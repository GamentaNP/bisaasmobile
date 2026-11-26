/// Providers and controller for the unified quiz spaced-repetition queue.
///
/// The due list is a plain [FutureProvider]: a failed read stays an error
/// with retry, never an empty list that reads as "nothing is due". Grading
/// is a Notifier action because it owns one stable Idempotency-Key per
/// review/quality intent and refreshes the queue only after a success.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../app/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/utils/debug_stack.dart';
import '../../../../shared/utils/error_message.dart';
import '../../data/datasources/quiz_srs_remote_data_source.dart';
import '../../data/repositories/quiz_srs_repository_impl.dart';
import '../../domain/entities/quiz_srs.dart';
import '../../domain/repositories/quiz_srs_repository.dart';

final quizSrsRemoteDataSourceProvider = Provider<QuizSrsRemoteDataSource>((ref) {
  return QuizSrsRemoteDataSource(ref.watch(dioProvider));
});

final quizSrsRepositoryProvider = Provider<QuizSrsRepository>((ref) {
  return QuizSrsRepositoryImpl(ref.watch(quizSrsRemoteDataSourceProvider));
});

/// The whole cursor-walked due queue. A transport/contract failure is thrown
/// and rendered by the screen with a retry affordance.
final quizSrsDueProvider = FutureProvider<List<QuizSrsCard>>((ref) async {
  return ref.watch(quizSrsRepositoryProvider).getDueCards();
});

class QuizSrsState {
  const QuizSrsState({
    this.isGrading = false,
    this.gradeError,
    this.lastGrade,
  });

  final bool isGrading;
  final String? gradeError;
  final QuizSrsGradeResult? lastGrade;

  static const _sentinel = Object();

  QuizSrsState copyWith({
    bool? isGrading,
    Object? gradeError = _sentinel,
    Object? lastGrade = _sentinel,
  }) {
    return QuizSrsState(
      isGrading: isGrading ?? this.isGrading,
      gradeError: gradeError == _sentinel
          ? this.gradeError
          : gradeError as String?,
      lastGrade: lastGrade == _sentinel
          ? this.lastGrade
          : lastGrade as QuizSrsGradeResult?,
    );
  }
}

class QuizSrsController extends Notifier<QuizSrsState> {
  @override
  QuizSrsState build() => const QuizSrsState();

  QuizSrsRepository get _repo => ref.read(quizSrsRepositoryProvider);

  /// One key per logical grade intent. A retry after a lost response must
  /// replay the first grade, so the key survives failed attempts and is
  /// discarded only once the server has accepted the write.
  final Map<String, String> _gradeKeys = <String, String>{};

  static const _uuid = Uuid();

  Future<QuizSrsGradeResult?> grade(
    String reviewId, {
    required int quality,
    String? type,
  }) async {
    if (!QuizSrsQuality.isValid(quality)) {
      // Quality comes from the four buttons on the screen, so this is a
      // defensive guard rather than a state a user can reach.
      state = state.copyWith(isGrading: false, gradeError: appL10n().error);
      return null;
    }

    final intent = '$reviewId:$quality';
    final key = _gradeKeys.putIfAbsent(intent, _uuid.v4);
    state = state.copyWith(isGrading: true, gradeError: null);
    try {
      final result = await _repo.gradeReview(
        reviewId,
        quality: quality,
        type: type,
        idempotencyKey: key,
      );
      _gradeKeys.remove(intent);
      state = state.copyWith(isGrading: false, lastGrade: result);
      // A graded card leaves the queue. Refresh only on success — refreshing
      // on failure would hide the error behind a re-read of the same card.
      ref.invalidate(quizSrsDueProvider);
      return result;
    } catch (e, st) {
      AppLogger.w('quiz SRS grade $reviewId failed: $e');
      debugStack(st);
      state = state.copyWith(isGrading: false, gradeError: errorMessage(e));
      return null;
    }
  }

  void clearError() => state = state.copyWith(gradeError: null);
}

final quizSrsControllerProvider =
    NotifierProvider<QuizSrsController, QuizSrsState>(QuizSrsController.new);

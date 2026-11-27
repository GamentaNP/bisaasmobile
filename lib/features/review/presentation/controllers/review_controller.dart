/// Providers and controller for the learner-review cluster.
///
/// Both reads are plain futures: a failed read stays an error with retry,
/// never an empty list that reads as "nothing is due" / "no answers". The
/// grade and report actions own one stable Idempotency-Key per intent, and
/// publish success only after the server accepts the write.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../app/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/debug_stack.dart';
import '../../../../shared/utils/error_message.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/entities/question_report.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  return ReviewRemoteDataSource(ref.watch(dioProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(reviewRemoteDataSourceProvider));
});

/// The full cursor-walked due queue.
final reviewDueProvider = FutureProvider<List<ReviewCard>>((ref) async {
  return ref.watch(reviewRepositoryProvider).getDueCards();
});

/// A completed attempt's verdict sheet, keyed by the attempt id in the URI.
final attemptReviewProvider = FutureProvider.family<AttemptReview, int>((
  ref,
  attemptId,
) async {
  return ref.watch(reviewRepositoryProvider).getAttemptReview(attemptId);
});

class ReviewGradeState {
  const ReviewGradeState({
    this.isGrading = false,
    this.gradeError,
    this.lastGrade,
  });

  final bool isGrading;
  final String? gradeError;
  final ReviewGradeResult? lastGrade;

  static const _sentinel = Object();

  ReviewGradeState copyWith({
    bool? isGrading,
    Object? gradeError = _sentinel,
    Object? lastGrade = _sentinel,
  }) {
    return ReviewGradeState(
      isGrading: isGrading ?? this.isGrading,
      gradeError: gradeError == _sentinel
          ? this.gradeError
          : gradeError as String?,
      lastGrade: lastGrade == _sentinel
          ? this.lastGrade
          : lastGrade as ReviewGradeResult?,
    );
  }
}

class ReviewGradeController extends Notifier<ReviewGradeState> {
  @override
  ReviewGradeState build() => const ReviewGradeState();

  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  /// One key per logical grade. A retry after a lost response must replay the
  /// first grade, so the key survives failures and is dropped only on success.
  final Map<String, String> _gradeKeys = <String, String>{};

  static const _uuid = Uuid();

  Future<ReviewGradeResult?> grade(
    String reviewId, {
    required int quality,
    required String type,
  }) async {
    if (!ReviewQuality.isValid(quality) || !ReviewCardType.isValid(type)) {
      state = state.copyWith(isGrading: false, gradeError: appL10n().error);
      return null;
    }

    final intent = '$reviewId:$type:$quality';
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
      // The graded card leaves the queue. Refresh only on success — a refresh
      // on failure would hide the error behind a re-read of the same card.
      ref.invalidate(reviewDueProvider);
      return result;
    } catch (e, st) {
      AppLogger.w('review grade $reviewId failed: $e');
      debugStack(st);
      state = state.copyWith(isGrading: false, gradeError: errorMessage(e));
      return null;
    }
  }

  void clearError() => state = state.copyWith(gradeError: null);
}

final reviewGradeControllerProvider =
    NotifierProvider<ReviewGradeController, ReviewGradeState>(
      ReviewGradeController.new,
    );

/// State of the "Report question" action.
///
/// [lastResult] and [reportedQuestionIds] change only on a server acceptance.
/// A transport failure keeps [failedSubmission] for the retry action and
/// leaves the reported set untouched — the UI never credits a report it did
/// not get an answer for.
class QuestionReportState {
  const QuestionReportState({
    this.isSubmitting = false,
    this.lastResult,
    this.error,
    this.failedSubmission,
    this.reportedQuestionIds = const <int>{},
  });

  final bool isSubmitting;
  final QuestionReportResult? lastResult;
  final String? error;
  final QuestionReportSubmission? failedSubmission;
  final Set<int> reportedQuestionIds;

  static const _sentinel = Object();

  QuestionReportState copyWith({
    bool? isSubmitting,
    Object? lastResult = _sentinel,
    Object? error = _sentinel,
    Object? failedSubmission = _sentinel,
    Set<int>? reportedQuestionIds,
  }) {
    return QuestionReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastResult: lastResult == _sentinel
          ? this.lastResult
          : lastResult as QuestionReportResult?,
      error: error == _sentinel ? this.error : error as String?,
      failedSubmission: failedSubmission == _sentinel
          ? this.failedSubmission
          : failedSubmission as QuestionReportSubmission?,
      reportedQuestionIds: reportedQuestionIds ?? this.reportedQuestionIds,
    );
  }
}

class QuestionReportController extends Notifier<QuestionReportState> {
  @override
  QuestionReportState build() => const QuestionReportState();

  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  /// One key per logical report, reused until the server accepts it.
  final Map<String, String> _reportKeys = <String, String>{};

  static const _uuid = Uuid();

  Future<QuestionReportResult?> submit(
    QuestionReportSubmission submission,
  ) async {
    final description = submission.description.trim();
    if (!QuestionReportCategory.isValid(submission.category) ||
        submission.questionId <= 0 ||
        description.length < QuestionReportCategory.minDescriptionLength ||
        description.length > QuestionReportCategory.maxLength ||
        (submission.suggestedCorrection?.length ?? 0) >
            QuestionReportCategory.maxLength) {
      state = state.copyWith(
        isSubmitting: false,
        error: appL10n().quizReportInvalid,
        failedSubmission: null,
      );
      return null;
    }

    final intent = submission.intent;
    final key = _reportKeys.putIfAbsent(intent, _uuid.v4);
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _repo.reportQuestion(
        submission.questionId,
        category: submission.category,
        description: description,
        suggestedCorrection:
            submission.suggestedCorrection?.trim().isEmpty ?? true
            ? null
            : submission.suggestedCorrection!.trim(),
        idempotencyKey: key,
      );
      _reportKeys.remove(intent);
      state = state.copyWith(
        isSubmitting: false,
        lastResult: result,
        error: null,
        failedSubmission: null,
        reportedQuestionIds: <int>{
          ...state.reportedQuestionIds,
          submission.questionId,
        },
      );
      return result;
    } catch (e, st) {
      AppLogger.w('question ${submission.questionId} report failed: $e');
      debugStack(st);
      state = state.copyWith(
        isSubmitting: false,
        // The server's own message is already localized. Contract drift and
        // local bugs go to the log; the user gets generic localized copy.
        error: e is ApiException ? e.message : appL10n().error,
        failedSubmission: submission,
      );
      return null;
    }
  }

  /// Retries the last failed report with its original payload and key.
  Future<QuestionReportResult?> retry() {
    final failed = state.failedSubmission;
    if (failed == null) return Future.value(null);
    return submit(failed);
  }

  void clearError() =>
      state = state.copyWith(error: null, failedSubmission: null);
}

final questionReportControllerProvider =
    NotifierProvider<QuestionReportController, QuestionReportState>(
      QuestionReportController.new,
    );

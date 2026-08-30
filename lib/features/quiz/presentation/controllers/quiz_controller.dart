import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ignore_for_file: omit_local_variable_types

import 'package:dio/dio.dart';

import '../../../../app/providers.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/quiz_local_data_source.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../state/quiz_state.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  return QuizRemoteDataSource(DioClient.instance.dio);
});

final quizLocalDataSourceProvider = Provider<QuizLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return QuizLocalDataSource(db);
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final remote = ref.watch(quizRemoteDataSourceProvider);
  final local = ref.watch(quizLocalDataSourceProvider);
  return QuizRepositoryImpl(remote, local: local);
});

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);

// ── Controller ─────────────────────────────────────────────────────────────

/// Manages the entire quiz session lifecycle — fetching, timing, submission,
/// grading feedback, and finish. Timer is isolated in a separate periodic
/// ticker so the UI never rebuilds to advance the clock (it reads remainingSeconds
/// only from state updates that the timer fires every second).
class QuizController extends Notifier<QuizState> {
  Timer? _timer;
  static const _uuid = Uuid();

  QuizRepository get _repo => ref.read(quizRepositoryProvider);

  @override
  QuizState build() {
    ref.onDispose(() => _timer?.cancel());
    return QuizState.initial();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> startSession(String quizId) async {
    state = QuizState.initial();

    try {
      // 1. Fetch questions (remote with Drift fallback for offline)
      final session = await _repo.getQuizSession(quizId);
      final isOfflineCache = session.title.startsWith('Offline Practice');

      // 2. Start attempt on server — offline if cache served or network down
      String attemptId;
      bool isOffline = isOfflineCache;
      try {
        final idempotencyKey = _uuid.v4();
        attemptId = await _repo.startAttempt(
          quizId: quizId,
          idempotencyKey: idempotencyKey,
        );
      } on DioException catch (e) {
        final offline = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.response == null;
        if (offline) {
          attemptId = 'offline-${_uuid.v4()}';
          isOffline = true;
        } else {
          rethrow;
        }
      }

      state = state.copyWith(
        phase: QuizPhase.answering,
        session: session,
        attemptId: attemptId,
        isOfflinePractice: isOffline,
      );

      _startTimer(session.durationSeconds);
      // analytics best-effort
      try {
        final a = ref.read(analyticsProvider);
        if (isOffline) {
          await a?.log(AnalyticsEvents.quizStart, params: {'mode': 'offline', 'quiz_id': quizId});
        } else {
          await a?.log(AnalyticsEvents.quizStart, params: {'quiz_id': quizId});
        }
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Called the moment user taps an option.
  /// Immediately transitions to [QuizPhase.grading] (optimistic UI shows selection),
  /// fires the API call, then transitions to [QuizPhase.feedback] with server result.
  /// Offline-practice: grades locally if cached `correctOptionId` is available,
  /// otherwise shows not-official feedback with 0 XP.
  Future<void> selectAnswer(String optionId) async {
    if (state.phase != QuizPhase.answering) return;
    final attemptId = state.attemptId;
    final question = state.currentQuestion;
    if (attemptId == null || question == null) return;

    // Optimistic: record selected option and switch to grading phase
    state = state.copyWith(
      phase: QuizPhase.grading,
      selectedOptionId: optionId,
    );

    // Offline path — attemptId prefixed 'offline-' → local grading only.
    if (attemptId.startsWith('offline-')) {
      final correctId = question.correctOptionId;
      final isKnown = correctId != null && correctId.isNotEmpty;
      final isCorrect = isKnown && optionId == correctId;
      final result = AttemptResult(
        questionId: question.id,
        selectedOptionId: optionId,
        isCorrect: isCorrect,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: correctId ?? '',
        explanation: isKnown ? question.explanation : 'Offline practice — not official. Reconnect to sync.',
      );
      final updatedAnswers = Map<String, AttemptResult>.from(state.answers)
        ..[question.id] = result;
      state = state.copyWith(
        phase: QuizPhase.feedback,
        lastResult: result,
        answers: updatedAnswers,
        comboCount: isCorrect ? state.comboCount + 1 : 0,
      );
      return;
    }

    try {
      final idempotencyKey = _uuid.v4();
      final result = await _repo.submitAnswer(
        attemptId: attemptId,
        questionId: question.id,
        selectedOptionId: optionId,
        idempotencyKey: idempotencyKey,
      );

      final updatedAnswers = Map<String, AttemptResult>.from(state.answers)
        ..[question.id] = result;

      state = state.copyWith(
        phase: QuizPhase.feedback,
        lastResult: result,
        answers: updatedAnswers,
        comboCount: result.isCorrect ? state.comboCount + 1 : 0,
        totalXpEarned: state.totalXpEarned + result.xpEarned,
        totalCoinsEarned: state.totalCoinsEarned + result.coinsEarned,
      );
      try {
        await ref.read(analyticsProvider)?.log(AnalyticsEvents.quizAnswer, params: {'is_correct': result.isCorrect ? 1 : 0});
      } catch (_) {}
    } catch (e) {
      // On network failure: still advance but mark as unsynced
      state = state.copyWith(
        phase: QuizPhase.feedback,
        lastResult: AttemptResult(
          questionId: question.id,
          selectedOptionId: optionId,
          isCorrect: false,
          xpEarned: 0,
          coinsEarned: 0,
          correctOptionId: '',
          explanation: 'Offline — answer queued. XP/coins will reconcile on reconnect.',
        ),
      );
    }
  }

  /// Advance to next question after feedback is shown.
  void nextQuestion() {
    if (state.phase != QuizPhase.feedback) return;

    if (state.isLastQuestion) {
      unawaited(_finishSession());
      return;
    }

    state = state.copyWith(
      phase: QuizPhase.answering,
      currentIndex: state.currentIndex + 1,
      lastResult: null,
      selectedOptionId: null,
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _startTimer(int totalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = state.elapsedSeconds + 1;
      if (newElapsed >= totalSeconds) {
        _timer?.cancel();
        unawaited(_finishSession());
      } else {
        state = state.copyWith(elapsedSeconds: newElapsed);
      }
    });
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    final attemptId = state.attemptId;
    if (attemptId == null) return;

    try {
      await _repo.finishAttempt(attemptId);
    } catch (_) {
      // Finish is best-effort; result screen still shows local totals
    }

    state = state.copyWith(phase: QuizPhase.finished);
    try {
      await ref.read(analyticsProvider)?.log(AnalyticsEvents.quizComplete, params: {
        'correct': state.answers.values.where((r) => r.isCorrect).length,
        'total': state.session?.totalQuestions ?? state.answers.length,
        'xp': state.totalXpEarned,
      });
    } catch (_) {}
  }
}

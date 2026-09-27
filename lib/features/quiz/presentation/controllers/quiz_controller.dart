import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ignore_for_file: omit_local_variable_types

import 'package:dio/dio.dart';

import '../../../../app/providers.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/lifeline_remote_data_source.dart';
import '../../data/datasources/quiz_local_data_source.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/models/lifeline_dto.dart';
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

final lifelineRemoteDataSourceProvider = Provider<LifelineRemoteDataSource>((ref) {
  return LifelineRemoteDataSource(DioClient.instance.dio);
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

  /// Wall-clock instant the current question was shown, used to report
  /// `time_taken_seconds` with the answer. Reset on every advance.
  DateTime? _questionShownAt;

  QuizRepository get _repo => ref.read(quizRepositoryProvider);
  LifelineRemoteDataSource get _lifelines => ref.read(lifelineRemoteDataSourceProvider);

  @override
  QuizState build() {
    ref.onDispose(() => _timer?.cancel());
    return QuizState.initial();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> startSession(String quizId, {int? categoryId}) async {
    state = QuizState.initial();

    try {
      // 1. Fetch questions (remote with Drift fallback for offline)
      final session = await _repo.getQuizSession(quizId, categoryId: categoryId);
      final isOfflineCache = session.title.startsWith('Offline Practice');

      // 2. Start attempt on server — offline if cache served or network down
      String attemptId;
      bool isOffline = isOfflineCache;
      try {
        final idempotencyKey = _uuid.v4();
        // Server seeds its grading rows from the ids we send — the questions
        // fetched for this session MUST be the ones the attempt is graded on.
        // The pool is already category-scoped (getQuizSession applies the
        // filter), so question_ids are always exact; delegating seeding to
        // category_id would grade a DIFFERENT set than the one on screen and
        // 404 every answer.
        final questionIds = session.questions
            .map((q) => int.tryParse(q.id))
            .whereType<int>()
            .toList();
        attemptId = await _repo.startAttempt(
          quizId: quizId,
          idempotencyKey: idempotencyKey,
          questionIds: questionIds.isNotEmpty ? questionIds : null,
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
        hiddenOptionKeys: const {},
        lifelineNotice: null,
      );
      _questionShownAt = DateTime.now();

      // Lifelines are a separate, server-owned cluster. Load them in the
      // background so a slow or failing read never delays the first question.
      if (!isOffline) unawaited(loadLifelines());

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
  /// Offline-practice: records the answer as *pending* — never graded, never
  /// rewarded. A key only ever reaches the device inside an encrypted offline
  /// pack (security plan W4.8); until that ships, the verdict waits for
  /// reconnect. An empty `correctOptionId` is the established pending marker
  /// that the attempt screen already skips feedback highlighting for.
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

    // Offline path — attemptId prefixed 'offline-' → pending, never graded here.
    if (attemptId.startsWith('offline-')) {
      final result = AttemptResult(
        questionId: question.id,
        selectedOptionId: optionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: 'Offline practice — answer saved. Reconnect to see the result.',
      );
      final updatedAnswers = Map<String, AttemptResult>.from(state.answers)
        ..[question.id] = result;
      state = state.copyWith(
        phase: QuizPhase.feedback,
        lastResult: result,
        answers: updatedAnswers,
        // Combos are an official-mode reward mechanic; offline never advances one.
        comboCount: 0,
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
        timeTakenSeconds: _secondsOnThisQuestion(),
      );

      final updatedAnswers = Map<String, AttemptResult>.from(state.answers)
        ..[question.id] = result;

      state = state.copyWith(
        phase: QuizPhase.feedback,
        lastResult: result,
        answers: updatedAnswers,
        // Pending results (empty correctOptionId — the server grades on
        // complete) must neither advance nor reset the cosmetic combo.
        comboCount: result.correctOptionId.isEmpty
            ? state.comboCount
            : (result.isCorrect ? state.comboCount + 1 : 0),
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
      // Lifeline effects are per-question; the next question starts clean.
      hiddenOptionKeys: const {},
      lifelineNotice: null,
    );
    _questionShownAt = DateTime.now();
  }

  // ── Lifelines (server-authoritative) ─────────────────────────────────────

  /// `GET /quiz/attempts/{attempt}/lifelines`.
  ///
  /// Failure is non-fatal and non-fatal-looking: a failed read leaves the bar
  /// hidden rather than showing lifelines whose cost or availability we could
  /// not confirm.
  Future<void> loadLifelines() async {
    final attemptId = state.attemptId;
    if (attemptId == null || attemptId.startsWith('offline-')) return;
    try {
      final catalogue = await _lifelines.getCatalogue(attemptId);
      state = state.copyWith(
        lifelinesEnabled: catalogue.enabled,
        lifelines: catalogue.lifelines,
        lifelineWalletBalance: catalogue.walletBalance,
      );
    } catch (e) {
      AppLogger.w('lifeline catalogue failed: $e');
      state = state.copyWith(lifelinesEnabled: false, lifelines: const []);
    }
  }

  /// Spend a lifeline on the current question and apply the server's effect.
  ///
  /// Returns the effect so the UI can narrate it, or `null` when the server
  /// refused (insufficient coins, already used, mode locked). The effect is
  /// never computed here — `LifelineEffectService` owns that.
  Future<LifelineEffectDto?> useLifeline(String slug) async {
    final attemptId = state.attemptId;
    final question = state.currentQuestion;
    if (attemptId == null || question == null) return null;
    if (attemptId.startsWith('offline-')) return null;
    if (state.isLifelineBusy) return null;

    final questionId = int.tryParse(question.id);
    // The server requires an int question_id; a non-numeric id cannot be spent.
    if (questionId == null) return null;

    final offered = state.lifelines.where((l) => l.slug == slug).firstOrNull;
    if (offered != null && !offered.isAvailable) return null;

    state = state.copyWith(busyLifelineSlug: slug, lifelineNotice: null);
    try {
      // Prefer a banked token; otherwise buy and apply in one server call.
      // (`use` 404s/422s without inventory, so the choice matters.)
      final result = offered != null && offered.hasBankedUse
          ? await _lifelines.use(attemptId: attemptId, slug: slug, questionId: questionId)
          : await _lifelines.purchaseAndUse(
              attemptId: attemptId,
              slug: slug,
              questionId: questionId,
            );

      state = state.copyWith(
        busyLifelineSlug: null,
        hiddenOptionKeys: result.effect.hiddenOptionKeys.toSet(),
        lifelineNotice: _describeEffect(result.effect),
      );
      // Remaining uses and the wallet moved server-side; re-read them rather
      // than decrementing a local copy.
      await loadLifelines();
      return result.effect;
    } catch (e) {
      AppLogger.w('lifeline $slug failed: $e');
      state = state.copyWith(
        busyLifelineSlug: null,
        lifelineNotice: 'Could not use ${offered?.name ?? slug}. ${_lifelineError(e)}',
      );
      return null;
    }
  }

  /// Player-facing text for a server-built effect. Returns `null` when the
  /// server sent an effect the client does not yet know how to render — the
  /// caller reports it rather than pretending nothing happened.
  static String? _describeEffect(LifelineEffectDto effect) {
    if (effect.hint != null && effect.hint!.isNotEmpty) return effect.hint;
    if (effect.explanation != null && effect.explanation!.isNotEmpty) {
      return effect.explanation;
    }
    if (effect.hiddenOptionKeys.isNotEmpty) {
      return '${effect.hiddenOptionKeys.length} wrong option(s) removed.';
    }
    if (effect.correctAnswer != null) return 'Correct answer: ${effect.correctAnswer}';
    if (effect.extraSeconds != null) return '+${effect.extraSeconds}s added.';
    if (effect.freezeSeconds != null) return 'Timer frozen for ${effect.freezeSeconds}s.';
    if (effect.shieldActive ?? false) return 'Shield active — one wrong answer forgiven.';
    if (effect.doubleXpActive ?? false) return 'Double XP active on the next correct answer.';
    if (effect.poll != null) return 'Audience poll coming up.';
    if (effect.retryQuestionId != null) return 'Second chance saved for this question.';
    return null;
  }

  static String _lifelineError(Object e) {
    final text = e.toString();
    if (text.contains('INSUFFICIENT_COINS')) return 'Not enough coins.';
    if (text.contains('LIFELINE_INVALID_QUESTION')) return 'Not valid for this question.';
    if (text.contains('LIFELINE_ALREADY_USED') || text.contains('409')) {
      return 'Already used on this attempt.';
    }
    if (text.contains('403')) return 'Not available for this attempt.';
    return 'Please try again.';
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Seconds the player has spent on the current question. `null` when unknown
  /// so the field is omitted rather than sent as a fabricated 0.
  int? _secondsOnThisQuestion() {
    final shownAt = _questionShownAt;
    if (shownAt == null) return null;
    final seconds = DateTime.now().difference(shownAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

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

// ignore_for_file: omit_local_variable_types
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../core/consent/consent_gate.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/utils/error_message.dart';
import '../../data/datasources/lifeline_remote_data_source.dart';
import '../../data/datasources/quiz_hint_remote_data_source.dart';
import '../../data/datasources/quiz_local_data_source.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/models/lifeline_dto.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../state/quiz_state.dart';
import '../../../../app/localization/l10n.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  return QuizRemoteDataSource(ref.watch(dioProvider));
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
  return LifelineRemoteDataSource(ref.watch(dioProvider));
});

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);

/// What the attempt screen renders for the server's answer-safe hint.
/// Kept in its own provider so a hint arrival does not need to fake a change
/// to [QuizState] (which has no hint fields).
typedef QuizHintViewState = ({
  String? hint,
  String? error,
  bool busy,
  int? questionId,
});

class QuizHintViewController extends Notifier<QuizHintViewState> {
  @override
  QuizHintViewState build() => (
        hint: null,
        error: null,
        busy: false,
        questionId: null,
      );

  QuizHintViewState get view => state;
  set view(QuizHintViewState next) => state = next;

  void clear() => view = (hint: null, error: null, busy: false, questionId: null);
}

final quizHintViewProvider =
    NotifierProvider<QuizHintViewController, QuizHintViewState>(
  QuizHintViewController.new,
);

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

  /// Start is a single logical write: the key is minted once per intent and
  /// reused when the error screen retries, so a lost response cannot seed a
  /// second attempt. Cleared only once the attempt is genuinely playable.
  String? _startKey;
  ({String quizId, int? categoryId, List<int> questionIds})? _startIntent;

  /// Answer writes are keyed by the logical answer, not by the tap. The cached
  /// result lets a replayed write return the original verdict rather than a
  /// generic failure.
  final Map<String, String> _answerKeys = <String, String>{};
  final Map<String, AttemptResult> _answerResults = <String, AttemptResult>{};

  /// A failed completion must be retried against the SAME attempt. Remembering
  /// it also lets the screen offer "retry completion" instead of "start over".
  String? _failedCompletionAttemptId;
  QuizResult? _completedResult;

  /// True when the error screen should retry a completion, not start a new
  /// quiz (C3). Read by the screen through the notifier.
  bool get hasFailedCompletion => _failedCompletionAttemptId != null;

  QuizRepository get _repo => ref.read(quizRepositoryProvider);
  QuizRemoteDataSource get _remote => ref.read(quizRemoteDataSourceProvider);
  LifelineRemoteDataSource get _lifelines => ref.read(lifelineRemoteDataSourceProvider);

  void _clearHint() => ref.read(quizHintViewProvider.notifier).clear();

  @override
  QuizState build() {
    ref.onDispose(() => _timer?.cancel());
    return QuizState.initial();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts a fresh quiz, or resumes an interrupted attempt when [attemptId]
  /// is supplied (the server's `GET /quiz/attempts/{attempt}` contract).
  Future<void> startSession(
    String quizId, {
    int? categoryId,
    String? attemptId,
  }) async {
    if (attemptId != null && attemptId.isNotEmpty) {
      await resumeSession(attemptId);
      return;
    }
    _timer?.cancel();
    final isRetry = _startKey != null && _startIntent?.quizId == quizId;
    if (!isRetry) {
      _startKey = 'quiz-start-$quizId-${_uuid.v4()}';
      _answerKeys.clear();
      _answerResults.clear();
    }
    _failedCompletionAttemptId = null;
    _completedResult = null;
    _clearHint();
    state = QuizState.initial();

    try {
      // 1. Fetch questions (remote with Drift fallback for offline)
      final session = await _repo.getQuizSession(quizId, categoryId: categoryId);
      final isOfflineCache = session.title.startsWith('Offline Practice');

      // A zero-question session cannot be played and must never be seeded on
      // the server: startAttempt would grade 20 questions the user never saw.
      if (session.questions.isEmpty) {
        state = state.copyWith(
          phase: QuizPhase.error,
          errorMessage: appL10n().quizEmptySession,
        );
        return;
      }

      // 2. Start attempt on server — offline if cache served or network down
      String attemptId;
      bool isOffline = isOfflineCache;
      try {
        // Server seeds its grading rows from the ids we send — the questions
        // fetched for this session MUST be the ones the attempt is graded on.
        // On a retry we reuse the first attempt's ids so the keyed request is
        // byte-for-byte the same one the server already stored.
        final fetchedIds = session.questions
            .map((q) => int.tryParse(q.id))
            .whereType<int>()
            .toList();
        final questionIds = (isRetry && _startIntent!.questionIds.isNotEmpty)
            ? _startIntent!.questionIds
            : fetchedIds;
        _startIntent = (
          quizId: quizId,
          categoryId: categoryId,
          questionIds: questionIds,
        );
        attemptId = await _repo.startAttempt(
          quizId: quizId,
          idempotencyKey: _startKey!,
          questionIds: questionIds.isNotEmpty ? questionIds : null,
        );
      } on DioException catch (e) {
        // A replay/conflict means the keyed start already happened. Return the
        // attempt the server reports instead of declaring a fresh offline run.
        if (_isIdempotentReplay(e)) {
          final replayedId = _attemptIdFromError(e);
          if (replayedId != null) {
            attemptId = replayedId;
          } else {
            rethrow;
          }
        } else {
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
      }

      state = state.copyWith(
        phase: QuizPhase.answering,
        session: session,
        attemptId: attemptId,
        isOfflinePractice: isOffline,
        hiddenOptionKeys: const {},
        lifelineNotice: null,
      );
      // The key is spent: "play again" must mint a new one rather than replay
      // this attempt.
      _startKey = null;
      _startIntent = null;
      _questionShownAt = DateTime.now();

      // Lifelines are a separate, server-owned cluster. Load them in the
      // background so a slow or failing read never delays the first question.
      if (!isOffline) unawaited(loadLifelines());

      _startTimer(session.durationSeconds);
      // analytics best-effort
      try {
        final a = ref.read(analyticsProvider);
        if (isOffline) {
          await a.log(AnalyticsEvents.quizStart, params: {'mode': 'offline', 'quiz_id': quizId});
        } else {
          await a.log(AnalyticsEvents.quizStart, params: {'quiz_id': quizId});
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
        explanation: appL10n().quizOfflinePracticeUngraded,
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

    final answerKey = '$attemptId:${question.id}';
    final idempotencyKey = _answerKeys.putIfAbsent(
      answerKey,
      () => 'quiz-answer-$attemptId-${question.id}-${_uuid.v4()}',
    );
    try {
      final result = await _repo.submitAnswer(
        attemptId: attemptId,
        questionId: question.id,
        selectedOptionId: optionId,
        idempotencyKey: idempotencyKey,
        timeTakenSeconds: _secondsOnThisQuestion(),
      );
      _answerResults[answerKey] = result;

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
        errorMessage: null,
      );
      try {
        await ref.read(analyticsProvider).log(AnalyticsEvents.quizAnswer, params: {'is_correct': result.isCorrect ? 1 : 0});
      } catch (_) {}
    } catch (e) {
      // A replayed write already succeeded server-side. Return the original
      // result (or the honest "verdict pending" marker when the first response
      // was lost) instead of telling the user their answer never arrived.
      if (_isIdempotentReplay(e)) {
        final result = _answerResults[answerKey] ??
            AttemptResult(
              questionId: question.id,
              selectedOptionId: optionId,
              isCorrect: false,
              xpEarned: 0,
              coinsEarned: 0,
              correctOptionId: '',
              explanation: appL10n().quizAnswerSubmitted,
            );
        _answerResults[answerKey] = result;
        final replayedAnswers = Map<String, AttemptResult>.from(state.answers)
          ..[question.id] = result;
        state = state.copyWith(
          phase: QuizPhase.feedback,
          lastResult: result,
          answers: replayedAnswers,
          errorMessage: null,
        );
        return;
      }
      // The write outbox is deliberately unwired: nothing is queued and
      // nothing reconciles. Keep the question in `answering` with the
      // selection intact so the user can retry instead of being told a lie.
      AppLogger.w('quiz answer submit failed: $e');
      state = state.copyWith(
        phase: QuizPhase.answering,
        lastResult: null,
        errorMessage: appL10n().quizAnswerNotSent,
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
      errorMessage: null,
      // Lifeline effects are per-question; the next question starts clean.
      hiddenOptionKeys: const {},
      lifelineNotice: null,
    );
    _clearHint();
    _questionShownAt = DateTime.now();
  }

  // ── Server-built hint (answer-safe) ──────────────────────────────────────

  /// Requests the hint for the current question from
  /// `GET /quiz/questions/{question}/hint`.
  ///
  /// The server sanitises the text and guarantees it carries no answer key;
  /// the client only renders what it returns. A failure is kept in the hint
  /// view with a retry — it is never an empty hint or a locally invented one.
  Future<void> loadHint() async {
    final question = state.currentQuestion;
    final attemptId = state.attemptId;
    if (question == null || attemptId == null || attemptId.startsWith('offline-')) return;
    final questionId = int.tryParse(question.id);
    if (questionId == null) return;
    if (ref.read(quizHintViewProvider).busy) return;

    final view = ref.read(quizHintViewProvider.notifier);
    view.view = (hint: null, error: null, busy: true, questionId: questionId);
    try {
      final hint = await ref
          .read(quizHintRemoteDataSourceProvider)
          .getHint(questionId);
      if (!ref.mounted) return;
      // The user may have advanced while the request was in flight. Never
      // paint a hint for question A against question B's body.
      if (state.currentQuestion?.id != question.id) {
        if (ref.read(quizHintViewProvider).questionId == questionId) {
          _clearHint();
        }
        return;
      }
      view.view = (hint: hint.hint, error: null, busy: false, questionId: questionId);
    } catch (e) {
      AppLogger.w('quiz hint failed for question $questionId: $e');
      if (!ref.mounted) return;
      if (state.currentQuestion?.id != question.id) {
        _clearHint();
        return;
      }
      view.view = (
        hint: null,
        error: appL10n().quizHintLoadFailed,
        busy: false,
        questionId: questionId,
      );
    }
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
      // A background read can outlive the screen (and its provider). Writing
      // state after disposal throws in Riverpod 3 and shows up as a spurious
      // test failure — and as a crash in the app after a fast navigation.
      if (!ref.mounted) return;
      state = state.copyWith(
        lifelinesEnabled: catalogue.enabled,
        lifelines: catalogue.lifelines,
        lifelineWalletBalance: catalogue.walletBalance,
      );
    } catch (e) {
      AppLogger.w('lifeline catalogue failed: $e');
      if (ref.mounted) {
        state = state.copyWith(lifelinesEnabled: false, lifelines: const []);
      }
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
      _applyTimeEffect(result.effect);
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
      return appL10n().lifelineWrongRemoved(effect.hiddenOptionKeys.length);
    }
    if (effect.correctAnswer != null) return appL10n().lifelineCorrectAnswer(effect.correctAnswer!);
    if (effect.extraSeconds != null) return appL10n().lifelineTimeAdded(effect.extraSeconds!);
    if (effect.freezeSeconds != null) return appL10n().lifelineTimerFrozen(effect.freezeSeconds!);
    if (effect.shieldActive ?? false) return appL10n().lifelineShieldActive;
    if (effect.doubleXpActive ?? false) return appL10n().lifelineDoubleXp;
    if (effect.poll != null) return appL10n().lifelineAudiencePoll;
    if (effect.retryQuestionId != null) return appL10n().lifelineSecondChance;
    return null;
  }

  static String _lifelineError(Object e) {
    final text = e.toString();
    if (text.contains('INSUFFICIENT_COINS')) return appL10n().lifelineNotEnoughCoins;
    if (text.contains('LIFELINE_INVALID_QUESTION')) return appL10n().lifelineNotValidForQuestion;
    if (text.contains('LIFELINE_ALREADY_USED') || text.contains('409')) {
      return appL10n().lifelineAlreadyUsed;
    }
    if (text.contains('403')) return appL10n().lifelineNotAvailable;
    return appL10n().lifelineTryAgain;
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
    // Read the deadline from state on every tick: a server-granted lifeline can
    // extend it mid-run, and a captured local would silently drop that effect.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final deadline = state.session?.durationSeconds ?? totalSeconds;
      final newElapsed = state.elapsedSeconds + 1;
      if (newElapsed >= deadline) {
        _timer?.cancel();
        unawaited(_finishSession());
      } else {
        state = state.copyWith(elapsedSeconds: newElapsed);
      }
    });
  }

  /// Applies the *server-built* time effects to the attempt deadline. The
  /// client never extends time on its own and never grades anything here; it
  /// only honours `extra_seconds` / `freeze_seconds` (or `frozen_until`) from
  /// the lifeline payload.
  void _applyTimeEffect(LifelineEffectDto effect) {
    final session = state.session;
    if (session == null) return;
    final extra = effect.extraSeconds ?? 0;
    var freeze = effect.freezeSeconds ?? 0;
    final until = effect.frozenUntil;
    if (until != null) {
      final remaining = until.difference(DateTime.now()).inSeconds;
      if (remaining > freeze) freeze = remaining;
    }
    if (extra <= 0 && freeze <= 0) return;
    final extended = session.durationSeconds + extra + freeze;
    state = state.copyWith(
      session: QuizSession(
        id: session.id,
        title: session.title,
        questions: session.questions,
        durationSeconds: extended,
        xpReward: session.xpReward,
        coinsReward: session.coinsReward,
        subjectSlug: session.subjectSlug,
      ),
    );
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    final attemptId = _failedCompletionAttemptId ?? state.attemptId;
    if (attemptId == null) return;

    late final QuizResult result;
    try {
      // Derived from the attempt, not minted here: a retry of the same
      // completion (dropped response, retry button) must present the same key,
      // or the server sees a second completion and credits the reward twice.
      result = await _repo.finishAttempt(
        attemptId,
        idempotencyKey: 'quiz-complete-$attemptId',
      );
    } catch (e) {
      if (_isIdempotentReplay(e) && _completedResult != null) {
        result = _completedResult!;
      } else {
        // Stay on THIS attempt: the error screen must retry the completion,
        // never call startSession() and orphan the attempt.
        _failedCompletionAttemptId = attemptId;
        state = state.copyWith(
          phase: QuizPhase.error,
          errorMessage: appL10n().quizFinishFailed,
        );
        AppLogger.w('quiz completion failed for $attemptId: $e');
        return;
      }
    }
    _failedCompletionAttemptId = null;
    _completedResult = result;
    state = state.copyWith(phase: QuizPhase.finished, quizResult: result);
    try {
      await ref.read(analyticsProvider).log(AnalyticsEvents.quizComplete, params: {
        'correct': result.correctAnswers,
        'total': result.totalQuestions,
        'xp': result.totalXpEarned,
      });
    } catch (_) {}
  }

  /// Ends the current attempt and asks the server for the verdict.
  /// Public so an UI action (and tests) can finish without waiting for the
  /// wall clock; the timer uses the same path.
  Future<void> finishSession() => _finishSession();

  /// Retries the completion of the attempt that failed, using the same key.
  /// A brand-new quiz is only started when the user explicitly chooses to.
  Future<void> retryCompletion() async {
    if (_failedCompletionAttemptId == null) return;
    await _finishSession();
  }

  /// Explicit exit from a live standard attempt. Abandonment is server-owned
  /// and keyed so a retried exit cannot abandon twice.
  Future<void> abandonSession() async {
    final attemptId = state.attemptId;
    if (attemptId == null || attemptId.startsWith('offline-')) return;
    try {
      await _remote.abandonAttempt(
        attemptId,
        idempotencyKey: 'quiz-abandon-$attemptId',
      );
    } catch (e) {
      // The user has already left; a failed best-effort write must not trap
      // them on the screen.
      AppLogger.w('quiz abandonment failed for $attemptId: $e');
    }
  }

  /// Resumes an interrupted server attempt from `GET /quiz/attempts/{id}`.
  /// Answered questions are marked as submitted (verdict pending) and the
  /// cursor lands on the first unanswered one; nothing is graded locally.
  Future<void> resumeSession(String attemptId) async {
    _timer?.cancel();
    state = QuizState.initial();
    _failedCompletionAttemptId = null;
    _completedResult = null;
    _startKey = null;
    _startIntent = null;
    _clearHint();
    try {
      final payload = await _remote.fetchAttempt(attemptId);
      if (payload.session.questions.isEmpty) {
        state = state.copyWith(
          phase: QuizPhase.error,
          errorMessage: appL10n().quizEmptySession,
        );
        return;
      }
      final answers = <String, AttemptResult>{};
      var elapsed = 0;
      var resumeIndex = 0;
      var foundPending = false;
      for (var i = 0; i < payload.rows.length; i++) {
        final row = payload.rows[i];
        elapsed += int.tryParse('${row['time_taken_seconds'] ?? 0}') ?? 0;
        final given = row['given_answer'];
        final answered = row['answered'] == true ||
            (given != null && given.toString().isNotEmpty);
        final skipped = row['skipped'] == true;
        final questionId = (row['question_id'] ??
                (row['question'] is Map ? (row['question'] as Map)['id'] : null) ?? '')
            .toString();
        if ((answered || skipped) && questionId.isNotEmpty) {
          answers[questionId] = AttemptResult(
            questionId: questionId,
            selectedOptionId: given?.toString() ?? '',
            isCorrect: false,
            xpEarned: 0,
            coinsEarned: 0,
            correctOptionId: '',
            explanation: appL10n().quizAnswerSubmitted,
          );
        } else if (!foundPending) {
          resumeIndex = i;
          foundPending = true;
        }
      }
      state = state.copyWith(
        phase: QuizPhase.answering,
        session: payload.session.toDomain(),
        attemptId: attemptId,
        currentIndex: resumeIndex,
        answers: answers,
        elapsedSeconds: elapsed,
        hiddenOptionKeys: const {},
        lifelineNotice: null,
        errorMessage: null,
      );
      _questionShownAt = DateTime.now();
      if (payload.status == 'in_progress') unawaited(loadLifelines());
      _startTimer(payload.session.durationSeconds);
    } catch (e) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: errorMessage(e),
      );
    }
  }

  bool _isIdempotentReplay(Object error) {
    final api = toApiException(error);
    if (api.code == ApiErrorCode.idempotencyConflict) return true;
    if (error is DioException) {
      final header = error.response?.headers.value('X-Idempotent-Replay');
      if (header?.toLowerCase() == 'true') return true;
    }
    return false;
  }

  String? _attemptIdFromError(Object error) {
    final api = toApiException(error);
    final details = api.details;
    if (details is Map) {
      final raw = details['attempt_id'] ?? details['id'];
      if (raw != null) return raw.toString();
    }
    return null;
  }
}

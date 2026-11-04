import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../data/datasources/arcade_remote_data_source.dart';
import '../../data/repositories/arcade_repository_impl.dart';
import '../../domain/entities/arcade_category.dart';
import '../../domain/entities/arcade_mode.dart';
import '../../domain/entities/arcade_question.dart';
import '../../domain/entities/arcade_result.dart';
import '../../domain/repositories/arcade_repository.dart';

final arcadeRemoteDataSourceProvider = Provider<ArcadeRemoteDataSource>(
  (ref) => ArcadeRemoteDataSource(ref.watch(dioProvider)),
);

final arcadeRepositoryProvider = Provider<ArcadeRepository>(
  (ref) => ArcadeRepositoryImpl(ref.watch(arcadeRemoteDataSourceProvider)),
);

/// How long the chosen option stays visible before the next question loads.
/// Overridable so tests do not sleep.
final arcadeAnswerPauseProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 320),
);

enum ArcadePhase { idle, starting, playing, submitting, finishing, finished, failed }

/// One run, from "starting" to the server's final tally.
@immutable
class ArcadeState {
  const ArcadeState({
    this.phase = ArcadePhase.idle,
    this.mode,
    this.category,
    this.attemptId,
    this.questions = const [],
    this.index = 0,
    this.answered = 0,
    this.timedOut = 0,
    this.secondsLeft,
    this.selectedOptionId,
    this.result,
    this.error,
    this.gameOver = false,
  });

  final ArcadePhase phase;
  final ArcadeMode? mode;
  final ArcadeCategory? category;
  final int? attemptId;

  /// The server's questions, in the server's order.
  final List<ArcadeQuestion> questions;
  final int index;

  /// Questions the user chose an answer for (the tally is still the server's).
  final int answered;

  /// Questions whose timer ran out. Nothing was submitted for them.
  final int timedOut;
  final int? secondsLeft;
  final String? selectedOptionId;
  final ArcadeResult? result;
  final ApiException? error;

  /// True when Survival ended because the server completed the attempt.
  final bool gameOver;

  ArcadeQuestion? get current =>
      index >= 0 && index < questions.length ? questions[index] : null;

  int get questionNumber => index + 1;
  int get totalQuestions => questions.length;
  bool get isLastQuestion => index >= questions.length - 1;

  /// Whether the screen should accept taps.
  bool get isAcceptingInput =>
      phase == ArcadePhase.playing && current != null;

  ArcadeState copyWith({
    ArcadePhase? phase,
    ArcadeMode? mode,
    ArcadeCategory? category,
    int? attemptId,
    List<ArcadeQuestion>? questions,
    int? index,
    int? answered,
    int? timedOut,
    int? secondsLeft,
    bool clearSeconds = false,
    String? selectedOptionId,
    bool clearSelection = false,
    ArcadeResult? result,
    ApiException? error,
    bool clearError = false,
    bool? gameOver,
  }) =>
      ArcadeState(
        phase: phase ?? this.phase,
        mode: mode ?? this.mode,
        category: category ?? this.category,
        attemptId: attemptId ?? this.attemptId,
        questions: questions ?? this.questions,
        index: index ?? this.index,
        answered: answered ?? this.answered,
        timedOut: timedOut ?? this.timedOut,
        secondsLeft: clearSeconds ? null : (secondsLeft ?? this.secondsLeft),
        selectedOptionId:
            clearSelection ? null : (selectedOptionId ?? this.selectedOptionId),
        result: result ?? this.result,
        error: clearError ? null : (error ?? this.error),
        gameOver: gameOver ?? this.gameOver,
      );
}

final arcadeControllerProvider =
    NotifierProvider<ArcadeController, ArcadeState>(ArcadeController.new);

class ArcadeController extends Notifier<ArcadeState> {
  static const _uuid = Uuid();

  Timer? _ticker;
  DateTime _questionStartedAt = DateTime.now();

  /// Reused when the same start is retried, so a transport failure cannot
  /// create a second attempt.
  String? _startKey;

  @override
  ArcadeState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const ArcadeState();
  }

  Future<void> start(ArcadeMode mode, {ArcadeCategory? category}) async {
    _ticker?.cancel();
    // A new intent needs a new key. Retrying a *failed* start must reuse the
    // old one (so the server resumes rather than seeding a second attempt),
    // but once a run has started the key is spent — reusing it for "play
    // again" would replay the completed attempt instead of starting a new one.
    _startKey ??= 'arcade-start-${mode.wire}-${_uuid.v4()}';

    state = ArcadeState(
      phase: ArcadePhase.starting,
      mode: mode,
      category: category,
    );

    try {
      final repo = ref.read(arcadeRepositoryProvider);
      final attemptId = await repo.start(
        mode: mode,
        idempotencyKey: _startKey!,
        categoryId: category?.id,
      );
      _startKey = null;
      final attempt = await repo.loadAttempt(attemptId);

      if (attempt.questions.isEmpty) {
        throw ContractViolation(
          'The attempt for ${mode.wire} carried no questions',
          endpoint: '/quiz/attempts/$attemptId',
        );
      }

      state = state.copyWith(
        phase: ArcadePhase.playing,
        attemptId: attemptId,
        questions: attempt.questions,
        index: 0,
        answered: 0,
        timedOut: 0,
        secondsLeft: mode.secondsPerQuestion,
        clearSelection: true,
        clearError: true,
      );
      _beginQuestion();
    } catch (error) {
      _fail(error);
    }
  }

  /// Submits the chosen option, then advances.
  ///
  /// Survival does one extra read: the server completes the attempt on the
  /// first wrong answer, so the only honest way to know the run is over is to
  /// ask it. The client never grades.
  Future<void> answer(String optionId) async {
    final run = state;
    final question = run.current;
    final attemptId = run.attemptId;
    final mode = run.mode;
    if (!run.isAcceptingInput || question == null || attemptId == null ||
        mode == null) {
      return;
    }

    _ticker?.cancel();
    state = state.copyWith(
      phase: ArcadePhase.submitting,
      selectedOptionId: optionId,
      clearError: true,
    );

    final seconds = DateTime.now().difference(_questionStartedAt).inSeconds;

    try {
      final repo = ref.read(arcadeRepositoryProvider);
      await repo.submitAnswer(
        attemptId: attemptId,
        questionId: question.id,
        answer: optionId,
        // Stable across retries of the same answer: a replayed submission
        // must not consume a second question.
        idempotencyKey: 'arcade-answer-$attemptId-${question.id}',
        timeTakenSeconds: seconds < 0 ? 0 : seconds,
      );

      if (mode.endsOnWrongAnswer) {
        final attempt = await repo.loadAttempt(attemptId);
        if (attempt.status != 'in_progress') {
          state = state.copyWith(gameOver: true);
          await _finishFromServer();
          return;
        }
      }

      await _pauseThenAdvance();
    } catch (error) {
      // A 409/422 on Survival usually means the attempt was already completed
      // by the server. Re-reading is cheaper than surfacing a failure the run
      // has already recovered from.
      if (mode.endsOnWrongAnswer && _isTerminalConflict(error)) {
        try {
          final attempt =
              await ref.read(arcadeRepositoryProvider).loadAttempt(attemptId);
          if (attempt.status != 'in_progress') {
            state = state.copyWith(gameOver: true);
            await _finishFromServer();
            return;
          }
        } catch (_) {
          // Fall through to the failure state below.
        }
      }
      _fail(error);
    }
  }

  /// The timer ran out. Nothing is submitted — the API has no "timed out"
  /// answer, and inventing one would be a lie the server cannot score. The
  /// question is left unanswered and the server counts it at completion.
  Future<void> timeOut() async {
    if (!state.isAcceptingInput) return;
    _ticker?.cancel();
    state = state.copyWith(
      phase: ArcadePhase.submitting,
      timedOut: state.timedOut + 1,
      clearSelection: true,
    );
    await _pauseThenAdvance();
  }

  /// Leaves the run without a result. Abandons server-side so the attempt does
  /// not linger in progress; a failure there must not trap the user on screen.
  Future<void> quit() async {
    _ticker?.cancel();
    final attemptId = state.attemptId;
    final phase = state.phase;
    _startKey = null;
    state = const ArcadeState();
    if (attemptId != null &&
        (phase == ArcadePhase.playing || phase == ArcadePhase.submitting)) {
      try {
        await ref.read(arcadeRepositoryProvider).abandon(
              attemptId: attemptId,
              idempotencyKey: 'arcade-abandon-$attemptId',
            );
      } catch (_) {
        // Best effort: the user has already left.
      }
    }
  }

  /// Back to the hub without touching the server (used after a run finished
  /// or failed).
  void reset() {
    _ticker?.cancel();
    _startKey = null;
    state = const ArcadeState();
  }

  Future<void> retryLastStart() async {
    final mode = state.mode;
    if (mode == null) return;
    await start(mode, category: state.category);
  }

  Future<void> _pauseThenAdvance() async {
    final pause = ref.read(arcadeAnswerPauseProvider);
    if (pause > Duration.zero) await Future<void>.delayed(pause);
    await _advance();
  }

  /// Moves to the next question, or finishes.
  ///
  /// Returned as a `Future` on purpose: the caller (an answer, a timeout) must
  /// be able to await the completion write, or the screen's dispose races a
  /// request that is still in flight.
  Future<void> _advance() async {
    if (state.isLastQuestion) {
      await _finish();
      return;
    }
    state = state.copyWith(
      phase: ArcadePhase.playing,
      index: state.index + 1,
      answered: state.answered + 1,
      clearSelection: true,
      secondsLeft: state.mode?.secondsPerQuestion,
      clearSeconds: !(state.mode?.isTimed ?? false),
    );
    _beginQuestion();
  }

  /// Normal end of a run: complete, then show the server's tally.
  Future<void> _finish() async {
    final attemptId = state.attemptId;
    if (attemptId == null) return;
    state = state.copyWith(phase: ArcadePhase.finishing, clearSelection: true);
    try {
      final result = await ref.read(arcadeRepositoryProvider).complete(
            attemptId: attemptId,
            idempotencyKey: 'arcade-complete-$attemptId',
          );
      state = state.copyWith(
        phase: ArcadePhase.finished,
        result: result,
        answered: state.answered + 1,
      );
    } catch (error) {
      _fail(error);
    }
  }

  /// Survival ended server-side; read the verdict instead of completing again.
  Future<void> _finishFromServer() async {
    final attemptId = state.attemptId;
    if (attemptId == null) return;
    state = state.copyWith(phase: ArcadePhase.finishing);
    try {
      final result =
          await ref.read(arcadeRepositoryProvider).results(attemptId);
      state = state.copyWith(
        phase: ArcadePhase.finished,
        result: result,
        answered: state.answered + 1,
      );
    } catch (error) {
      _fail(error);
    }
  }

  void _beginQuestion() {
    _questionStartedAt = DateTime.now();
    _ticker?.cancel();
    final run = state;
    final mode = run.mode;
    if (mode == null || !mode.isTimed || run.current == null) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (state.secondsLeft ?? 1) - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(secondsLeft: 0);
        unawaited(timeOut());
        return;
      }
      state = state.copyWith(secondsLeft: left);
    });
  }

  bool _isTerminalConflict(Object error) {
    final api = toApiException(error);
    return api.statusCode == 409 || api.statusCode == 422;
  }

  void _fail(Object error) {
    _ticker?.cancel();
    state = state.copyWith(
      phase: ArcadePhase.failed,
      error: toApiException(error),
    );
  }
}

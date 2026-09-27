import 'package:meta/meta.dart';
import '../../data/models/lifeline_dto.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/attempt_result.dart';

/// Canonical quiz session state — immutable snapshot consumed by the UI.
enum QuizPhase {
  /// Fetching session from server
  loading,
  /// Answering in progress
  answering,
  /// Awaiting server grading response (shows instant optimistic highlight)
  grading,
  /// Server has responded — show result feedback (green/red)
  feedback,
  /// All questions answered — show results screen
  finished,
  /// Unrecoverable error
  error,
}

@immutable
class QuizState {
  const QuizState({
    required this.phase,
    required this.session,
    required this.currentIndex,
    required this.answers,
    required this.lastResult,
    required this.elapsedSeconds,
    required this.comboCount,
    required this.totalXpEarned,
    required this.totalCoinsEarned,
    this.errorMessage,
    this.attemptId,
    this.selectedOptionId,
    this.isOfflinePractice = false,
    this.lifelinesEnabled = false,
    this.lifelines = const [],
    this.lifelineWalletBalance = 0,
    this.hiddenOptionKeys = const {},
    this.lifelineNotice,
    this.busyLifelineSlug,
  });

  factory QuizState.initial() => const QuizState(
        phase: QuizPhase.loading,
        session: null,
        currentIndex: 0,
        answers: {},
        lastResult: null,
        elapsedSeconds: 0,
        comboCount: 0,
        totalXpEarned: 0,
        totalCoinsEarned: 0,
        isOfflinePractice: false,
      );

  final QuizPhase phase;
  final QuizSession? session;
  final int currentIndex;
  /// Maps questionId → AttemptResult (server graded)
  final Map<String, AttemptResult> answers;
  final AttemptResult? lastResult;
  final int elapsedSeconds;
  final int comboCount;
  final int totalXpEarned;
  final int totalCoinsEarned;
  final String? errorMessage;
  final String? attemptId;
  /// Option selected in the current grading round (shown instantly before response)
  final String? selectedOptionId;
  /// True when session was served from Drift cache and server attempt creation failed.
  final bool isOfflinePractice;

  // ── Lifelines (server-authoritative) ───────────────────────────────────
  /// The server's kill switch for this attempt. `false` hides the bar entirely.
  final bool lifelinesEnabled;

  /// The server's catalogue for this attempt, in the server's own order.
  final List<LifelineDto> lifelines;
  final int lifelineWalletBalance;

  /// Option keys the server told us to hide (50/50, eliminate-one, swap).
  /// Cleared on every question advance. Never derived on-device.
  final Set<String> hiddenOptionKeys;
  /// Text for the effect the server just returned (hint, explanation, poll…).
  final String? lifelineNotice;

  /// Slug of the lifeline currently being spent, for a per-chip spinner.
  final String? busyLifelineSlug;

  bool get hasLifelines => lifelinesEnabled && lifelines.isNotEmpty;
  bool get isLifelineBusy => busyLifelineSlug != null;

  bool isOptionHidden(String optionKey) =>
      hiddenOptionKeys.any((hidden) => hidden.toUpperCase() == optionKey.toUpperCase());

  bool get hasSession => session != null;

  Question? get currentQuestion =>
      session != null && currentIndex < session!.questions.length
          ? session!.questions[currentIndex]
          : null;

  int get remainingSeconds =>
      session != null
          ? (session!.durationSeconds - elapsedSeconds).clamp(0, session!.durationSeconds)
          : 0;

  bool get isTimedOut => session != null && elapsedSeconds >= session!.durationSeconds;

  bool get isLastQuestion =>
      session != null && currentIndex >= session!.questions.length - 1;

  static const _sentinel = Object();

  QuizState copyWith({
    QuizPhase? phase,
    QuizSession? session,
    int? currentIndex,
    Map<String, AttemptResult>? answers,
    Object? lastResult = _sentinel,
    int? elapsedSeconds,
    int? comboCount,
    int? totalXpEarned,
    int? totalCoinsEarned,
    Object? errorMessage = _sentinel,
    String? attemptId,
    Object? selectedOptionId = _sentinel,
    bool? isOfflinePractice,
    bool? lifelinesEnabled,
    List<LifelineDto>? lifelines,
    int? lifelineWalletBalance,
    Set<String>? hiddenOptionKeys,
    Object? lifelineNotice = _sentinel,
    Object? busyLifelineSlug = _sentinel,
  }) {
    return QuizState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      lastResult: lastResult == _sentinel
          ? this.lastResult
          : lastResult as AttemptResult?,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      comboCount: comboCount ?? this.comboCount,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      attemptId: attemptId ?? this.attemptId,
      selectedOptionId: selectedOptionId == _sentinel
          ? this.selectedOptionId
          : selectedOptionId as String?,
      isOfflinePractice: isOfflinePractice ?? this.isOfflinePractice,
      lifelinesEnabled: lifelinesEnabled ?? this.lifelinesEnabled,
      lifelines: lifelines ?? this.lifelines,
      lifelineWalletBalance: lifelineWalletBalance ?? this.lifelineWalletBalance,
      hiddenOptionKeys: hiddenOptionKeys ?? this.hiddenOptionKeys,
      lifelineNotice:
          lifelineNotice == _sentinel ? this.lifelineNotice : lifelineNotice as String?,
      busyLifelineSlug: busyLifelineSlug == _sentinel
          ? this.busyLifelineSlug
          : busyLifelineSlug as String?,
    );
  }
}

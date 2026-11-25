library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// Thin wrapper — keeps FirebaseAnalytics out of features (testable, swappable).
/// Construct via [tryCreate]; null when Firebase is unavailable (dev builds
/// without config) so callers can no-op.
class AnalyticsService {
  AnalyticsService._(this._fa);
  final FirebaseAnalytics _fa;

  /// Null when Firebase was never initialized.
  static AnalyticsService? tryCreate() =>
      Firebase.apps.isNotEmpty ? AnalyticsService._(FirebaseAnalytics.instance) : null;

  Future<void> log(String name, {Map<String, Object>? params}) =>
      _fa.logEvent(name: name, parameters: params);

  /// Identifies the user. Callers should go through `ConsentGatedAnalytics`
  /// rather than this class directly, because this is the most identifying call.
  Future<void> setUser(int? userId) async {
    await _fa.setUserId(id: userId?.toString());
  }
}

/// Event names — frozen per contract, additive only.
/// 20+ events for funnel + retention; use `AnalyticsService.tryCreate()?.log(name)` so dev without Firebase no-ops.
abstract final class AnalyticsEvents {
  static const login = 'login';
  static const logout = 'logout';
  static const register = 'sign_up';
  static const appOpen = 'app_open';
  static const onboardingStart = 'onboarding_start';
  static const onboardingComplete = 'onboarding_complete';
  static const quizStart = 'quiz_start';
  static const quizAnswer = 'quiz_answer';
  static const quizComplete = 'quiz_complete';
  static const quizAbandon = 'quiz_abandon';
  static const quizReviewOpen = 'quiz_review_open';
  static const calculatorOpen = 'calculator_open';
  static const calculatorCalculate = 'calculator_calculate';
  static const calculatorShare = 'calculator_share';
  static const battleMatchSearch = 'battle_match_search';
  static const battleMatchFound = 'battle_match_found';
  static const battleAnswerSubmit = 'battle_answer_submit';
  /// Emitted once when RTDB reports `status == 'finished'` in
  /// `BattleController._subscribeRtdb` — the server's terminal transition.
  static const battleFinished = 'battle_finished';

  /// Legacy alias of [battleFinished] kept for the frozen event vocabulary.
  /// Not emitted: two names for one transition would split the funnel.
  static const battleComplete = 'battle_complete';
  static const streakView = 'streak_view';
  static const shareOpen = 'share_open';

  /// Not emitted. Qualification is decided by the server when a referred
  /// account completes its first graded quiz; the client never sees that
  /// transition, so logging it here would be a guess.
  static const referralQualified = 'referral_qualified';
  static const notificationOpen = 'notification_open';
  static const pushTokenRegister = 'push_token_register';
  static const courseView = 'course_view';

  /// Not emitted. The daily quiz card on Home navigates to the ordinary
  /// `/quiz` catalog and `QuizController.startSession` receives the same
  /// `quizId` as any other quiz, so there is no client-observable transition
  /// that identifies a "daily" attempt. Emitting it from the card tap would
  /// count a catalog open as a quiz start. Wire it when a daily-specific
  /// attempt route exists.
  static const dailyQuizStart = 'daily_quiz_start';

  /// Not emitted. The write outbox is built but deliberately unwired (quiz
  /// grading is server-authoritative), so there is no sync to report.
  static const offlineQueueSync = 'offline_queue_sync';
}

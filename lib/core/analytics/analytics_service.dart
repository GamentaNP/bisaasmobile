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
  static const battleComplete = 'battle_complete';
  static const streakView = 'streak_view';
  static const shareOpen = 'share_open';
  static const referralQualified = 'referral_qualified';
  static const notificationOpen = 'notification_open';
  static const pushTokenRegister = 'push_token_register';
  static const courseView = 'course_view';
  static const dailyQuizStart = 'daily_quiz_start';
  static const offlineQueueSync = 'offline_queue_sync';
}

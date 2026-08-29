library;

import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper — keeps FirebaseAnalytics out of features (testable, swappable).
class AnalyticsService {
  AnalyticsService(this._fa);
  final FirebaseAnalytics _fa;

  Future<void> log(String name, {Map<String, Object>? params}) =>
      _fa.logEvent(name: name, parameters: params);

  Future<void> setUser(int? userId) async {
    await _fa.setUserId(id: userId?.toString());
  }
}

/// Event names — frozen per contract, additive only.
abstract final class AnalyticsEvents {
  static const quizStart = 'quiz_start';
  static const quizAnswer = 'quiz_answer';
  static const quizComplete = 'quiz_complete';
  static const shareOpen = 'share_open';
  static const referralQualified = 'referral_qualified';
}

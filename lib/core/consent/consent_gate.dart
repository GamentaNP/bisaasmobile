import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import 'consent_controller.dart';
import 'consent_state.dart';

/// Wraps [AnalyticsService] so events are dropped unless analytics consent was
/// granted.
///
/// This is the part that makes the consent screen real. There is a temptation
/// to implement consent as a banner that records a choice, and leave the event
/// calls alone — but the app already logged `login`, `logout`, push-token
/// lengths and every battle answer through [AnalyticsService] with no gate at
/// all, so a banner on top of that would be recording consent to something that
/// had already happened.
///
/// Dropped events are counted so the gate itself is observable: a silent no-op
/// would be indistinguishable from a broken pipeline.
class ConsentGatedAnalytics {
  ConsentGatedAnalytics(this._inner, this._consent);

  final AnalyticsService? _inner;
  final ConsentState Function() _consent;

  int droppedEvents = 0;

  /// True when an event would actually be sent. Exposed so a screen can be
  /// honest about it, and so tests can assert on the gate rather than on a mock.
  bool get isEnabled =>
      _inner != null && _consent().granted(ConsentCategory.analytics);

  Future<void> log(String name, {Map<String, Object>? params}) async {
    if (!isEnabled) {
      droppedEvents++;
      return;
    }
    try {
      await _inner!.log(name, params: params);
    } catch (e) {
      // Analytics must never surface as a user-visible failure.
      AppLogger.w('analytics log failed for $name: $e');
    }
  }

  Future<void> setUser(int? userId) async {
    if (!isEnabled) return;
    try {
      await _inner!.setUser(userId);
    } catch (e) {
      AppLogger.w('analytics setUser failed: $e');
    }
  }

  /// Identifies the user to the analytics provider. Also consent-gated, because
  /// it is arguably the most identifying call in the set.
  Future<void> identifyUser(int? userId) async {
    if (!isEnabled) return;
    try {
      await _inner!.setUser(userId);
    } catch (e) {
      AppLogger.w('analytics setUser failed: $e');
    }
  }
}

/// Reads the current consent synchronously.
///
/// Analytics call sites are spread across features and are called from `initState`
/// and callbacks, where awaiting an `AsyncValue` would be awkward. Reading from
/// the notifier's cached state is safe because [ConsentController] loads from
/// local storage during boot, before the first frame.
final analyticsProvider = Provider<ConsentGatedAnalytics>((ref) {
  final inner = AnalyticsService.tryCreate();
  return ConsentGatedAnalytics(
    inner,
    () => ref.read(consentProvider).value ?? const ConsentState.unknown(),
  );
});

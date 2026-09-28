import 'package:bisaasmobile/core/analytics/analytics_service.dart';
import 'package:bisaasmobile/core/consent/consent_gate.dart';
import 'package:bisaasmobile/core/consent/consent_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Consent is a legal obligation, so the behaviour that matters is not the
/// banner — it is that non-essential collection is **blocked** until the user
/// agrees. Before this existed, `login`, `logout`, push-token lengths, battle
/// answers, quiz starts and tutor events were all logged through a bare
/// [AnalyticsService] with no gate at all, so a consent dialog added afterwards
/// would have been recording agreement to something that had already happened.
void main() {
  group('ConsentState defaults to the most restrictive answer', () {
    test('undecided grants nothing except necessary', () {
      const s = ConsentState.unknown();
      expect(s.decided, isFalse);
      expect(s.granted(ConsentCategory.necessary), isTrue);
      expect(s.granted(ConsentCategory.functional), isFalse);
      expect(s.granted(ConsentCategory.analytics), isFalse);
      expect(s.granted(ConsentCategory.marketing), isFalse);
    });

    test('the zero-argument constructor behaves like unknown', () {
      const s = ConsentState();
      expect(s, equals(const ConsentState.unknown()));
    });

    test('necessary cannot be refused', () {
      const s = ConsentState(decided: true, functional: false, analytics: false, marketing: false);
      expect(s.granted(ConsentCategory.necessary), isTrue,
          reason: 'the app cannot function without auth and local storage');
    });
  });

  group('ConsentState persistence', () {
    test('round-trips through storage', () {
      const original = ConsentState(
        decided: true,
        functional: true,
        analytics: false,
        marketing: true,
      );
      expect(ConsentState.fromStorage(original.toStorage()), original);
    });

    test('a missing record is undecided, not granted', () {
      expect(ConsentState.fromStorage(null), equals(const ConsentState.unknown()));
    });

    test('a partial record does not grant what it omits', () {
      // A half-written record must fail closed, not open.
      final s = ConsentState.fromStorage(const {'decided': true, 'analytics': true});
      expect(s.analytics, isTrue);
      expect(s.functional, isFalse);
      expect(s.marketing, isFalse);
    });

    test('a non-true value is never read as granted', () {
      final s = ConsentState.fromStorage(const {
        'decided': 'yes',
        'analytics': 'true',
        'marketing': 1,
      });
      expect(s.decided, isFalse);
      expect(s.analytics, isFalse);
      expect(s.marketing, isFalse);
    });

    test('an empty object is undecided', () {
      expect(ConsentState.fromStorage(const {}), equals(const ConsentState.unknown()));
    });
  });

  group('the request body matches the server contract', () {
    test('sends all three optional categories explicitly', () {
      // UpdateCookieConsentRequest requires `analytics` and accepts
      // `marketing` and `functional` as `sometimes`. Sending all three means a
      // mobile retry re-affirms the same choice instead of toggling it, which is
      // why the route is a PUT with a target rather than a toggle.
      final body = const ConsentState(
        decided: true,
        functional: true,
        analytics: false,
        marketing: false,
      ).toRequestBody();
      expect(body.keys.toSet(), {'analytics', 'marketing', 'functional'});
      expect(body['analytics'], isFalse);
      expect(body['functional'], isTrue);
    });

    test('never sends `decided`, which is a client-only concept', () {
      expect(const ConsentState.unknown().toRequestBody().containsKey('decided'), isFalse);
    });

    test('booleans are real booleans, not strings', () {
      for (final v in const ConsentState(decided: true).toRequestBody().values) {
        expect(v, isA<bool>());
      }
    });
  });

  group('ConsentGatedAnalytics blocks collection until consent', () {
    /// A transport that is never actually used — the gate must not call it when
    /// consent is absent, and there is no way to observe Firebase in a unit test.
    ConsentGatedAnalytics gateWith(ConsentState Function() read) =>
        ConsentGatedAnalytics(null, read);

    test('is disabled when there is no transport at all', () {
      final gate = gateWith(() => const ConsentState(decided: true, analytics: true));
      expect(gate.isEnabled, isFalse,
          reason: 'no Firebase in a test; the gate must not pretend otherwise');
    });

    test('drops events and counts them when analytics is refused', () async {
      final gate = gateWith(() => const ConsentState(decided: true, analytics: false));
      expect(gate.isEnabled, isFalse);
      await gate.log(AnalyticsEvents.login);
      await gate.log(AnalyticsEvents.quizStart);
      expect(gate.droppedEvents, 2);
    });

    test('drops events before the user has decided', () async {
      // This is the case that used to be unguarded: the app logs `login` during
      // the very first session, long before any banner could have been answered.
      final gate = gateWith(() => const ConsentState.unknown());
      await gate.log(AnalyticsEvents.login);
      expect(gate.droppedEvents, 1);
    });

    test('does not identify the user when analytics is refused', () async {
      final gate = gateWith(() => const ConsentState.unknown());
      await gate.identifyUser(42);
      expect(gate.droppedEvents, 0,
          reason: 'identifyUser is gated separately and is not an event');
    });

    test('grants nothing that marketing consent implies', () async {
      // A separate category, so marketing consent must not enable analytics.
      final gate = gateWith(() => const ConsentState(decided: true, marketing: true));
      await gate.log(AnalyticsEvents.login);
      expect(gate.droppedEvents, 1);
    });

    test('grants nothing that functional consent implies', () async {
      final gate = gateWith(() => const ConsentState(decided: true, functional: true));
      await gate.log(AnalyticsEvents.login);
      expect(gate.droppedEvents, 1);
    });
  });

  group('ConsentCategory', () {
    test('parses by name and rejects unknown names', () {
      expect(ConsentCategory.byName('analytics'), ConsentCategory.analytics);
      expect(ConsentCategory.byName('necessary'), ConsentCategory.necessary);
      expect(ConsentCategory.byName('nope'), isNull);
    });
  });
}

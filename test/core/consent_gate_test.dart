import 'package:bisaasmobile/core/consent/consent_gate.dart';
import 'package:bisaasmobile/core/consent/consent_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gate is the only thing standing between "the user said no" and the app
/// still sending events, so it gets direct tests rather than relying on the
/// screens that call it.
///
/// There is deliberately no Firebase here: `AnalyticsService.tryCreate()` returns
/// null without a configured project, and the gate must treat that as "cannot
/// send" rather than as "send anyway".
void main() {
  ConsentGatedAnalytics gate(ConsentState Function() read) =>
      ConsentGatedAnalytics(null, read);

  group('the gate fails closed', () {
    test('no transport means disabled even with consent granted', () {
      final g = gate(() => const ConsentState(decided: true, analytics: true));
      expect(g.isEnabled, isFalse);
    });

    test('consent granted but no transport still drops events', () async {
      final g = gate(() => const ConsentState(decided: true, analytics: true));
      await g.log('login');
      await g.log('logout');
      expect(g.droppedEvents, 2);
    });

    test('consent refused drops events', () async {
      final g = gate(() => const ConsentState(decided: true, analytics: false));
      await g.log('quiz_start');
      expect(g.droppedEvents, 1);
    });

    test('undecided drops events', () async {
      final g = gate(() => const ConsentState.unknown());
      await g.log('login');
      expect(g.droppedEvents, 1);
    });
  });

  group('categories do not leak into each other', () {
    test('marketing consent does not enable analytics', () async {
      final g = gate(() => const ConsentState(decided: true, marketing: true));
      await g.log('login');
      expect(g.droppedEvents, 1);
    });

    test('functional consent does not enable analytics', () async {
      final g = gate(() => const ConsentState(decided: true, functional: true));
      await g.log('login');
      expect(g.droppedEvents, 1);
    });

    test('necessary is always granted but is not analytics', () async {
      // The only category that is unconditionally true, and it is deliberately
      // not the analytics category.
      const s = ConsentState.unknown();
      expect(s.granted(ConsentCategory.necessary), isTrue);
      expect(s.granted(ConsentCategory.analytics), isFalse);
    });
  });

  group('identifyUser is gated separately from event logging', () {
    test('a refused identify call is not counted as a dropped event', () async {
      final g = gate(() => const ConsentState.unknown());
      await g.identifyUser(42);
      expect(g.droppedEvents, 0,
          reason: 'it is not an event, so it must not inflate the event count');
    });

    test('identifyUser does not throw when consent is refused', () async {
      final g = gate(() => const ConsentState(decided: true, analytics: false));
      await g.identifyUser(null);
    });
  });

  group('the gate never throws into a caller', () {
    // Call sites are `unawaited(analytics.log(...))` inside controllers, so an
    // exception here would become an unhandled async error.
    test('log is a no-op path when disabled, not a throwing path', () async {
      final g = gate(() => const ConsentState.unknown());
      await expectLater(g.log('app_open', params: {'a': 1}), completes);
    });

    test('the dropped counter is monotonic', () async {
      final g = gate(() => const ConsentState.unknown());
      await g.log('a');
      expect(g.droppedEvents, 1);
      await g.log('b');
      await g.log('c');
      expect(g.droppedEvents, 3);
    });
  });
}

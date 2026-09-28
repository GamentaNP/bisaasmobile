import 'package:bisaasmobile/features/privacy/domain/entities/visitor_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// The anonymous-visitor surface is the server twin of the local consent
/// choices, and it has one rule that is easy to break: **the client must never
/// send a visitor id.** Identity comes from an HMAC-signed `_bs_vid` cookie
/// attached by middleware, and the route comment is explicit that it is "never
/// by a request value the client could forge".
void main() {
  group('VisitorConsentMode', () {
    test('parses the three server modes', () {
      expect(VisitorConsentMode.byName('analytics'), VisitorConsentMode.analytics);
      expect(VisitorConsentMode.byName('functional'), VisitorConsentMode.functional);
      expect(VisitorConsentMode.byName('none'), VisitorConsentMode.none);
    });

    test('is case-insensitive', () {
      expect(VisitorConsentMode.byName('ANALYTICS'), VisitorConsentMode.analytics);
    });

    test('an unknown mode falls back to the restrictive default, never to opt-in', () {
      // A new or malformed server value must not be read as consent.
      expect(VisitorConsentMode.byName('granted'), VisitorConsentMode.functional);
      expect(VisitorConsentMode.byName('true'), VisitorConsentMode.functional);
      expect(VisitorConsentMode.byName(null), VisitorConsentMode.functional);
      expect(VisitorConsentMode.byName(''), VisitorConsentMode.functional);
    });

    test('only analytics mode grants analytics', () {
      expect(VisitorConsentMode.analytics.grantsAnalytics, isTrue);
      expect(VisitorConsentMode.functional.grantsAnalytics, isFalse);
      expect(VisitorConsentMode.none.grantsAnalytics, isFalse);
    });

    test('round-trips the wire value', () {
      for (final mode in VisitorConsentMode.values) {
        expect(VisitorConsentMode.byName(mode.wireValue), mode);
      }
    });
  });

  group('VisitorData', () {
    const empty = VisitorData(
      visitorId: 'v-1',
      consentMode: VisitorConsentMode.functional,
      eventCount: 0,
    );

    test('no events means nothing stored', () {
      expect(empty.hasStoredData, isFalse);
    });

    test('any event means something is stored', () {
      const some = VisitorData(
        visitorId: 'v-1',
        consentMode: VisitorConsentMode.analytics,
        eventCount: 1,
      );
      expect(some.hasStoredData, isTrue);
    });

    test('an anonymous profile can be erased here', () {
      expect(empty.canEraseHere, isTrue);
    });

    test('a stitched profile cannot, because erasure moves to the account flow', () {
      // DELETE /visitor-data returns ERASURE_REQUIRES_ACCOUNT for these, so the
      // button must not be offered.
      const stitched = VisitorData(
        visitorId: 'v-1',
        consentMode: VisitorConsentMode.analytics,
        eventCount: 4,
        stitched: true,
      );
      expect(stitched.canEraseHere, isFalse);
    });

    test('zero events with analytics consent is a valid state, not an error', () {
      const granted = VisitorData(
        visitorId: 'v-1',
        consentMode: VisitorConsentMode.analytics,
        eventCount: 0,
      );
      expect(granted.hasStoredData, isFalse);
      expect(granted.consentMode.grantsAnalytics, isTrue);
    });
  });
}

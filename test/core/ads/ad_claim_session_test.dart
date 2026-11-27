import 'package:bisaasmobile/core/ads/ad_claim_session.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdClaimSession.fromJson', () {
    test('reads the camelCase claimToken from data', () {
      final session = AdClaimSession.fromJson(<String, dynamic>{
        'claimToken': 'server-issued-token',
        'requiredDurationSeconds': 15,
        'coinsExpected': 20,
        'issuedAt': '2026-11-27T00:00:00Z',
      });

      expect(session.claimToken, 'server-issued-token');
      expect(session.requiredDurationSeconds, 15);
      expect(session.coinsExpected, 20);
    });

    test('a missing or empty token is contract drift, not a claim', () {
      expect(
        () => AdClaimSession.fromJson(<String, dynamic>{}),
        throwsA(isA<ContractViolation>()),
      );
      expect(
        () => AdClaimSession.fromJson(<String, dynamic>{'claimToken': ''}),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('negative or non-numeric watch time clamps to zero', () {
      final negative = AdClaimSession.fromJson(<String, dynamic>{
        'claimToken': 'token',
        'requiredDurationSeconds': -5,
      });
      final absent = AdClaimSession.fromJson(<String, dynamic>{
        'claimToken': 'token',
      });
      expect(negative.requiredDurationSeconds, 0);
      expect(absent.requiredDurationSeconds, 0);
      expect(absent.coinsExpected, isNull);
    });
  });
}

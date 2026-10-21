/// Cross-layer test for the calculator result share.
///
/// POST /api/v1/calculator/permalinks takes the inline payload.
/// POST /api/v1/share is snapshot-only and demands a calculable_type the
/// client cannot mint, so the permalink route is the one a mobile client can
/// actually use.
library;

import 'package:bisaasmobile/features/calculator/data/datasources/calculator_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {  group('the calculator share', () {
    test('the permalink is minted from the inline payload', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/calculator/permalinks',
        FakeRoute.ok(<String, dynamic>{
          'ulid': 'ULID123',
          'domain': 'civil',
          'calculator_slug': 'slab-volume',
          'url': 'https://bisaas.com/calculators/civil/slab-volume?share=ULID123',
          'standalone_url': 'https://bisaas.com/s/ULID123',
          'report_url': 'https://bisaas.com/s/ULID123/report',
          'intent': 'rehydrate',
        }),
      );

      final remote = CalculatorRemoteDataSource(dioFor(api));
      final permalink = await remote.createPermalink(
        domain: 'civil',
        calculatorSlug: 'slab-volume',
        inputs: <String, dynamic>{'length': 4},
        results: <String, dynamic>{'volume': 12},
      );

      expect(permalink.url, contains('ULID123'));
      expect(permalink.standaloneUrl, isNotNull);

      final body = api.jsonBodyOf(0);
      expect(body['domain'], 'civil');
      expect(body['calculator_slug'], 'slab-volume');
      expect(body['inputs'], <String, dynamic>{'length': 4});
      expect(body['results'], <String, dynamic>{'volume': 12});
      // The recipient's calculator recomputes, so the intent is `rehydrate`.
      expect(body['intent'], 'rehydrate');
    });
  });
}

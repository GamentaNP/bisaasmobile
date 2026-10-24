import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/features/courses/data/corpus_availability.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/support/fake_api.dart';

/// The `courses` feature had zero coverage; this pins the corpus-probe
/// contract that decides whether an entry tile is offered at all — the exact
/// logic that once shipped an empty Books reader to every user.
void main() {
  test('corpus status offers a corpus whose meta.total is non-zero', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on('GET', '/library/files', FakeRoute.envelope({
      'success': true,
      'data': <Object>[],
      'meta': {'total': 42},
    }));

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dioFor(api)),
    ]);
    addTearDown(container.dispose);

    final status = await container.read(corpusStatusProvider('library').future);

    expect(status.availability, CorpusAvailability.available);
    expect(status.count, 42);
    expect(status.isOffered, isTrue);
  });

  test('an empty corpus reads as empty, not broken', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on('GET', '/books', FakeRoute.envelope({
      'success': true,
      'data': <Object>[],
      'meta': {'total': 0},
    }));

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dioFor(api)),
      appConfigValueProvider.overrideWithValue(
        const AppConfig(features: {'book_engine': true}),
      ),
    ]);
    addTearDown(container.dispose);

    final status = await container.read(corpusStatusProvider('books').future);

    expect(status.availability, CorpusAvailability.empty);
    expect(status.isOffered, isFalse);
  });

  test('a corpus the operator switched off is empty without a probe', () async {
    final api = FakeApi(<String, FakeRoute>{});
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dioFor(api)),
      appConfigValueProvider.overrideWithValue(
        const AppConfig(features: {'library_enabled': false}),
      ),
    ]);
    addTearDown(container.dispose);

    final status = await container.read(corpusStatusProvider('library').future);

    expect(status.availability, CorpusAvailability.empty);
    // The probe must never have fired — the config alone settles it.
    expect(api.requests, isEmpty);
  });

  test('a signed-out probe (401) keeps the corpus visible with its code', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on('GET', '/library/files',
        FakeRoute.error(401, 'UNAUTHENTICATED', 'Unauthenticated.'));

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dioFor(api)),
    ]);
    addTearDown(container.dispose);

    final status = await container.read(corpusStatusProvider('library').future);

    // Regression: the 401 path used to return an empty corpus code, losing
    // the identifier the tile needs to explain itself.
    expect(status.code, 'library');
    expect(status.availability, CorpusAvailability.unknown);
    expect(status.isOffered, isTrue);
  });

  test('a server error keeps the corpus visible rather than hiding it', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on('GET', '/syllabi',
        FakeRoute.error(500, 'SERVER_ERROR', 'Boom.'));

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dioFor(api)),
    ]);
    addTearDown(container.dispose);

    final status = await container.read(corpusStatusProvider('syllabus').future);

    expect(status.availability, CorpusAvailability.unknown);
    expect(status.isOffered, isTrue);
  });
}

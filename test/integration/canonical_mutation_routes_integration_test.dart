/// The four mutation routes that used to be near-misses.
///
/// A wrong path is a guaranteed 404 and a wrong verb is a guaranteed 405, so
/// these are pinned at the transport boundary where the mismatch is visible.
/// Every assertion checks the actual method + path sent to the adapter, not
/// just that a future completed.
library;

import 'package:bisaasmobile/features/contests/data/datasources/contests_remote_data_source.dart';
import 'package:bisaasmobile/features/live_events/data/datasources/live_events_remote_data_source.dart';
import 'package:bisaasmobile/features/tutor/data/datasources/tutor_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late FakeApi api;

  setUp(() => api = FakeApi(<String, FakeRoute>{}));

  group('AI tutor onboarding', () {
    late TutorRemoteDataSource remote;
    setUp(() => remote = TutorRemoteDataSource(dioFor(api)));

    test('start uses the canonical POST /learning/ai-tutor/onboarding', () async {
      api.on(
        'POST',
        '/learning/ai-tutor/onboarding',
        FakeRoute.ok(<String, dynamic>{'session_id': 's-1'}),
      );

      final result = await remote.startOnboarding();

      expect(result.sessionId, 's-1');
      expect(api.indexOfRequest('POST', '/learning/ai-tutor/onboarding'), 0);
    });

    test('completion uses PUT /learning/ai-tutor/onboarding/completion', () async {
      api.on(
        'PUT',
        '/learning/ai-tutor/onboarding/completion',
        FakeRoute.ok(<String, dynamic>{'success': true}),
      );

      final result = await remote.completeOnboarding(sessionId: 's-1');

      expect(result.success, isTrue);
      expect(
        api.indexOfRequest('PUT', '/learning/ai-tutor/onboarding/completion'),
        0,
      );
      expect(api.jsonBodyOf(0)['session_id'], 's-1');
    });
  });

  group('contest entry', () {
    test('uses PUT /quiz/contests/{id}/entry', () async {
      api.on(
        'PUT',
        '/quiz/contests/7/entry',
        FakeRoute.ok(<String, dynamic>{'attempt_id': 42}),
      );
      final remote = ContestsRemoteDataSource(dioFor(api));

      final result = await remote.enterContest(7);

      expect(result.attemptId, 42);
      expect(api.indexOfRequest('PUT', '/quiz/contests/7/entry'), 0);
    });
  });

  group('live-event check-in', () {
    test('uses PUT /quiz/live-events/{id}/attendance', () async {
      api.on(
        'PUT',
        '/quiz/live-events/9/attendance',
        FakeRoute.ok(<String, dynamic>{
          'participant': <String, dynamic>{
            'id': 5,
            'event_id': 9,
            'status': 'checked_in',
          },
        }),
      );
      final remote = LiveEventsRemoteDataSource(dioFor(api));

      final result = await remote.checkIn(9);

      expect(result.status, 'checked_in');
      expect(api.indexOfRequest('PUT', '/quiz/live-events/9/attendance'), 0);
    });
  });
}

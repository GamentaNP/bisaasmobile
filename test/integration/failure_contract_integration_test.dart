/// The failure contract, asserted on the data sources that were the worst
/// offenders.
///
/// The rule: a data source **throws** on a transport error, a non-2xx status
/// or a body it does not understand. It may only return an empty collection
/// when the server actually published zero rows.
///
/// The two cases that mattered most were:
///
///  * the **streak**, where a failure used to render as `currentStreak: 0` —
///    a *plausible* business value, not an obviously broken one, so an outage
///    was indistinguishable from a genuine reset; and
///  * the **leaderboard** and the **coaching** surfaces, where a dead
///    endpoint rendered as "you have no ranks" / "no study plan".
library;

import 'package:bisaasmobile/features/coaching/data/datasources/coaching_remote_data_source.dart';
import 'package:bisaasmobile/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:bisaasmobile/features/streak/data/datasources/streak_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('the streak', () {
    late FakeApi api;
    late StreakRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = StreakRemoteDataSource(dioFor(api));
    });

    test('a server error is an error, not a zero streak', () async {
      api.on(
        'GET',
        '/quiz/streak',
        FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      );

      await expectLater(remote.getStreak(), throwsA(isA<Object>()));
    });

    test('an unreadable body is an error, not a zero streak', () async {
      api.on(
        'GET',
        '/quiz/streak',
        FakeRoute.raw(<String, dynamic>{'unexpected': 'shape'}),
      );

      await expectLater(remote.getStreak(), throwsA(isA<Object>()));
    });

    test('a real streak is read', () async {
      api.on(
        'GET',
        '/quiz/streak',
        FakeRoute.ok(<String, dynamic>{
          'current_streak': 7,
          'longest_streak': 21,
        }),
      );

      final streak = await remote.getStreak();

      expect(streak.currentStreak, 7);
      expect(streak.longestStreak, 21);
    });
  });

  group('the leaderboard', () {
    late FakeApi api;
    late LeaderboardRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = LeaderboardRemoteDataSource(dioFor(api));
    });

    test('a server error is an error, not an empty leaderboard', () async {
      api.on(
        'GET',
        '/quiz/leaderboards/1',
        FakeRoute.error(503, 'SERVICE_UNAVAILABLE', 'down'),
      );

      await expectLater(remote.getLeaderboard(1), throwsA(isA<Object>()));
    });

    test('my-ranks: an unreadable body is an error, not an empty list', () async {
      api.on(
        'GET',
        '/quiz/leaderboards/my-rank',
        FakeRoute.raw(<String, dynamic>{'unexpected': 'shape'}),
      );

      await expectLater(remote.getMyRanks(), throwsA(isA<Object>()));
    });
  });

  group('the coaching surfaces', () {
    late FakeApi api;
    late CoachingRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = CoachingRemoteDataSource(dioFor(api));
    });

    test('a server error on the readiness check is an error', () async {
      api.on(
        'GET',
        '/learning/goals/7/readiness',
        FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      );

      await expectLater(remote.getReadiness('7'), throwsA(isA<Object>()));
    });

    test('an unreadable weak-areas body is an error, not null', () async {
      api.on(
        'GET',
        '/learning/ai-tutor/weak-areas',
        FakeRoute.raw(<String, dynamic>{'unexpected': 'shape'}),
      );

      await expectLater(remote.getWeakAreasRaw(), throwsA(isA<Object>()));
    });

    test('a legitimately empty coaching payload is still empty', () async {
      // `data: null` is the server saying "there is no plan" — that is a real
      // answer and must not become an error.
      api.on(
        'GET',
        '/learning/ai-tutor/weak-areas',
        FakeRoute.raw(<String, dynamic>{'data': null}),
      );

      expect(await remote.getWeakAreasRaw(), isNull);
    });
  });
}

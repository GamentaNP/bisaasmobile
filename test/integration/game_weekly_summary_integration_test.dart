/// Cross-layer test for `GET /quiz/game/weekly-summary`, a live server read the
/// client previously never called (audit §2.3). A wrong path, a drifted shape
/// or a swallowed error fails here rather than showing a zeroed dashboard.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/game/data/datasources/game_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _payload() => <String, dynamic>{
      'weekStartDate': '2026-11-23',
      'levelsCompleted': 7,
      'totalStarsEarned': 21,
      'coinsEarned': 140,
      'xpEarned': 350,
      'accuracyPct': 82.5,
      'bestStreak': 9,
      'timeSpentSeconds': 3600,
    };

void main() {
  test('reads the server-computed summary for the current week', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/game/weekly-summary',
      FakeRoute.ok(_payload()),
    );
    final source = GameRemoteDataSource(dioFor(api));

    final summary = await source.getWeeklySummary();

    expect(api.requests.single.path, '/quiz/game/weekly-summary');
    expect(summary['levelsCompleted'], 7);
    expect(summary['accuracyPct'], 82.5);
  });

  test('passes an explicit week to the server', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/game/weekly-summary',
      FakeRoute.ok(_payload()),
    );
    final source = GameRemoteDataSource(dioFor(api));

    await source.getWeeklySummary(week: '2026-W48');

    expect(
      api.requests.single.queryParameters['week'],
      '2026-W48',
    );
  });

  test('a missing required field is contract drift, not a zeroed value', () async {
    final api = FakeApi(<String, FakeRoute>{});
    final payload = _payload()..remove('bestStreak');
    api.on(
      'GET',
      '/quiz/game/weekly-summary',
      FakeRoute.ok(payload),
    );
    final source = GameRemoteDataSource(dioFor(api));

    await expectLater(
      source.getWeeklySummary(),
      throwsA(isA<ContractViolation>()),
    );
  });
}

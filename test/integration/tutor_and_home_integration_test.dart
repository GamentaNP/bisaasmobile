/// Cross-layer tests for the two flows that were silently broken.
///
/// 1. The tutor chat posted to `/learning/ai-tutor/chat`, which the server
///    does **not** record in the AI-usage ledger — so "Your AI usage" showed
///    zero requests no matter how much the user had chatted. It now posts to
///    `/learning/tutor`, the only mobile-reachable route the rollup reads.
///
/// 2. The home dashboard merged five endpoints and answered a total outage
///    with a zeroed dashboard that was indistinguishable from a real
///    account with nothing to do. It now throws, so the screen's offline
///    treatment is reachable.
library;

import 'package:bisaasmobile/features/home/data/datasources/home_remote_data_source.dart';
import 'package:bisaasmobile/features/tutor/data/datasources/tutor_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('the tutor chat', () {
    late FakeApi api;
    late TutorRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = TutorRemoteDataSource(dioFor(api));
    });

    test('posts to /learning/tutor — the route the usage rollup reads', () async {
      api.on(
        'POST',
        '/learning/tutor',
        FakeRoute.ok(<String, dynamic>{
          'answer': 'Use a factor of safety of 1.5 for this case.',
        }),
      );

      await remote.chat('What factor of safety should I use?', topic: 'Structural');

      expect(api.requests.single.path, '/learning/tutor');
      final body = api.jsonBodyOf(0);
      expect(body['topic'], 'Structural');
      expect(body['question'], 'What factor of safety should I use?');
    });

    test('the body is what the server validates', () async {
      api.on(
        'POST',
        '/learning/tutor',
        FakeRoute.ok(<String, dynamic>{'answer': 'ok'}),
      );

      await remote.chat(
        'Explain this',
        topic: 'Geodesy',
        history: <Map<String, String>>[
          <String, String>{'role': 'user', 'content': 'my earlier answer'},
          <String, String>{'role': 'assistant', 'content': 'the tutor said'},
        ],
      );

      final body = api.jsonBodyOf(0);
      // `topic` and `question` are required by the server; the learner's own
      // last message is sent as the misconception context.
      expect(body.containsKey('topic'), isTrue);
      expect(body.containsKey('question'), isTrue);
      expect(body['learner_answer'], 'my earlier answer');
    });
  });

  group('the home dashboard', () {
    late FakeApi api;
    late HomeRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = HomeRemoteDataSource(dioFor(api));
    });

    void failEverything() {
      for (final path in const [
        '/me',
        '/quiz/streak',
        '/quiz/daily',
        '/learning/today',
        '/quiz/game/missions/dashboard',
      ]) {
        api.on('GET', path, FakeRoute.error(503, 'SERVICE_UNAVAILABLE', 'down'));
      }
    }

    test('a total outage is an error, not a zeroed dashboard', () async {
      failEverything();

      await expectLater(remote.getDashboard(), throwsA(isA<Object>()));
    });

    test('one absent section does not blank the whole dashboard', () async {
      // A 404 on `/quiz/daily` means "no daily quiz is scheduled" — a real
      // answer, and the merge simply leaves that part out.
      api.on('GET', '/me', FakeRoute.ok(<String, dynamic>{
            'user': <String, dynamic>{'level': 4, 'xp': 900, 'coins': 120},
          }));
      api.on('GET', '/quiz/streak', FakeRoute.ok(<String, dynamic>{
            'current_streak': 6,
          }));
      api.on('GET', '/quiz/daily', FakeRoute.error(404, 'NOT_FOUND', 'none'));
      api.on('GET', '/learning/today', FakeRoute.ok(<String, dynamic>{
            'active_course': <String, dynamic>{'title': 'Structures', 'progress': 0.4},
          }));
      api.on('GET', '/quiz/game/missions/dashboard', FakeRoute.ok(<String, dynamic>{
            'streak': <String, dynamic>{'current_streak': 6},
          }));

      final dashboard = await remote.getDashboard();

      expect(dashboard.streakDays, 6);
      expect(dashboard.level, 4);
      expect(dashboard.coinsBalance, 120);
      // The absent section is absent, not a fabricated "no daily quiz".
      expect(dashboard.dailyQuizScheduled, isFalse);
    });
  });
}

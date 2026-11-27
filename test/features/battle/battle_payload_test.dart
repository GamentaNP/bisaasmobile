import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/battle/data/datasources/battle_remote_data_source.dart';
import 'package:bisaasmobile/features/battle/data/models/battle_payload.dart';
import 'package:bisaasmobile/features/battle/data/repositories/battle_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements BattleRemoteDataSource {}

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> canonicalPayload({
  String mode = '3v3',
  String? token = 'fresh-token',
  int questionCount = 6,
}) {
  return {
    'id': 'fb-1',
    'status': 'in_progress',
    'mode': mode,
    'firebase_battle_id': 'fb-1',
    'firebase_token': token,
    'questions': [
      for (var i = 1; i <= 2; i++)
        {
          'id': '10$i',
          'body': 'Question $i',
          'options': [
            {'key': '1', 'text': 'First'},
            {'key': '2', 'text': 'Second'},
            {'key': '3', 'text': 'Third'},
            {'key': '4', 'text': 'Fourth'},
          ],
        },
    ],
    'started_at': '2026-11-27T10:00:00Z',
    'per_question_seconds': 30,
    'total_questions': questionCount,
    'players': [
      for (var i = 1; i <= 6; i++)
        {
          'uid': 'u$i',
          'id': i,
          'name': 'Player $i',
          'team': i <= 3 ? 'A' : 'B',
          'score': i,
        },
    ],
    'me': {'uid': 'u1', 'id': 1},
  };
}

void main() {
  setUpAll(() => registerFallbackValue(Options()));

  group('canonical payload', () {
    test('parses questions, teams, mode, token and server timing', () {
      final m = BattlePayload.parse(canonicalPayload());

      expect(m.id, 'fb-1');
      expect(m.rtdbId, 'fb-1');
      expect(m.status, 'in_progress');
      expect(m.mode, '3v3');
      expect(m.firebaseToken, 'fresh-token');
      expect(m.questions, hasLength(2));
      expect(m.questions.first.text, 'Question 1');
      expect(m.questions.first.options.first.order, 0);
      expect(m.questions.first.options.last.order, 3);
      expect(m.questionCount, 6);
      expect(m.perQuestionSeconds, 30);
      expect(m.allPlayers, hasLength(6));
      expect(m.allPlayers.first.team, 'A');
      expect(m.allPlayers.last.team, 'B');
      expect(m.meUid, 'u1');
      expect(m.currentUserId, 1);
      expect(m.startedAt, DateTime.parse('2026-11-27T10:00:00Z'));
    });

    test('a match with no questions is never valid', () {
      final raw = canonicalPayload()..remove('questions');
      expect(
        () => BattlePayload.parse(raw),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('legacy create payload is tolerated through firebase_battle_id', () {
      final m = BattlePayload.parse({
        'action': 'created',
        'battle_id': 42,
        'firebase_battle_id': 'fb-legacy',
        'firebase_token': 'legacy-token',
        'questions': [
          {'id': 7, 'text': 'Legacy question', 'options': [{'id': '1', 'text': 'A'}]},
        ],
      });

      expect(m.id, 'fb-legacy');
      expect(m.rtdbId, 'fb-legacy');
      expect(m.firebaseToken, 'legacy-token');
      expect(m.status, 'waiting');
      expect(m.mode, '1v1');
      expect(m.perQuestionSeconds, 30);
      expect(m.questions.single.text, 'Legacy question');
    });

    test('RTDB snapshot can merge into a waiting match without questions', () {
      final base = BattlePayload.parse(canonicalPayload());
      final merged = BattlePayload.parse(
        {
          'status': 'in_progress',
          'questions': canonicalPayload()['questions'],
        },
        base: base,
        requireQuestions: false,
      );
      expect(merged.id, base.id);
      expect(merged.status, 'in_progress');
      expect(merged.allPlayers, hasLength(6));
      expect(merged.firebaseToken, base.firebaseToken);
    });
  });

  group('started_at conversion', () {
    test('ISO-8601 is read verbatim', () {
      expect(
        BattlePayload.startedAt('2026-11-27T10:00:00+00:00'),
        DateTime.parse('2026-11-27T10:00:00Z'),
      );
    });

    test('unix seconds are not mistaken for milliseconds', () {
      const seconds = 1764237600;
      expect(
        BattlePayload.startedAt(seconds),
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      );
      expect(
        BattlePayload.startedAt('$seconds'),
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      );
    });

    test('millisecond magnitudes stay milliseconds', () {
      const ms = 1764237600000;
      expect(
        BattlePayload.startedAt(ms),
        DateTime.fromMillisecondsSinceEpoch(ms),
      );
    });
  });

  group('terminal status and winner', () {
    test('both terminal spellings end the battle', () {
      expect(BattlePayload.isTerminal('finished'), isTrue);
      expect(BattlePayload.isTerminal('completed'), isTrue);
      expect(BattlePayload.isTerminal('in_progress'), isFalse);
    });

    test('winner is read from a uid, an id or a map', () {
      expect(BattlePayload.winnerUid('u2'), 'u2');
      expect(BattlePayload.winnerUid(2), '2');
      expect(BattlePayload.winnerUid({'uid': 'u3', 'id': 3}), 'u3');
      expect(BattlePayload.winnerUid(null), isNull);
    });
  });

  group('repository', () {
    test('mode is forwarded to create and token is refreshed when absent', () async {
      final remote = _MockRemote();
      when(
        () => remote.findMatch(
          categoryId: any(named: 'categoryId'),
          totalQuestions: any(named: 'totalQuestions'),
          mode: any(named: 'mode'),
        ),
      ).thenAnswer((_) async => canonicalPayload(token: null, mode: '2v2'));
      Future<Map<String, dynamic>> refreshed(Object? _) async =>
          {'firebase_token': 'refreshed-token'};
      when(remote.getFirebaseToken).thenAnswer(refreshed);

      final repo = BattleRepositoryImpl(remote);
      final m = await repo.findMatch(mode: '2v2', totalQuestions: 12);

      final captured = verify(
        () => remote.findMatch(
          categoryId: any(named: 'categoryId'),
          totalQuestions: any(named: 'totalQuestions'),
          mode: captureAny(named: 'mode'),
        ),
      ).captured.single as String;
      expect(captured, '2v2');
      expect(m.mode, '2v2');
      // The server's published total wins over the requested queue size.
      expect(m.questionCount, 6);
      expect(m.firebaseToken, 'refreshed-token');
      verify(remote.getFirebaseToken).called(1);
    });

    test('a fresh create token is never overwritten by the token endpoint', () async {
      final remote = _MockRemote();
      when(
        () => remote.findMatch(
          categoryId: any(named: 'categoryId'),
          totalQuestions: any(named: 'totalQuestions'),
          mode: any(named: 'mode'),
        ),
      ).thenAnswer((_) async => canonicalPayload());
      final repo = BattleRepositoryImpl(remote);

      final m = await repo.findMatch(mode: '3v3');

      expect(m.firebaseToken, 'fresh-token');
      verifyNever(remote.getFirebaseToken);
    });

    test('join returns the canonical payload and its fresh token', () async {
      final remote = _MockRemote();
      when(() => remote.join('fb-1')).thenAnswer((_) async => canonicalPayload());
      final m = await BattleRepositoryImpl(remote).joinBattle('fb-1');
      expect(m.firebaseToken, 'fresh-token');
      expect(m.allPlayers, hasLength(6));
    });
  });

  group('remote data source', () {
    test('sends the selected mode in the create body', () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/quiz/battles'),
          statusCode: 200,
          data: {'success': true, 'data': canonicalPayload()},
        ),
      );

      await BattleRemoteDataSource(dio).findMatch(
        categoryId: 5,
        totalQuestions: 10,
        mode: '3v3',
      );

      final body = verify(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured.first as Map<String, dynamic>;
      expect(body['mode'], '3v3');
      expect(body['category_id'], 5);
      expect(body['total_questions'], 10);
    });
  });
}

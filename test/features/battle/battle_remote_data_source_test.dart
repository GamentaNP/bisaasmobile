import 'package:bisaasmobile/features/battle/data/datasources/battle_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

/// The battle surface could not be completed: `create` and `answer` were wired
/// but `join`, `end`, `results` and `history` were not, so the result screen had
/// to invent the outcome.
///
/// These pin the exact verbs. The server registers the §4.3 state transitions
/// canonically as PUT and keeps the POST forms only as `*.transition-alias`
/// until a freeze, so drifting back to POST would break on freeze day.
void main() {
  late _MockDio dio;
  late BattleRemoteDataSource src;

  Response<Map<String, dynamic>> body(Object? data) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
        data: <String, dynamic>{'success': true, 'data': data},
      );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    dio = _MockDio();
    src = BattleRemoteDataSource(dio);
  });

  test('join uses PUT .../participation with no body', () async {
    when(() => dio.put<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body({'firebase_battle_id': 'fb-1', 'firebase_token': 't'}),
    );

    final res = await src.join('fb-1');

    verify(() => dio.put<Map<String, dynamic>>('/quiz/battles/fb-1/participation')).called(1);
    expect(res['firebase_token'], 't');
  });

  test('end uses PUT .../completion with no body', () async {
    when(() => dio.put<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body({'status': 'completed'}),
    );

    await src.end('fb-1');

    verify(() => dio.put<Map<String, dynamic>>('/quiz/battles/fb-1/completion')).called(1);
  });

  test('results is a GET', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body({
            'battle': {'winner_id': 1, 'status': 'completed'},
          }),
    );

    final res = await src.getResults('fb-1');

    verify(() => dio.get<Map<String, dynamic>>('/quiz/battles/fb-1/results')).called(1);
    expect(res['battle'], isNotNull);
  });

  test('history is a GET on the collection', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body({'items': <dynamic>[], 'stats': <String, dynamic>{}}),
    );

    final res = await src.getHistory();

    verify(() => dio.get<Map<String, dynamic>>('/quiz/battles/history')).called(1);
    expect(res['items'], isNotNull);
  });

  test('none of the four use a POST alias', () async {
    when(() => dio.get<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => body(const <String, dynamic>{}));
    when(() => dio.put<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => body(const <String, dynamic>{}));

    await src.join('fb-1');
    await src.end('fb-1');
    await src.getResults('fb-1');
    await src.getHistory();

    verifyNever(() => dio.post<Map<String, dynamic>>(any()));
  });

  test('a 403 on end propagates rather than looking like success', () async {
    // The server refuses `end` for anyone but the host.
    when(() => dio.put<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/quiz/battles/fb-1/completion'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/quiz/battles/fb-1/completion'),
          statusCode: 403,
        ),
      ),
    );

    await expectLater(src.end('fb-1'), throwsA(isA<DioException>()));
  });

  test('a 404 on join propagates — the lobby filling is a real outcome', () async {
    when(() => dio.put<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/quiz/battles/fb-1/participation'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/quiz/battles/fb-1/participation'),
          statusCode: 404,
        ),
      ),
    );

    await expectLater(src.join('fb-1'), throwsA(isA<DioException>()));
  });
}

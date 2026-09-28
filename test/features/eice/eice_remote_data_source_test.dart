import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

/// The study-planner routes are `->whereNumber('exam')`.
///
/// The client used to call `study-planner/{exam}/coach` with the literal string
/// 'psc-civil', which never matched a route and so 404'd at the routing layer on
/// every call. Confirmed against the running backend:
///   GET /quiz/coach                    -> 401  (route resolves)
///   GET /quiz/study-planner/1/coach    -> 401  (numeric id resolves)
///   GET /quiz/study-planner/psc-civil/coach -> 404  (no such route)
///
/// These tests pin the request paths so that shape cannot regress silently.
void main() {
  late _MockDio dio;
  late EiceRemoteDataSource src;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    dio = _MockDio();
    src = EiceRemoteDataSource(dio);
  });

  Response<Map<String, dynamic>> body(Object? data) => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
        data: <String, dynamic>{'success': true, 'data': data},
      );

  test('getCoach takes NO exam segment', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => body({'exam_id': 7}));

    final res = await src.getCoach();

    verify(() => dio.get<Map<String, dynamic>>('/quiz/coach')).called(1);
    expect(res?['exam_id'], 7);
  });

  test('getTriage sends the numeric exam id, not a slug', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => body({'mode': 'cover'}));

    await src.getTriage(42);

    verify(() => dio.get<Map<String, dynamic>>('/quiz/study-planner/42/triage')).called(1);
  });

  test('sprint and weekly use their top-level routes', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => body(<String, dynamic>{}));

    await src.getSprint();
    await src.getWeekly();

    verify(() => dio.get<Map<String, dynamic>>('/quiz/sprint')).called(1);
    verify(() => dio.get<Map<String, dynamic>>('/quiz/reports/weekly')).called(1);
  });

  test('getSprint unwraps an items list', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body({
            'items': [
              {'question_id': 1},
            ],
          }),
    );

    final items = await src.getSprint();
    expect(items, hasLength(1));
  });

  test('getSprint tolerates a bare list payload', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => body([
            {'question_id': 9},
          ]),
    );
    expect(await src.getSprint(), hasLength(1));
  });

  test('a failure propagates rather than looking like an empty account', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/quiz/coach'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/quiz/coach'),
          statusCode: 404,
        ),
      ),
    );

    // Before this data source stopped swallowing, this returned null and the UI
    // rendered "no study plan" for a dead endpoint.
    await expectLater(src.getCoach(), throwsA(isA<DioException>()));
  });
}

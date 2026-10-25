/// Cross-layer tests for the search and PSC contracts — the two data
/// sources that used to be called straight off the presentation side.
///
/// Routes (API guide):
///   * `GET /api/v1/quiz/questions?search=…`  (cursor-shaped route — the
///     client must NOT send `page`; `per_page` only sizes the page)
///   * `GET /api/v1/psc/blueprints`
///   * `POST /api/v1/psc/blueprints/{id}/exam`
///   * `PUT  /api/v1/psc/blueprints/{id}/submission`
///
/// The regressions pinned here:
///   * search accepts both documented payload shapes (`data` as a list, and
///     `data.questions` as a list) and refuses everything else — a shape
///     drift must surface as `ContractViolation`, not as an empty result;
///   * PSC failures propagate instead of collapsing into "no blueprints",
///     which used to make an outage indistinguishable from an empty server.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/psc/data/psc_remote_data_source.dart';
import 'package:bisaasmobile/features/search/data/search_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _question({int id = 1}) => <String, dynamic>{
      'id': id,
      'question': 'The degree of static indeterminacy of a rigid jointed '
          'plane frame is…',
      'subject': 'structural',
    };

void main() {
  group('the search contract (GET /quiz/questions?search=…)', () {
    test('sends the query and the page size, and reads `data` as a list',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      // `data` is the list itself for this endpoint:
      api.routes['GET /quiz/questions'] = FakeRoute(
        200,
        <String, dynamic>{
          'success': true,
          'data': [_question()],
          'message': 'ok',
          'timestamp': '2026-10-25T00:00:00+00:00',
          'api_version': 'v1',
        },
      );

      final source = SearchRemoteDataSource(dioFor(api));
      final rows = await source.searchQuestions('bending moment');

      expect(rows, hasLength(1));
      expect(rows.single['id'], 1);
      expect(api.queryOf(0)['search'], 'bending moment');
      expect(api.queryOf(0)['per_page'], 10);
      // Cursor-shaped route: sending `page` is deprecated on the server.
      expect(api.queryOf(0).containsKey('page'), isFalse);
    });

    test('reads the alternate documented shape `data.questions`', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.routes['GET /quiz/questions'] = FakeRoute(
        200,
        <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'questions': [_question(id: 2), _question(id: 3)],
          },
          'message': 'ok',
          'timestamp': '2026-10-25T00:00:00+00:00',
          'api_version': 'v1',
        },
      );

      final source = SearchRemoteDataSource(dioFor(api));
      final rows = await source.searchQuestions('fluid');

      expect(rows, hasLength(2));
      expect(rows.first['id'], 2);
    });

    test('an unrecognised 2xx shape is ContractViolation, not an empty list',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.routes['GET /quiz/questions'] = FakeRoute.raw(
        <String, dynamic>{'success': true, 'data': <String, dynamic>{},
         'message': 'ok', 'timestamp': 'x', 'api_version': 'v1'},
      );

      final source = SearchRemoteDataSource(dioFor(api));

      await expectLater(
        source.searchQuestions('soil'),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('a 500 propagates as a Dio error the controller can render a retry',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'GET',
        '/quiz/questions',
        FakeRoute.error(500, 'SERVER_ERROR', 'boom'),
      );

      final source = SearchRemoteDataSource(dioFor(api));

      await expectLater(
        source.searchQuestions('soil'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            500,
          ),
        ),
      );
    });
  });

  group('the PSC blueprint contract', () {
    test('GET /psc/blueprints reads `data` as a list', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.routes['GET /psc/blueprints'] = FakeRoute(
        200,
        <String, dynamic>{
          'success': true,
          'data': [
            {'id': 11, 'name': 'Loksewa Section Officer — Paper II'},
          ],
          'message': 'ok',
          'timestamp': '2026-10-25T00:00:00+00:00',
          'api_version': 'v1',
        },
      );

      final source = PscRemoteDataSource(dioFor(api));
      final rows = await source.getBlueprints();

      expect(rows, hasLength(1));
      expect(rows.single['id'], 11);
    });

    test('an outage propagates — it must not read as "no blueprints"',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'GET',
        '/psc/blueprints',
        FakeRoute.error(503, 'MAINTENANCE', 'down for maintenance'),
      );

      final source = PscRemoteDataSource(dioFor(api));

      await expectLater(
        source.getBlueprints(),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );
    });

    test('startExam posts to the blueprint exam route and returns its data',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/psc/blueprints/11/exam',
        FakeRoute.ok(<String, dynamic>{
          'exam_id': 42,
          'started_at': '2026-10-25T10:00:00+00:00',
        }),
      );

      final source = PscRemoteDataSource(dioFor(api));
      final exam = await source.startExam('11');

      expect(exam?['exam_id'], 42);
      expect(api.indexOfRequest('POST', '/psc/blueprints/11/exam'), 0);
    });

    test('submit PUTs the canonical submission route with the payload',
        () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'PUT',
        '/psc/blueprints/11/submission',
        FakeRoute.ok(<String, dynamic>{'score': 8}),
      );

      final source = PscRemoteDataSource(dioFor(api));
      final result = await source.submit('11', <String, dynamic>{
        'answers': {'1': 'b'},
      });

      expect(result?['score'], 8);
      expect(api.indexOfRequest('PUT', '/psc/blueprints/11/submission'), 0);
      expect(api.jsonBodyOf(0)['answers'], <String, dynamic>{'1': 'b'});
    });
  });
}

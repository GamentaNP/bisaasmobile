/// Cross-layer coverage for the four EICE routes the audit found published
/// but unused (§2.3). Real Dio + interceptors + envelope + datasource, with a
/// scripted transport: the request path and the response shape both matter.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late FakeApi api;
  late EiceRemoteDataSource source;

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    source = EiceRemoteDataSource(dioFor(api));
  });

  test('study planner sends a numeric exam id', () async {
    api.on(
      'GET',
      '/quiz/study-planner/7',
      FakeRoute.ok(<String, dynamic>{'mode': 'normal'}),
    );

    final plan = await source.getStudyPlan(7);

    expect(plan?['mode'], 'normal');
    expect(api.requests.single.path, '/quiz/study-planner/7');
  });

  test('topic and course patterns use the numeric segments', () async {
    api.on(
      'GET',
      '/quiz/topics/12/pattern',
      FakeRoute.ok(<String, dynamic>{'topic_id': 12, 'has_data': true}),
    );
    api.on(
      'GET',
      '/quiz/courses/3/patterns',
      FakeRoute.ok(<String, dynamic>{
        'course_id': 3,
        'topics': [
          {'topic_id': 12},
        ],
      }),
    );

    expect((await source.getTopicPattern(12))?['has_data'], isTrue);
    expect((await source.getCoursePatterns(3))?['course_id'], 3);
    expect(api.requests.map((r) => r.path), [
      '/quiz/topics/12/pattern',
      '/quiz/courses/3/patterns',
    ]);
  });

  test('weekly history accepts the bare list and keeps every row', () async {
    api.on(
      'GET',
      '/quiz/reports/weekly/history',
      FakeRoute.envelope(<String, dynamic>{
        'success': true,
        'data': <dynamic>[
          <String, dynamic>{'report_id': 1},
          <String, dynamic>{'report_id': 2},
        ],
        'message': 'Report history retrieved',
        'api_version': 'v1',
      }),
    );

    final history = await source.getWeeklyHistory();

    expect(history.map((r) => r['report_id']), [1, 2]);
    expect(api.requests.single.path, '/quiz/reports/weekly/history');
  });

  test('a drifted history payload throws instead of pretending there are no reports', () async {
    api.on(
      'GET',
      '/quiz/reports/weekly/history',
      FakeRoute.ok(<String, dynamic>{'items': <dynamic>[]}),
    );

    await expectLater(
      source.getWeeklyHistory(),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('a server error is not converted into an empty history', () async {
    api.on(
      'GET',
      '/quiz/reports/weekly/history',
      FakeRoute.error(404, 'NOT_FOUND', 'No reports'),
    );

    await expectLater(
      source.getWeeklyHistory(),
      throwsA(isA<Exception>()),
    );
  });
}

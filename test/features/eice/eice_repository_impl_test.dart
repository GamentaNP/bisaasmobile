/// The repository used to expose only coach/triage/sprint/weekly, so the four
/// server-published EICE routes were unreachable from presentation. These
/// tests pin that the new methods map raw payloads to domain handles without
/// swallowing a failure as "no data".
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/eice/data/repositories/eice_repository_impl.dart';
import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EiceRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EiceRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = EiceRepositoryImpl(remote);
  });

  test('combined plan maps to a payload without re-shaping it', () async {
    when(() => remote.getCombinedStudyPlan()).thenAnswer(
      (_) async => {'combined_daily_plan': <Map<String, dynamic>>[]},
    );

    final payload = await repository.getCombinedStudyPlan();

    expect(payload?.raw['combined_daily_plan'], isA<List<Map<String, dynamic>>>());
  });

  test('readiness verdict maps to a payload without re-shaping it', () async {
    when(() => remote.getReadiness(12)).thenAnswer(
      (_) async => {'verdict': 'ready', 'readiness_percent': 91},
    );

    final payload = await repository.getReadiness(12);

    expect(payload?.readinessVerdict, 'ready');
    expect(payload?.readinessPercent, 91);
  });

  test('plan, topic pattern and course patterns map to payloads', () async {
    when(() => remote.getStudyPlan(7)).thenAnswer((_) async => {'mode': 'sprint'});
    when(() => remote.getTopicPattern(12)).thenAnswer((_) async => {'topic_id': 12});
    when(() => remote.getCoursePatterns(3)).thenAnswer((_) async => {'course_id': 3});

    final plan = await repository.getStudyPlan(7);
    final topic = await repository.getTopicPattern(12);
    final course = await repository.getCoursePatterns(3);

    expect(plan?.raw['mode'], 'sprint');
    expect(topic?.raw['topic_id'], 12);
    expect(course?.raw['course_id'], 3);
  });

  test('weekly history maps the bare list without losing rows', () async {
    when(() => remote.getWeeklyHistory()).thenAnswer(
      (_) async => [
        {'report_id': 1},
        {'report_id': 2},
      ],
    );

    final history = await repository.getWeeklyHistory();

    expect(history.map((p) => p.raw['report_id']), [1, 2]);
  });

  test('a data-source failure propagates through the repository', () async {
    when(() => remote.getWeeklyHistory()).thenThrow(
      const ContractViolation('Expected `data` to be an array'),
    );

    await expectLater(
      repository.getWeeklyHistory(),
      throwsA(isA<ContractViolation>()),
    );
  });
}

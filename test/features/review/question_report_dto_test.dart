import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/review/data/models/question_report_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _wire({bool duplicate = false}) => <String, dynamic>{
  'duplicate': duplicate,
  'canonical_report_id': 91,
  'report': <String, dynamic>{
    'id': 91,
    'status': 'pending',
    'category': 'incorrect_answer',
    'duplicate_count': duplicate ? 1 : 0,
  },
};

void main() {
  test('a documented report response becomes a domain result', () {
    final result = QuestionReportResultDto.fromJson(_wire()).toDomain();

    expect(result.reportId, 91);
    expect(result.canonicalReportId, 91);
    expect(result.status, 'pending');
    expect(result.category, 'incorrect_answer');
    expect(result.duplicate, isFalse);
    expect(result.duplicateCount, 0);
  });

  test('a duplicate reply keeps the canonical id returned by the server', () {
    final wire = _wire(duplicate: true)
      ..['report'] = <String, dynamic>{
        'id': 92,
        'status': 'pending',
        'category': 'outdated',
        'duplicate_count': 2,
      };
    final result = QuestionReportResultDto.fromJson(wire).toDomain();

    expect(result.duplicate, isTrue);
    expect(result.canonicalReportId, 91);
    expect(result.reportId, 92);
    expect(result.duplicateCount, 2);
  });

  test('a 2xx body that is not a report response is contract drift', () {
    for (final broken in <Map<String, dynamic>>[
      <String, dynamic>{'unexpected': true},
      <String, dynamic>{..._wire(), 'report': null},
      <String, dynamic>{
        ..._wire(),
        'canonical_report_id': null,
      },
      <String, dynamic>{
        ..._wire(),
        'duplicate': 'yes',
      },
    ]) {
      expect(
        () => QuestionReportResultDto.fromJson(broken),
        throwsA(isA<ContractViolation>()),
      );
    }
  });
}

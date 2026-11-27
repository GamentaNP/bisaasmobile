import '../../../../core/network/api_failure.dart';
import '../../domain/entities/question_report.dart';

/// Wire DTO for `POST /quiz/questions/{question}/reports`.
///
/// The reply is `{duplicate, canonical_report_id, report:{id, status,
/// category, duplicate_count}}` inside the canonical envelope. A 2xx body
/// that does not carry it is contract drift, not a successful report: the
/// caller must not show "sent" for a response it could not read.
class QuestionReportResultDto {
  const QuestionReportResultDto({
    required this.reportId,
    required this.status,
    required this.category,
    required this.duplicate,
    required this.canonicalReportId,
    required this.duplicateCount,
  });

  factory QuestionReportResultDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/questions/{question}/reports',
  }) {
    final report = j['report'];
    if (report is! Map<String, dynamic>) {
      throw ContractViolation(
        'A report response has no report object',
        endpoint: endpoint,
      );
    }
    final reportId = _intOf(report['id']);
    if (reportId == null) {
      throw ContractViolation(
        'A report response has no report id',
        endpoint: endpoint,
      );
    }
    final canonicalReportId = _intOf(j['canonical_report_id']);
    if (canonicalReportId == null) {
      throw ContractViolation(
        'A report response has no canonical_report_id',
        endpoint: endpoint,
      );
    }
    final status = report['status'];
    if (status is! String || status.isEmpty) {
      throw ContractViolation(
        'A report response has no status',
        endpoint: endpoint,
      );
    }
    final category = report['category'];
    if (category is! String || category.isEmpty) {
      throw ContractViolation(
        'A report response has no category',
        endpoint: endpoint,
      );
    }
    final duplicate = j['duplicate'];
    if (duplicate is! bool) {
      throw ContractViolation(
        'A report response has no duplicate flag',
        endpoint: endpoint,
      );
    }
    return QuestionReportResultDto(
      reportId: reportId,
      status: status,
      category: category,
      duplicate: duplicate,
      canonicalReportId: canonicalReportId,
      duplicateCount: _intOf(report['duplicate_count']) ?? 0,
    );
  }

  static int? _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  final int reportId;
  final String status;
  final String category;
  final bool duplicate;
  final int canonicalReportId;
  final int duplicateCount;

  QuestionReportResult toDomain() => QuestionReportResult(
    reportId: reportId,
    status: status,
    category: category,
    duplicate: duplicate,
    canonicalReportId: canonicalReportId,
    duplicateCount: duplicateCount,
  );
}

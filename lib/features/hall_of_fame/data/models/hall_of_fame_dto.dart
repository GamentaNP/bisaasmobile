import '../../../../core/network/api_failure.dart';
import '../../domain/entities/hall_of_fame.dart';

/// Wire DTO for the composed Hall of Fame snapshot.
///
/// A missing or wrongly typed section is contract drift. An empty `records`
/// list is the only shape allowed to produce an empty screen — a failure can
/// never be disguised as "no records".
abstract final class _Parse {
  static Map<String, dynamic> requireMap(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> requireList(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value is List) return value.whereType<Map<String, dynamic>>().toList();
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static int intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? dateOf(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String requireString(Object? value, String key, {required String endpoint}) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A hall of fame record has no $key', endpoint: endpoint);
    }
    return text;
  }
}

class HallOfFameDto {
  const HallOfFameDto({
    required this.filters,
    required this.summary,
    required this.featuredRecords,
    required this.records,
    required this.recordTypeOptions,
    required this.periodOptions,
  });

  factory HallOfFameDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/hall-of-fame',
  }) {
    final filters = _Parse.requireMap(j['filters'], endpoint: endpoint, key: 'filters');
    final summary = _Parse.requireMap(j['summary'], endpoint: endpoint, key: 'summary');
    return HallOfFameDto(
      filters: HallOfFameFilters(
        recordType: (filters['record_type'] ?? 'all').toString(),
        period: (filters['period'] ?? 'all_time').toString(),
        search: filters['search'] as String?,
      ),
      summary: HallOfFameSummary(
        recordCount: _Parse.intOf(summary['record_count']),
        hallOfFamers: _Parse.intOf(summary['hall_of_famers']),
        featuredCount: _Parse.intOf(summary['featured_count']),
        latestRecordAt: _Parse.dateOf(summary['latest_record_at']),
      ),
      featuredRecords: _Parse.requireList(
        j['featured_records'], endpoint: endpoint, key: 'featured_records',
      ).map((r) => _record(r, endpoint)).toList(),
      records: _Parse.requireList(
        j['records'], endpoint: endpoint, key: 'records',
      ).map((r) => _record(r, endpoint)).toList(),
      recordTypeOptions: _Parse.requireList(
        j['record_type_options'], endpoint: endpoint, key: 'record_type_options',
      ).map(_option).toList(),
      periodOptions: _Parse.requireList(
        j['period_options'], endpoint: endpoint, key: 'period_options',
      ).map(_option).toList(),
    );
  }

  final HallOfFameFilters filters;
  final HallOfFameSummary summary;
  final List<HallOfFameRecord> featuredRecords;
  final List<HallOfFameRecord> records;
  final List<HallOfFameOption> recordTypeOptions;
  final List<HallOfFameOption> periodOptions;

  static HallOfFameOption _option(Map<String, dynamic> j) => HallOfFameOption(
        value: (j['value'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        description: j['description'] as String?,
      );

  static HallOfFameRecord _record(Map<String, dynamic> j, String endpoint) =>
      HallOfFameRecord(
        id: _Parse.requireString(j['id'], 'id', endpoint: endpoint),
        recordKey: (j['record_key'] ?? '').toString(),
        recordType: (j['record_type'] ?? '').toString(),
        metric: (j['metric'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        valueLabel: (j['value_label'] ?? '').toString(),
        scopeLabel: j['scope_label'] as String?,
        name: j['name'] as String?,
        username: j['username'] as String?,
        description: j['description'] as String?,
        achievedAt: _Parse.dateOf(j['achieved_at']),
        isCurrentUser: j['is_current_user'] == true,
        isFeatured: j['is_featured'] == true,
        certificateStatus: j['certificate_status'] as String?,
        historyCount: _Parse.intOf(j['history_count']),
        history: (j['history'] is List
                ? (j['history'] as List).whereType<Map<String, dynamic>>()
                : const <Map<String, dynamic>>[])
            .map((h) => HallOfFameHistoryEntry(
                  name: (h['name'] ?? '').toString(),
                  valueLabel: (h['value_label'] ?? '').toString(),
                  username: h['username'] as String?,
                  achievedAt: _Parse.dateOf(h['achieved_at']),
                ))
            .toList(),
      );

  HallOfFameSnapshot toDomain() => HallOfFameSnapshot(
        filters: filters,
        summary: summary,
        featuredRecords: featuredRecords,
        records: records,
        recordTypeOptions: recordTypeOptions,
        periodOptions: periodOptions,
      );
}

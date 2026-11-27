/// Pure Dart models for the composed `GET /quiz/hall-of-fame` snapshot.
///
/// This endpoint is a bounded top-100 snapshot with no cursor — never walk it.
/// The server publishes the filter values, summary counts, featured records
/// and option lists in one object; nothing here is recomputed locally.
library;

class HallOfFameOption {
  const HallOfFameOption({
    required this.value,
    required this.label,
    this.description,
  });

  final String value;
  final String label;
  final String? description;
}

class HallOfFameHistoryEntry {
  const HallOfFameHistoryEntry({
    required this.name,
    required this.valueLabel,
    this.username,
    this.achievedAt,
  });

  final String name;
  final String valueLabel;
  final String? username;
  final DateTime? achievedAt;
}

class HallOfFameRecord {
  const HallOfFameRecord({
    required this.id,
    required this.recordKey,
    required this.recordType,
    required this.metric,
    required this.title,
    required this.valueLabel,
    this.scopeLabel,
    this.name,
    this.username,
    this.description,
    this.achievedAt,
    this.isCurrentUser = false,
    this.isFeatured = false,
    this.certificateStatus,
    this.historyCount = 0,
    this.history = const <HallOfFameHistoryEntry>[],
  });

  final String id;
  final String recordKey;
  final String recordType;
  final String metric;
  final String title;
  final String valueLabel;
  final String? scopeLabel;
  final String? name;
  final String? username;
  final String? description;
  final DateTime? achievedAt;
  final bool isCurrentUser;
  final bool isFeatured;
  final String? certificateStatus;
  final int historyCount;
  final List<HallOfFameHistoryEntry> history;
}

class HallOfFameFilters {
  const HallOfFameFilters({
    required this.recordType,
    required this.period,
    this.search,
  });

  final String recordType;
  final String period;
  final String? search;
}

class HallOfFameSummary {
  const HallOfFameSummary({
    this.recordCount = 0,
    this.hallOfFamers = 0,
    this.featuredCount = 0,
    this.latestRecordAt,
  });

  final int recordCount;
  final int hallOfFamers;
  final int featuredCount;
  final DateTime? latestRecordAt;
}

class HallOfFameSnapshot {
  const HallOfFameSnapshot({
    required this.filters,
    required this.summary,
    required this.featuredRecords,
    required this.records,
    required this.recordTypeOptions,
    required this.periodOptions,
  });

  final HallOfFameFilters filters;
  final HallOfFameSummary summary;
  final List<HallOfFameRecord> featuredRecords;
  final List<HallOfFameRecord> records;
  final List<HallOfFameOption> recordTypeOptions;
  final List<HallOfFameOption> periodOptions;
}

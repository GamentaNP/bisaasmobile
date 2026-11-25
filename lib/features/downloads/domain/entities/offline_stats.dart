/// Local snapshot of the offline question cache.
///
/// Derived only from rows the app actually stored in Drift - never from a
/// network guess. A failure to read the cache throws; it is not reported as
/// "0 questions cached", which would look like a fresh install.
library;

class OfflineStats {
  const OfflineStats({
    required this.questions,
    required this.subjects,
    required this.approxKb,
    this.lastCached,
  });

  static const empty = OfflineStats(questions: 0, subjects: 0, approxKb: 0);

  final int questions;
  final int subjects;
  final int approxKb;
  final DateTime? lastCached;
}

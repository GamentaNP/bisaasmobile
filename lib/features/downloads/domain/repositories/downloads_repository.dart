import '../entities/offline_stats.dart';

/// Offline content manager.
///
/// There is no remote data source here: the figures come from the same Drift
/// table the daily prefetcher warms, and the prefetch itself is Dio-backed at
/// the composition seam. Reads and writes stay behind this interface so the
/// screen does not reach into the database or the prefetcher directly.
abstract class DownloadsRepository {
  Future<OfflineStats> getStats();
  Future<bool> prefetchOnce();
  Future<void> clear();
}

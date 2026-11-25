import '../../../../core/storage/database/daos/quiz_dao.dart';
import '../../../../core/sync/daily_quiz_prefetcher.dart';
import '../../domain/entities/offline_stats.dart';
import '../../domain/repositories/downloads_repository.dart';

/// Wraps the existing local cache (Drift) and the Dio-backed prefetcher.
///
/// The computation is the one the screen used before, moved verbatim behind
/// the repository boundary: a Drift read error still propagates to the UI's
/// error state instead of reading as an empty cache.
class DownloadsRepositoryImpl implements DownloadsRepository {
  const DownloadsRepositoryImpl(this._dao, this._prefetcher);

  final QuizDao _dao;
  final DailyQuizPrefetcher _prefetcher;

  @override
  Future<OfflineStats> getStats() async {
    final rows = await _dao.all();
    if (rows.isEmpty) return OfflineStats.empty;
    final subjects = rows.map((r) => r.subjectSlug).where((s) => s.isNotEmpty).toSet();
    final bytes = rows.fold<int>(0, (sum, r) => sum + r.body.length + r.optionsJson.length);
    final newest = rows
        .map((r) => r.cachedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return OfflineStats(
      questions: rows.length,
      subjects: subjects.length,
      approxKb: (bytes / 1024).ceil(),
      lastCached: newest,
    );
  }

  @override
  Future<bool> prefetchOnce() => _prefetcher.prefetchOnce();

  @override
  Future<void> clear() => _dao.clear();
}

/// The cache contract the daily prefetcher needs. Declared in `core` so the
/// prefetcher does not depend on a feature's data layer; the quiz feature
/// implements it with its Drift-backed data source.
// ignore_for_file: one_member_abstracts
abstract class DailyPackCache {
  Future<void> cacheDailyPack({
    required String quizId,
    required List<Map<String, dynamic>> questions,
    String subjectSlug = 'daily',
  });
}

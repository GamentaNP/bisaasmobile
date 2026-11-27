import '../entities/past_paper.dart';

/// Read boundary for the past-paper catalog and its detail view.
abstract class PastPapersRepository {
  Future<PastPaperCatalogPage> getPapers({
    String? search,
    String? country,
    String? province,
    String? year,
    String? paper,
    String? cursor,
    int perPage,
  });

  Future<PastPaperDetail> getPaper(int paperId);
}

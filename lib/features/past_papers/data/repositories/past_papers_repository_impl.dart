import '../../domain/entities/past_paper.dart';
import '../../domain/repositories/past_papers_repository.dart';
import '../datasources/past_papers_remote_data_source.dart';

class PastPapersRepositoryImpl implements PastPapersRepository {
  const PastPapersRepositoryImpl(this._remote);

  final PastPapersRemoteDataSource _remote;

  @override
  Future<PastPaperCatalogPage> getPapers({
    String? search,
    String? country,
    String? province,
    String? year,
    String? paper,
    String? cursor,
    int perPage = 25,
  }) =>
      _remote.getPapers(
        search: search,
        country: country,
        province: province,
        year: year,
        paper: paper,
        cursor: cursor,
        perPage: perPage,
      );

  @override
  Future<PastPaperDetail> getPaper(int paperId) => _remote.getPaper(paperId);
}

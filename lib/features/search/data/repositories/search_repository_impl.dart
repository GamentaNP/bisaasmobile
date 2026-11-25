import '../../domain/entities/search_hit.dart';
import '../../domain/repositories/search_repository.dart';
import '../search_remote_data_source.dart';

/// Thin repository over the existing search data source.
///
/// The data source still owns the two accepted `data` shapes and still throws
/// a `ContractViolation` for anything else - no parsing is redone here.
class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<List<SearchHit>> searchQuestions(String query) async {
    final rows = await _remote.searchQuestions(query);
    return rows.map(SearchHit.new).toList(growable: false);
  }
}

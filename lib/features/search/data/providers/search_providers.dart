import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/search_hit.dart';
import '../../domain/repositories/search_repository.dart';
import '../repositories/search_repository_impl.dart';
import '../search_remote_data_source.dart';

/// The Dio seam for this feature: one data source, built from the app's Dio,
/// then wrapped by the repository the screen watches.
final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource(ref.watch(dioProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider));
});

/// One page of hits for a query. An empty query never hits the network.
final searchResultsProvider =
    FutureProvider.family<List<SearchHit>, String>((ref, query) async {
  if (query.trim().isEmpty) return const <SearchHit>[];
  return ref.watch(searchRepositoryProvider).searchQuestions(query);
});

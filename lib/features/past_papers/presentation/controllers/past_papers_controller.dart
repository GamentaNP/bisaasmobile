/// Providers for the past-paper catalog and detail reads.
///
/// Filters are part of the family key so a change re-fetches page one. Cursor
/// continuation is NOT a provider key: the screen rounds-trips `next_cursor`
/// explicitly, because walking a cursor is stateful across taps.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/past_papers_remote_data_source.dart';
import '../../data/repositories/past_papers_repository_impl.dart';
import '../../domain/entities/past_paper.dart';
import '../../domain/repositories/past_papers_repository.dart';

typedef PastPaperQuery = ({
  String? search,
  String? country,
  String? province,
  String? year,
  String? paper,
});

final pastPapersRemoteDataSourceProvider = Provider<PastPapersRemoteDataSource>((ref) {
  return PastPapersRemoteDataSource(ref.watch(dioProvider));
});

final pastPapersRepositoryProvider = Provider<PastPapersRepository>((ref) {
  return PastPapersRepositoryImpl(ref.watch(pastPapersRemoteDataSourceProvider));
});

final pastPaperCatalogProvider =
    FutureProvider.family<PastPaperCatalogPage, PastPaperQuery>((ref, query) {
  return ref.watch(pastPapersRepositoryProvider).getPapers(
        search: query.search,
        country: query.country,
        province: query.province,
        year: query.year,
        paper: query.paper,
      );
});

final pastPaperDetailProvider = FutureProvider.family<PastPaperDetail, int>((ref, paperId) {
  return ref.watch(pastPapersRepositoryProvider).getPaper(paperId);
});

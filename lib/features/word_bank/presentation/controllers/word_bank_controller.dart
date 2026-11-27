/// Providers for the word-bank catalog.
///
/// Filter changes re-fetch page one; cursor continuation is screen state and
/// is always round-tripped verbatim from the server.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/word_bank_remote_data_source.dart';
import '../../data/repositories/word_bank_repository_impl.dart';
import '../../domain/entities/word_bank.dart';
import '../../domain/repositories/word_bank_repository.dart';

typedef WordBankQuery = ({String? search, String? difficulty, String? course});

final wordBankRemoteDataSourceProvider = Provider<WordBankRemoteDataSource>((ref) {
  return WordBankRemoteDataSource(ref.watch(dioProvider));
});

final wordBankRepositoryProvider = Provider<WordBankRepository>((ref) {
  return WordBankRepositoryImpl(ref.watch(wordBankRemoteDataSourceProvider));
});

final wordBankProvider = FutureProvider.family<WordBankCatalogPage, WordBankQuery>((ref, query) {
  return ref.watch(wordBankRepositoryProvider).getWords(
        search: query.search,
        difficulty: query.difficulty,
        course: query.course,
      );
});

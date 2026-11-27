import '../../domain/entities/word_bank.dart';
import '../../domain/repositories/word_bank_repository.dart';
import '../datasources/word_bank_remote_data_source.dart';

class WordBankRepositoryImpl implements WordBankRepository {
  const WordBankRepositoryImpl(this._remote);

  final WordBankRemoteDataSource _remote;

  @override
  Future<WordBankCatalogPage> getWords({
    String? search,
    String? difficulty,
    String? course,
    String? cursor,
    int perPage = 25,
  }) =>
      _remote.getWords(
        search: search,
        difficulty: difficulty,
        course: course,
        cursor: cursor,
        perPage: perPage,
      );
}

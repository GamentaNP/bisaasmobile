import '../entities/word_bank.dart';

/// Read boundary for the word-bank catalog.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class WordBankRepository {
  Future<WordBankCatalogPage> getWords({
    String? search,
    String? difficulty,
    String? course,
    String? cursor,
    int perPage,
  });
}

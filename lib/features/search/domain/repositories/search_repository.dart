import '../entities/search_hit.dart';

/// Global question search.
///
/// A transport or contract failure throws; a genuinely empty result set is
/// an empty list. Those two states are never conflated.
// ignore: one_member_abstracts
abstract class SearchRepository {
  Future<List<SearchHit>> searchQuestions(String query);
}

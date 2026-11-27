import '../../../../core/network/api_failure.dart';
import '../../domain/entities/word_bank.dart';

/// Wire DTO for `GET /quiz/word-bank`.
///
/// A missing `items` array or a malformed option list is drift and throws;
/// a genuinely empty `items` array is the only allowed empty result.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Object?> list(Object? value, String key, String endpoint) {
    if (value is List) return value;
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static int intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String requiredString(Object? value, String key, String endpoint) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A word bank row has no $key', endpoint: endpoint);
    }
    return text;
  }

  static String? nullableString(Object? value) => value?.toString();
}

class WordBankDto {
  const WordBankDto({required this.data});
  final Map<String, dynamic> data;

  factory WordBankDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/word-bank',
  }) {
    _Parse.list(data['items'], 'items', endpoint);
    _Parse.map(data['filters'], 'filters', endpoint);
    _Parse.list(data['all_tags'], 'all_tags', endpoint);
    _Parse.list(data['all_courses'], 'all_courses', endpoint);
    _Parse.list(data['all_difficulties'], 'all_difficulties', endpoint);
    return WordBankDto(data: data);
  }

  WordBankCatalogPage toDomain({String endpoint = '/quiz/word-bank'}) {
    final items = _Parse.list(data['items'], 'items', endpoint)
        .whereType<Map<String, dynamic>>()
        .map((j) => WordBankEntry(
              id: _Parse.intOf(j['id']),
              term: _Parse.requiredString(j['term'], 'term', endpoint),
              definition: _Parse.requiredString(j['definition'], 'definition', endpoint),
              example: _Parse.nullableString(j['example']),
              difficulty: _Parse.nullableString(j['difficulty']) ?? 'medium',
              tags: (j['tags'] is List)
                  ? (j['tags'] as List).map((t) => t.toString()).toList()
                  : const <String>[],
              courseName: _Parse.nullableString(
                  j['course'] is Map ? (j['course'] as Map)['name'] : null),
              topicName: _Parse.nullableString(
                  j['topic'] is Map ? (j['topic'] as Map)['name'] : null),
              mastery: j['mastery'] is num ? j['mastery'] as num : null,
            ))
        .toList();

    return WordBankCatalogPage(
      items: items,
      filters: _Parse.map(data['filters'], 'filters', endpoint),
      allTags: _Parse.list(data['all_tags'], 'all_tags', endpoint)
          .map((t) => t.toString())
          .toList(),
      allCourses: _Parse.list(data['all_courses'], 'all_courses', endpoint)
          .whereType<Map<String, dynamic>>()
          .map((j) => WordBankCourse(
                id: _Parse.intOf(j['id']),
                name: _Parse.requiredString(j['name'], 'name', endpoint),
                slug: _Parse.nullableString(j['slug']),
              ))
          .toList(),
      allDifficulties: _Parse.list(data['all_difficulties'], 'all_difficulties', endpoint)
          .map((d) => d.toString())
          .toList(),
    );
  }
}

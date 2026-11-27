import '../../../../core/network/api_failure.dart';
import '../../domain/entities/knowledge_atom.dart';

/// Strict wire parser for a single knowledge atom.
///
/// Every field the screen reads is type-checked. A missing `id` or a wrong
/// type on any published field is contract drift and throws — it is never
/// rendered as an empty atom.
abstract final class _Parse {
  static int intOf(Object? value, String key, String endpoint) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation('Expected $key to be an int', endpoint: endpoint);
  }

  static String? optionalString(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      'Expected $key to be a string or null',
      endpoint: endpoint,
    );
  }

  static int? optionalInt(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation(
      'Expected $key to be an int or null',
      endpoint: endpoint,
    );
  }
}

class KnowledgeAtomDto {
  const KnowledgeAtomDto({required this.data});
  final Map<String, dynamic> data;

  factory KnowledgeAtomDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/knowledge-atoms/{atom}',
  }) {
    _Parse.intOf(data['id'], 'id', endpoint);
    // Validate the nullable fields here too: a shape change must fail at the
    // boundary, not halfway through rendering the screen.
    _Parse.optionalString(data['title'], 'title', endpoint);
    _Parse.optionalString(data['type'], 'type', endpoint);
    _Parse.optionalString(data['summary'], 'summary', endpoint);
    _Parse.optionalInt(data['topic_id'], 'topic_id', endpoint);
    return KnowledgeAtomDto(data: data);
  }

  KnowledgeAtom toDomain({String endpoint = '/quiz/knowledge-atoms/{atom}'}) =>
      KnowledgeAtom(
        id: _Parse.intOf(data['id'], 'id', endpoint),
        title: _Parse.optionalString(data['title'], 'title', endpoint),
        type: _Parse.optionalString(data['type'], 'type', endpoint),
        summary: _Parse.optionalString(data['summary'], 'summary', endpoint),
        topicId: _Parse.optionalInt(data['topic_id'], 'topic_id', endpoint),
      );
}

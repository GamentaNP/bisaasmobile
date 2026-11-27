import '../../../../core/network/api_failure.dart';
import '../../domain/entities/resource_hub.dart';

/// Wire DTO for `GET /quiz/resources`.
///
/// `sections` is a map of lists, not a list of objects. A malformed section is
/// contract drift and throws; an empty section is a legitimate empty result.
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

  static num numOf(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String requiredString(Object? value, String key, String endpoint) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A resource card has no $key', endpoint: endpoint);
    }
    return text;
  }

  static String? nullableString(Object? value) => value?.toString();
}

class ResourceHubDto {
  const ResourceHubDto({required this.data});
  final Map<String, dynamic> data;

  factory ResourceHubDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/resources',
  }) {
    _Parse.map(data['sections'], 'sections', endpoint);
    return ResourceHubDto(data: data);
  }

  ResourceHub toDomain({String endpoint = '/quiz/resources'}) {
    final rawSections = _Parse.map(data['sections'], 'sections', endpoint);
    final sections = <String, List<ResourceCard>>{};
    for (final entry in rawSections.entries) {
      sections[entry.key] = _Parse
          .list(entry.value, 'sections.${entry.key}', endpoint)
          .whereType<Map<String, dynamic>>()
          .map((j) {
        final category = j['category'] is Map ? j['category'] as Map : null;
        final uploader = j['uploader'] is Map ? j['uploader'] as Map : null;
        return ResourceCard(
          id: _Parse.intOf(j['id']),
          slug: _Parse.requiredString(j['slug'], 'slug', endpoint),
          title: _Parse.requiredString(j['title'], 'title', endpoint),
          description: _Parse.nullableString(j['description']),
          fileType: _Parse.nullableString(j['file_type']),
          coinPrice: _Parse.intOf(j['coin_price']),
          averageRating: _Parse.numOf(j['average_rating']),
          reviewCount: _Parse.intOf(j['review_count']),
          downloadCount: _Parse.intOf(j['download_count']),
          isUnlocked: j['is_unlocked'] == true,
          isFeatured: j['is_featured'] == true,
          detailUrl: _Parse.nullableString(j['detail_url']),
          categoryName: category == null
              ? null
              : _Parse.nullableString(category['name']),
          uploaderName: uploader == null
              ? null
              : _Parse.nullableString(uploader['name']),
        );
      }).toList();
    }

    return ResourceHub(
      sections: sections,
      libraryUrl: _Parse.nullableString(data['library_url']),
      myLibraryUrl: _Parse.nullableString(data['my_library_url']),
      uploadUrl: _Parse.nullableString(data['upload_url']),
    );
  }
}

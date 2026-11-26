import '../../../../app/localization/l10n.dart';
import '../../domain/entities/course_catalog.dart';

/// Wire row of `GET /quiz/courses`.
///
/// The catalog is a plain array under `data` today; `parsePage` in the data
/// source also tolerates an `items`-shaped envelope without letting an
/// unreadable body become an empty catalog.
class CourseCatalogDto {
  const CourseCatalogDto({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory CourseCatalogDto.fromJson(Map<String, dynamic> j) => CourseCatalogDto(
        id: (j['id'] ?? '').toString(),
        title: (j['name'] ?? j['title'] ?? appL10n().courses).toString(),
        description: (j['description'] ?? '').toString(),
      );

  CourseCatalogEntry toDomain() => CourseCatalogEntry(
        id: id,
        title: title,
        description: description,
      );
}

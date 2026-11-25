/// One row of the public course catalog published by `GET /quiz/courses`.
///
/// Pure Dart: no Dio, no envelope and no Flutter. The wire shape is parsed by
/// `CourseCatalogDto` in the data layer; the screen only ever sees this.
class CourseCatalogEntry {
  const CourseCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

import 'package:meta/meta.dart';

/// A course that owns categories. The arcade picker shows these first, because
/// the API only serves categories per course.
@immutable
class ArcadeCourse {
  const ArcadeCourse({required this.id, required this.name});

  final int id;
  final String name;
}

/// A category a run can be scoped to.
///
/// The API only serves categories per course
/// (`GET /quiz/courses/{course}/categories`), so the picker walks
/// course → category rather than pretending a flat list exists.
@immutable
class ArcadeCategory {
  const ArcadeCategory({
    required this.id,
    required this.name,
    required this.courseId,
    required this.courseName,
  });

  final int id;
  final String name;
  final int courseId;
  final String courseName;
}

import '../entities/course_catalog.dart';

/// Domain-facing catalog contract. The screen never sees Dio or the envelope.
// ignore: one_member_abstracts
abstract class CoursesRepository {
  Future<List<CourseCatalogEntry>> getCourses();
}

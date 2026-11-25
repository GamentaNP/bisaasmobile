import '../../domain/entities/course_catalog.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_data_source.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  const CoursesRepositoryImpl(this._remote);

  final CoursesRemoteDataSource _remote;

  @override
  Future<List<CourseCatalogEntry>> getCourses() => _remote.getCourses();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/course_catalog.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_data_source.dart';
import '../repositories/courses_repository_impl.dart';

final coursesRemoteDataSourceProvider = Provider<CoursesRemoteDataSource>((ref) {
  return CoursesRemoteDataSource(ref.watch(dioProvider));
});

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepositoryImpl(ref.watch(coursesRemoteDataSourceProvider));
});

/// The public catalog. Errors propagate to the screen, which renders a retry
/// instead of an empty grid — an unreadable 2xx body is not "no courses".
final coursesProvider = FutureProvider<List<CourseCatalogEntry>>((ref) {
  return ref.watch(coursesRepositoryProvider).getCourses();
});

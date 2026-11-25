import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/quiz_catalog.dart';
import '../../domain/repositories/quiz_catalog_repository.dart';
import '../datasources/quiz_catalog_remote_data_source.dart';
import '../repositories/quiz_catalog_repository_impl.dart';

final quizCatalogRemoteDataSourceProvider =
    Provider<QuizCatalogRemoteDataSource>((ref) {
  return QuizCatalogRemoteDataSource(ref.watch(dioProvider));
});

final quizCatalogRepositoryProvider = Provider<QuizCatalogRepository>((ref) {
  return QuizCatalogRepositoryImpl(
      ref.watch(quizCatalogRemoteDataSourceProvider));
});

final quizCoursesProvider = FutureProvider<List<QuizCourseEntry>>((ref) {
  return ref.watch(quizCatalogRepositoryProvider).getCourses();
});

/// `null` means "no course selected yet": no request is made, and the family
/// still has a stable key so the browser can watch it unconditionally.
final quizCategoriesProvider =
    FutureProvider.family<List<QuizCategoryEntry>, String?>((ref, courseId) {
  if (courseId == null) return Future.value(const <QuizCategoryEntry>[]);
  return ref.watch(quizCatalogRepositoryProvider).getCategories(courseId);
});

final quizQuestionCountProvider = FutureProvider.family<
    QuestionCount, ({String courseId, String? categoryId})>((ref, key) {
  return ref.watch(quizCatalogRepositoryProvider).getQuestionCount(
        courseId: key.courseId,
        categoryId: key.categoryId,
      );
});

final attemptReviewProvider =
    FutureProvider.family<AttemptReview, String>((ref, attemptId) {
  return ref.watch(quizCatalogRepositoryProvider).getAttemptReview(attemptId);
});

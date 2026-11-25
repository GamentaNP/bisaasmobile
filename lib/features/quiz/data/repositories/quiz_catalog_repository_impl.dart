import '../../../../core/network/api_failure.dart';
import '../../domain/entities/quiz_catalog.dart';
import '../../domain/repositories/quiz_catalog_repository.dart';
import '../datasources/quiz_catalog_remote_data_source.dart';

class QuizCatalogRepositoryImpl implements QuizCatalogRepository {
  const QuizCatalogRepositoryImpl(this._remote);

  final QuizCatalogRemoteDataSource _remote;

  @override
  Future<List<QuizCourseEntry>> getCourses() => _remote.getCourses();

  @override
  Future<List<QuizCategoryEntry>> getCategories(String courseId) =>
      _remote.getCategories(courseId);

  @override
  Future<QuestionCount> getQuestionCount({
    required String courseId,
    String? categoryId,
  }) async {
    final endpoint = '/quiz/courses/$courseId/questions';
    final page = await _remote.getQuestionPage(
      courseId: courseId,
      categoryId: categoryId,
    );
    // A server that claims another page but publishes no cursor cannot be
    // walked; that is drift, not a reason to print a definite count.
    if (page.isStalled) {
      throw ContractViolation(
        'has_more was true but no next_cursor was published',
        endpoint: endpoint,
      );
    }
    return QuestionCount(
      rows: page.items.length,
      isLowerBound: page.hasMore,
    );
  }

  @override
  Future<AttemptReview> getAttemptReview(String attemptId) =>
      _remote.getAttemptReview(attemptId);
}

import '../entities/quiz_catalog.dart';

/// Browse/review contract for the screens. No Dio, no envelope and no cursor
/// handling leaks through this interface.
abstract class QuizCatalogRepository {
  Future<List<QuizCourseEntry>> getCourses();

  Future<List<QuizCategoryEntry>> getCategories(String courseId);

  /// One page's worth of questions, flagged when the server says more exist.
  Future<QuestionCount> getQuestionCount({
    required String courseId,
    String? categoryId,
  });

  Future<AttemptReview> getAttemptReview(String attemptId);
}

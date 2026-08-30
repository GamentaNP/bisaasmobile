import 'package:bisaasmobile/shared/domain/paginated.dart';

import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_data_source.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  const PracticeRepositoryImpl(this._remote);
  final PracticeRemoteDataSource _remote;

  @override
  Future<Paginated<BookmarkedQuestion>> getBookmarks({String? cursor, int perPage = 20}) async {
    final res = await _remote.getBookmarks(cursor: cursor, perPage: perPage);
    return Paginated<BookmarkedQuestion>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<bool> toggleBookmark(int questionId, {String? idempotencyKey}) => _remote.toggleBookmark(questionId, idempotencyKey: idempotencyKey);

  @override
  Future<bool> addBookmark(int questionId, {String? idempotencyKey}) => _remote.addBookmark(questionId, idempotencyKey: idempotencyKey);

  @override
  Future<bool> removeBookmark(int questionId) => _remote.removeBookmark(questionId);

  @override
  Future<Paginated<PracticeAttemptHistoryItem>> getAttemptHistory({int page = 1, int perPage = 20}) async {
    final res = await _remote.getAttemptHistory(page: page, perPage: perPage);
    return Paginated<PracticeAttemptHistoryItem>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<List<PracticeQuestion>> getQuestions({
    int? topicId,
    int? categoryId,
    int? courseId,
    String? difficulty,
    String? query,
    int page = 1,
    int perPage = 20,
  }) async {
    final dtos = await _remote.getQuestions(
      topicId: topicId,
      categoryId: categoryId,
      courseId: courseId,
      difficulty: difficulty,
      query: query,
      page: page,
      perPage: perPage,
    );
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<String> startPracticeAttempt({
    List<int>? questionIds,
    int? topicId,
    int? categoryId,
    int? courseId,
    int questionCount = 10,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.startPracticeAttempt(
      questionIds: questionIds,
      topicId: topicId,
      categoryId: categoryId,
      courseId: courseId,
      questionCount: questionCount,
      idempotencyKey: idempotencyKey,
    );
    return dto.attemptId;
  }
}

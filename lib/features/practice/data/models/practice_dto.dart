// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types
import '../../domain/entities/practice.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

// ── PracticeQuestion / BookmarkedQuestion ────────────────────────────────────

class PracticeQuestionDto {
  const PracticeQuestionDto({
    required this.id,
    required this.questionText,
    this.type,
    this.difficulty,
    this.points,
    this.categoryId,
  });

  factory PracticeQuestionDto.fromJson(Map<String, dynamic> j) {
    return PracticeQuestionDto(
      id: _asInt(j['id']) ?? 0,
      questionText: (j['question_text'] ?? j['questionText'] ?? j['body'] ?? j['title'] ?? '').toString(),
      type: j['type'] as String?,
      difficulty: _asInt(j['difficulty']),
      points: _asInt(j['points']),
      categoryId: _asInt(j['quiz_category_id'] ?? j['category_id']),
    );
  }

  final int id;
  final String questionText;
  final String? type;
  final int? difficulty;
  final int? points;
  final int? categoryId;

  PracticeQuestion toDomain() => PracticeQuestion(
        id: id,
        questionText: questionText,
        type: type,
        difficulty: difficulty,
        points: points,
        categoryId: categoryId,
      );
}

class BookmarkedQuestionDto {
  const BookmarkedQuestionDto({required this.question, this.bookmarkedAt});

  factory BookmarkedQuestionDto.fromJson(Map<String, dynamic> j) {
    // Server GET /quiz/bookmarks returns QuizQuestion directly (cursor paginated items are questions)
    // But pivot bookmark may wrap: {question: {...}, created_at}. Tolerant to both.
    Map<String, dynamic> qJson;
    DateTime? bookmarkedAt;
    if (j['question'] is Map<String, dynamic>) {
      qJson = j['question'] as Map<String, dynamic>;
      bookmarkedAt = _asDate(j['created_at'] ?? j['bookmarked_at']);
    } else {
      qJson = j;
      bookmarkedAt = _asDate(j['created_at'] ?? j['bookmarked_at']);
    }
    return BookmarkedQuestionDto(question: PracticeQuestionDto.fromJson(qJson), bookmarkedAt: bookmarkedAt);
  }

  final PracticeQuestionDto question;
  final DateTime? bookmarkedAt;

  BookmarkedQuestion toDomain() => BookmarkedQuestion(question: question.toDomain(), bookmarkedAt: bookmarkedAt);
}

// ── Attempt history ──────────────────────────────────────────────────────────

class PracticeAttemptHistoryDto {
  const PracticeAttemptHistoryDto({
    required this.id,
    required this.mode,
    required this.status,
    this.score,
    this.correctCount,
    this.wrongCount,
    this.skippedCount,
    this.questionCount,
    this.completedAt,
    this.createdAt,
  });

  factory PracticeAttemptHistoryDto.fromJson(Map<String, dynamic> j) {
    // Shape from paginated history: QuizAttempt model fields
    // Use tolerant parsing — extra fields ignored
    return PracticeAttemptHistoryDto(
      id: _asInt(j['id']) ?? 0,
      mode: (j['mode'] as String?) ?? 'standard',
      status: (j['status'] as String?) ?? 'unknown',
      score: _asInt(j['score']),
      correctCount: _asInt(j['correct_count']),
      wrongCount: _asInt(j['wrong_count']),
      skippedCount: _asInt(j['skipped_count']),
      questionCount: _asInt(j['question_count'] ?? j['total_questions']),
      completedAt: _asDate(j['completed_at'] ?? j['finished_at']),
      createdAt: _asDate(j['created_at'] ?? j['started_at']),
    );
  }

  final int id;
  final String mode;
  final String status;
  final int? score;
  final int? correctCount;
  final int? wrongCount;
  final int? skippedCount;
  final int? questionCount;
  final DateTime? completedAt;
  final DateTime? createdAt;

  PracticeAttemptHistoryItem toDomain() => PracticeAttemptHistoryItem(
        id: id,
        mode: mode,
        status: status,
        score: score,
        correctCount: correctCount,
        wrongCount: wrongCount,
        skippedCount: skippedCount,
        questionCount: questionCount,
        completedAt: completedAt,
        createdAt: createdAt,
      );
}

// ── Self-challenge start result ─────────────────────────────────────────────

class PracticeStartDto {
  const PracticeStartDto({required this.attemptId, required this.mode, required this.status, this.questionCount = 0});
  factory PracticeStartDto.fromJson(Map<String, dynamic> j) => PracticeStartDto(
        attemptId: (_asInt(j['attempt_id'] ?? j['id']) ?? 0).toString(),
        mode: (j['mode'] as String?) ?? 'practice',
        status: (j['status'] as String?) ?? 'in_progress',
        questionCount: _asInt(j['question_count']) ?? 0,
      );
  final String attemptId;
  final String mode;
  final String status;
  final int questionCount;
}

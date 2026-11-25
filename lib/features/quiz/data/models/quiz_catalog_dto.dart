import 'package:bisaasmobile/shared/utils/wire_coercion.dart';
import '../../domain/entities/quiz_catalog.dart';

class QuizCourseDto {
  const QuizCourseDto({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory QuizCourseDto.fromJson(Map<String, dynamic> j) => QuizCourseDto(
        id: (j['id'] ?? '').toString(),
        title: (j['name'] ?? j['title'] ?? 'Course').toString(),
        description: (j['description'] ?? '').toString(),
      );

  QuizCourseEntry toDomain() => QuizCourseEntry(
        id: id,
        title: title,
        description: description,
      );
}

class QuizCategoryDto {
  const QuizCategoryDto({required this.id, required this.name});

  final String id;
  final String name;

  factory QuizCategoryDto.fromJson(Map<String, dynamic> j) => QuizCategoryDto(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? j['slug'] ?? 'Topic').toString(),
      );

  QuizCategoryEntry toDomain() => QuizCategoryEntry(id: id, name: name);
}

/// One row of a cursor page. The browser only needs the page size and the
/// pagination block; it deliberately does not download question text.
class QuestionRowDto {
  const QuestionRowDto({this.id});

  final String? id;

  factory QuestionRowDto.fromJson(Map<String, dynamic> j) =>
      QuestionRowDto(id: j['id']?.toString());
}

/// DTO for `data` of `GET /quiz/attempts/{id}/results`.
///
/// The results endpoint used to be read with a chain of alternative keys and
/// a silent `?? []`. The row key is now resolved by `extractRows` in the data
/// source, so an unrecognised body throws instead of rendering "no answers".
class AttemptReviewDto {
  const AttemptReviewDto(this.entries);

  final List<AttemptReviewEntryDto> entries;

  factory AttemptReviewDto.fromJson(List<Map<String, dynamic>> rows) =>
      AttemptReviewDto(
        rows.map(AttemptReviewEntryDto.fromJson).toList(growable: false),
      );

  AttemptReview toDomain() => AttemptReview(
        entries.map((dto) => dto.toDomain()).toList(growable: false),
      );
}

class AttemptReviewEntryDto {
  const AttemptReviewEntryDto({
    required this.body,
    this.userOptionId,
    this.correctOptionId,
    this.userOptionText,
    this.correctOptionText,
    this.explanation,
    this.difficulty,
    this.isCorrect,
    this.isSkipped,
  });

  final String body;
  final String? userOptionId;
  final String? correctOptionId;
  final String? userOptionText;
  final String? correctOptionText;
  final String? explanation;
  final int? difficulty;
  final bool? isCorrect;
  final bool? isSkipped;

  factory AttemptReviewEntryDto.fromJson(Map<String, dynamic> j) {
    return AttemptReviewEntryDto(
      body: (j['body'] ?? j['question'] ?? j['question_text'] ?? '').toString(),
      userOptionId: j['user_option_id']?.toString() ??
          j['given_answer']?.toString() ??
          j['selected_option_id']?.toString(),
      correctOptionId: j['correct_option_id']?.toString(),
      userOptionText: j['user_option_text']?.toString() ??
          j['selected_option_text']?.toString(),
      correctOptionText: j['correct_option_text']?.toString(),
      explanation: j['explanation']?.toString(),
      difficulty: wireInt(j['difficulty']),
      isCorrect: _asBool(j['is_correct']),
      isSkipped: _asBool(j['is_skipped']),
    );
  }

  AttemptReviewEntry toDomain() => AttemptReviewEntry(
        body: body,
        userOptionId: userOptionId,
        correctOptionId: correctOptionId,
        userOptionText: userOptionText,
        correctOptionText: correctOptionText,
        explanation: explanation,
        difficulty: difficulty,
        isCorrect: isCorrect,
        isSkipped: isSkipped,
      );
}

bool? _asBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v == null) return null;
  return v.toString().toLowerCase() == 'true';
}

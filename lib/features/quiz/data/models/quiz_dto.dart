import 'dart:convert';
import '../../domain/entities/question.dart';

class AnswerOptionDto {
  const AnswerOptionDto({required this.id, required this.text, required this.position});

  factory AnswerOptionDto.fromJson(Map<String, dynamic> j) => AnswerOptionDto(
        id: j['id'] as String,
        text: (j['text'] ?? j['body'] ?? '') as String,
        position: (j['position'] as int?) ?? 0,
      );

  final String id;
  final String text;
  final int position;

  AnswerOption toDomain() => AnswerOption(id: id, text: text, position: position);
}

class QuestionDto {
  const QuestionDto({
    required this.id,
    required this.body,
    required this.options,
    required this.subjectSlug,
    required this.difficulty,
    required this.marksPositive,
    required this.marksNegative,
    this.quizId,
    this.explanation,
    this.correctOptionId,
  });

  factory QuestionDto.fromJson(Map<String, dynamic> j) {
    final rawOptions = j['options'] ?? j['answers'] ?? [];
    final List<AnswerOptionDto> options;

    if (rawOptions is List) {
      options = rawOptions
          .cast<Map<String, dynamic>>()
          .map(AnswerOptionDto.fromJson)
          .toList();
    } else if (rawOptions is String) {
      // Drift stores JSON-encoded list
      final decoded = jsonDecode(rawOptions) as List;
      options = decoded
          .cast<Map<String, dynamic>>()
          .map(AnswerOptionDto.fromJson)
          .toList();
    } else {
      options = [];
    }

    return QuestionDto(
      id: (j['id'] ?? j['uuid'] ?? '') as String,
      body: (j['body'] ?? j['question'] ?? '') as String,
      options: options,
      subjectSlug: (j['subject_slug'] ?? j['category_slug'] ?? '') as String,
      difficulty: (j['difficulty'] as int?) ?? 1,
      marksPositive: (j['marks_positive'] as int?) ?? (j['marks'] as int?) ?? 4,
      marksNegative: (j['marks_negative'] as int?) ?? 0,
      quizId: j['quiz_id'] as String?,
      explanation: j['explanation'] as String?,
      correctOptionId: j['correct_option_id'] as String?,
    );
  }

  final String id;
  final String body;
  final List<AnswerOptionDto> options;
  final String subjectSlug;
  final int difficulty;
  final int marksPositive;
  final int marksNegative;
  final String? quizId;
  final String? explanation;
  final String? correctOptionId;

  Question toDomain() => Question(
        id: id,
        body: body,
        options: options.map((o) => o.toDomain()).toList(),
        subjectSlug: subjectSlug,
        difficulty: difficulty,
        marksPositive: marksPositive,
        marksNegative: marksNegative,
        quizId: quizId,
        explanation: explanation,
        correctOptionId: correctOptionId,
      );

  String optionsToJson() => jsonEncode(
        options.map((o) => {'id': o.id, 'text': o.text, 'position': o.position}).toList(),
      );
}

class QuizSessionDto {
  const QuizSessionDto({
    required this.id,
    required this.title,
    required this.questions,
    required this.durationSeconds,
    this.xpReward = 0,
    this.coinsReward = 0,
    this.subjectSlug,
  });

  factory QuizSessionDto.fromJson(Map<String, dynamic> j) {
    final rawQs = (j['questions'] ?? j['items'] ?? []) as List;
    final questions = rawQs
        .cast<Map<String, dynamic>>()
        .map(QuestionDto.fromJson)
        .toList();

    return QuizSessionDto(
      id: (j['id'] ?? j['uuid'] ?? '') as String,
      title: (j['title'] ?? j['name'] ?? 'Quiz') as String,
      questions: questions,
      durationSeconds: (j['duration_seconds'] as int?) ??
          ((j['duration_minutes'] as int?) ?? 15) * 60,
      xpReward: (j['xp_reward'] as int?) ?? 0,
      coinsReward: (j['coins_reward'] as int?) ?? 0,
      subjectSlug: j['subject_slug'] as String?,
    );
  }

  final String id;
  final String title;
  final List<QuestionDto> questions;
  final int durationSeconds;
  final int xpReward;
  final int coinsReward;
  final String? subjectSlug;

  QuizSession toDomain() => QuizSession(
        id: id,
        title: title,
        questions: questions.map((q) => q.toDomain()).toList(),
        durationSeconds: durationSeconds,
        xpReward: xpReward,
        coinsReward: coinsReward,
        subjectSlug: subjectSlug,
      );
}

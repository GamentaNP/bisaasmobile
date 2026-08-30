import 'package:meta/meta.dart';

@immutable
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    required this.position,
  });

  final String id;
  final String text;
  final int position;
}

@immutable
class Question {
  const Question({
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

  final String id;
  final String body;
  final List<AnswerOption> options;
  final String subjectSlug;
  final int difficulty;
  final int marksPositive;
  final int marksNegative;
  final String? quizId;
  final String? explanation;
  // Only populated after server grading
  final String? correctOptionId;
}

@immutable
class QuizSession {
  const QuizSession({
    required this.id,
    required this.title,
    required this.questions,
    required this.durationSeconds,
    this.xpReward = 0,
    this.coinsReward = 0,
    this.subjectSlug,
  });

  final String id;
  final String title;
  final List<Question> questions;
  final int durationSeconds;
  final int xpReward;
  final int coinsReward;
  final String? subjectSlug;

  int get totalQuestions => questions.length;
}

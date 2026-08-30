import 'package:meta/meta.dart';

@immutable
class AttemptResult {
  const AttemptResult({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.xpEarned,
    required this.coinsEarned,
    required this.correctOptionId,
    this.explanation,
    this.newStreakDays,
    this.comboCount,
  });

  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;
  final int xpEarned;
  final int coinsEarned;
  final String correctOptionId;
  final String? explanation;
  final int? newStreakDays;
  final int? comboCount;
}

@immutable
class QuizResult {
  const QuizResult({
    required this.attemptId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skipped,
    required this.totalXpEarned,
    required this.totalCoinsEarned,
    required this.durationSeconds,
    required this.accuracy,
    this.streakDays,
    this.leaderboardRank,
  });

  final String attemptId;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skipped;
  final int totalXpEarned;
  final int totalCoinsEarned;
  final int durationSeconds;
  final double accuracy;
  final int? streakDays;
  final int? leaderboardRank;
}

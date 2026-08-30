import '../../domain/entities/attempt_result.dart';

class AttemptResultDto {
  const AttemptResultDto({
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

  factory AttemptResultDto.fromJson(Map<String, dynamic> j) {
    return AttemptResultDto(
      questionId: (j['question_id'] ?? '') as String,
      selectedOptionId: (j['selected_option_id'] ?? j['answer_id'] ?? '') as String,
      isCorrect: (j['is_correct'] as bool?) ?? false,
      xpEarned: (j['xp_earned'] as int?) ?? 0,
      coinsEarned: (j['coins_earned'] as int?) ?? 0,
      correctOptionId: (j['correct_option_id'] ?? '') as String,
      explanation: j['explanation'] as String?,
      newStreakDays: j['streak_days'] as int?,
      comboCount: j['combo_count'] as int?,
    );
  }

  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;
  final int xpEarned;
  final int coinsEarned;
  final String correctOptionId;
  final String? explanation;
  final int? newStreakDays;
  final int? comboCount;

  AttemptResult toDomain() => AttemptResult(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: isCorrect,
        xpEarned: xpEarned,
        coinsEarned: coinsEarned,
        correctOptionId: correctOptionId,
        explanation: explanation,
        newStreakDays: newStreakDays,
        comboCount: comboCount,
      );
}

class QuizResultDto {
  const QuizResultDto({
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

  factory QuizResultDto.fromJson(Map<String, dynamic> j) {
    final stats = (j['stats'] ?? j) as Map<String, dynamic>;
    final total = (stats['total_questions'] as int?) ?? 0;
    final correct = (stats['correct'] as int?) ?? (stats['correct_answers'] as int?) ?? 0;

    return QuizResultDto(
      attemptId: (j['attempt_id'] ?? j['id'] ?? '') as String,
      totalQuestions: total,
      correctAnswers: correct,
      wrongAnswers: (stats['wrong'] as int?) ?? (stats['incorrect'] as int?) ?? (total - correct),
      skipped: (stats['skipped'] as int?) ?? 0,
      totalXpEarned: (j['total_xp_earned'] ?? j['xp_earned'] ?? 0) as int,
      totalCoinsEarned: (j['total_coins_earned'] ?? j['coins_earned'] ?? 0) as int,
      durationSeconds: (j['duration_seconds'] as int?) ?? 0,
      accuracy: total > 0 ? correct / total : 0,
      streakDays: j['streak_days'] as int?,
      leaderboardRank: j['leaderboard_rank'] as int?,
    );
  }

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

  QuizResult toDomain() => QuizResult(
        attemptId: attemptId,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        skipped: skipped,
        totalXpEarned: totalXpEarned,
        totalCoinsEarned: totalCoinsEarned,
        durationSeconds: durationSeconds,
        accuracy: accuracy,
        streakDays: streakDays,
        leaderboardRank: leaderboardRank,
      );
}

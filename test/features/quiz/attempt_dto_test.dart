import 'package:bisaasmobile/features/quiz/data/models/attempt_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuizResultDto maps authoritative completion totals', () {
    final result = QuizResultDto.fromJson({
      'attempt_id': 'a1',
      'stats': {
        'total_questions': 12,
        'correct': 9,
        'wrong': 2,
        'skipped': 1,
      },
      'total_xp_earned': 90,
      'total_coins_earned': 18,
      'duration_seconds': 75,
    }).toDomain();

    expect(result.attemptId, 'a1');
    expect(result.totalQuestions, 12);
    expect(result.correctAnswers, 9);
    expect(result.wrongAnswers, 2);
    expect(result.skipped, 1);
    expect(result.totalXpEarned, 90);
    expect(result.totalCoinsEarned, 18);
    expect(result.accuracy, closeTo(0.75, 0.001));
  });
}

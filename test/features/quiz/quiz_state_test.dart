import 'package:bisaasmobile/features/quiz/domain/entities/attempt_result.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/question.dart';
import 'package:bisaasmobile/features/quiz/presentation/state/quiz_state.dart';
import 'package:flutter_test/flutter_test.dart';

QuizSession fakeSession() => const QuizSession(
      id: 's1',
      title: 'Test',
      questions: [
        Question(id: 'q1', body: 'Q1?', options: [AnswerOption(id: 'o1', text: 'A', position: 0), AnswerOption(id: 'o2', text: 'B', position: 1)], subjectSlug: 'soil', difficulty: 1, marksPositive: 4, marksNegative: 1),
        Question(id: 'q2', body: 'Q2?', options: [AnswerOption(id: 'o3', text: 'C', position: 0)], subjectSlug: 'soil', difficulty: 1, marksPositive: 4, marksNegative: 1),
      ],
      durationSeconds: 120,
    );

void main() {
  test('QuizState.initial defaults', () {
    final s = QuizState.initial();
    expect(s.phase, QuizPhase.loading);
    expect(s.currentIndex, 0);
    expect(s.answers, isEmpty);
    expect(s.quizResult, isNull);
    expect(s.isOfflinePractice, false);
    expect(s.remainingSeconds, 0);
  });

  test('stores and clears the authoritative quiz result', () {
    const result = QuizResult(
      attemptId: 'a1', totalQuestions: 10, correctAnswers: 8,
      wrongAnswers: 1, skipped: 1, totalXpEarned: 80,
      totalCoinsEarned: 20, durationSeconds: 42, accuracy: 0.8,
    );
    var s = QuizState.initial().copyWith(phase: QuizPhase.finished, quizResult: result);
    expect(s.quizResult, same(result));
    s = s.copyWith(quizResult: null);
    expect(s.quizResult, isNull);
  });

  test('copyWith sentinel clears lastResult', () {
    final session = fakeSession();
    var s = QuizState.initial().copyWith(session: session, phase: QuizPhase.answering, attemptId: 'a1');
    s = s.copyWith(phase: QuizPhase.feedback, lastResult: const AttemptResult(questionId: 'q1', selectedOptionId: 'o1', isCorrect: true, xpEarned: 10, coinsEarned: 5, correctOptionId: 'o1'), selectedOptionId: 'o1');
    expect(s.lastResult, isNotNull);
    s = s.copyWith(phase: QuizPhase.answering, currentIndex: 1, lastResult: null, selectedOptionId: null);
    expect(s.lastResult, isNull);
    expect(s.selectedOptionId, isNull);
    expect(s.currentIndex, 1);
  });

  test('isLastQuestion and remainingSeconds', () {
    final s = QuizState.initial().copyWith(session: fakeSession(), phase: QuizPhase.answering);
    expect(s.isLastQuestion, false);
    expect(s.remainingSeconds, 120);
    final s2 = s.copyWith(elapsedSeconds: 60);
    expect(s2.remainingSeconds, 60);
    final s3 = s.copyWith(currentIndex: 1);
    expect(s3.isLastQuestion, true);
  });

  test('isOfflinePractice flag', () {
    final s = QuizState.initial().copyWith(isOfflinePractice: true);
    expect(s.isOfflinePractice, true);
  });
}

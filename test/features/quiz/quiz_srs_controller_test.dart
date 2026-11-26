/// The quiz SRS controller owns one stable grade key per intent and only
/// refreshes the due queue after the server accepted a grade. Those are
/// controller responsibilities, so they are tested one layer at a time here;
/// the wire behaviour is pinned by
/// `test/integration/quiz_srs_review_integration_test.dart`.
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/quiz_srs.dart';
import 'package:bisaasmobile/features/quiz/domain/repositories/quiz_srs_repository.dart';
import 'package:bisaasmobile/features/quiz/presentation/controllers/quiz_srs_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQuizSrsRepository extends Mock implements QuizSrsRepository {}

void main() {
  late MockQuizSrsRepository repo;

  final card = QuizSrsCard(
    id: '7',
    type: QuizSrsCardType.question,
    content: 'Due question',
    dueAt: DateTime.utc(2026, 11, 26),
  );

  const graded = QuizSrsGradeResult(
    id: '7',
    type: QuizSrsCardType.question,
    quality: QuizSrsQuality.good,
    intervalDays: 9,
    repetitions: 4,
    easinessFactor: 2.6,
  );

  setUp(() {
    repo = MockQuizSrsRepository();
    when(() => repo.getDueCards()).thenAnswer((_) async => [card]);
  });

  ProviderContainer boot() {
    final c = ProviderContainer(
      overrides: [quizSrsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  void stubGrade() {
    when(() => repo.gradeReview(
          any(),
          quality: any(named: 'quality'),
          type: any(named: 'type'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => graded);
  }

  test('a successful grade refreshes the queue and keeps the server result',
      () async {
    stubGrade();
    final container = boot();
    await container.read(quizSrsDueProvider.future);

    final result = await container
        .read(quizSrsControllerProvider.notifier)
        .grade('7', quality: QuizSrsQuality.good, type: card.type);

    expect(result, same(graded));
    final state = container.read(quizSrsControllerProvider);
    expect(state.isGrading, isFalse);
    expect(state.gradeError, isNull);
    expect(state.lastGrade, same(graded));
    await container.read(quizSrsDueProvider.future);
    verify(() => repo.getDueCards()).called(2);
  });

  test('a failed grade exposes the server message and does not refresh',
      () async {
    when(() => repo.gradeReview(
          any(),
          quality: any(named: 'quality'),
          type: any(named: 'type'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(
      const ApiException(
        statusCode: 500,
        code: ApiErrorCode.internalError,
        message: 'Grade could not be stored',
      ),
    );
    final container = boot();
    await container.read(quizSrsDueProvider.future);

    final result = await container
        .read(quizSrsControllerProvider.notifier)
        .grade('7', quality: QuizSrsQuality.good, type: card.type);

    expect(result, isNull);
    final state = container.read(quizSrsControllerProvider);
    expect(state.isGrading, isFalse);
    expect(state.gradeError, 'Grade could not be stored');
    expect(state.lastGrade, isNull);
    await container.read(quizSrsDueProvider.future);
    verify(() => repo.getDueCards()).called(1);
  });

  test('a retry reuses the key, and a different quality gets a new one',
      () async {
    var calls = 0;
    when(() => repo.gradeReview(
          any(),
          quality: any(named: 'quality'),
          type: any(named: 'type'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw const ApiException(
          statusCode: 500,
          code: ApiErrorCode.internalError,
          message: 'Grade could not be stored',
        );
      }
      return graded;
    });
    final container = boot();
    final controller = container.read(quizSrsControllerProvider.notifier);

    await controller.grade('7', quality: QuizSrsQuality.good, type: card.type);
    await controller.grade('7', quality: QuizSrsQuality.good, type: card.type);
    await controller.grade('7', quality: QuizSrsQuality.easy, type: card.type);

    final keys = verify(
      () => repo.gradeReview(
        '7',
        quality: any(named: 'quality'),
        type: any(named: 'type'),
        idempotencyKey: captureAny(named: 'idempotencyKey'),
      ),
    ).captured.cast<String>();
    expect(keys, hasLength(3));
    expect(keys[0], keys[1], reason: 'a retry must replay the first grade');
    expect(keys[2], isNot(keys[0]),
        reason: 'a different quality is a different grade intent');
  });

  test('the invalid-quality guard never mutates the queue', () async {
    final container = boot();
    final result = await container
        .read(quizSrsControllerProvider.notifier)
        .grade('7', quality: 9, type: card.type);

    expect(result, isNull);
    expect(container.read(quizSrsControllerProvider).gradeError,
        isNotNull);
    verifyNever(() => repo.gradeReview(
          any(),
          quality: any(named: 'quality'),
          type: any(named: 'type'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));
  });
}

import 'package:bisaasmobile/features/quiz/domain/entities/content_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generation is asynchronous and server-side, so the state that matters here is
/// the one where the client must *not* claim a test is ready. These tests pin the
/// honesty of `canStart` and `statusLabel` against a status the server may one
/// day send that this client has not seen.
void main() {
  group('GenerationStatus', () {
    test('parses the known statuses', () {
      expect(GenerationStatus.byName('pending'), GenerationStatus.pending);
      expect(GenerationStatus.byName('generating'), GenerationStatus.generating);
      expect(GenerationStatus.byName('ready'), GenerationStatus.ready);
      expect(GenerationStatus.byName('failed'), GenerationStatus.failed);
    });

    test('is case-insensitive', () {
      expect(GenerationStatus.byName('READY'), GenerationStatus.ready);
    });

    test('an unknown status reads as pending, never as ready', () {
      // This is the important direction of the default. Guessing `ready` would
      // offer a user a start button for a test whose questions may not exist.
      expect(GenerationStatus.byName('queued'), GenerationStatus.pending);
      expect(GenerationStatus.byName('complete'), GenerationStatus.pending);
      expect(GenerationStatus.byName(null), GenerationStatus.pending);
      expect(GenerationStatus.byName(''), GenerationStatus.pending);
    });

    test('only ready is ready', () {
      expect(GenerationStatus.ready.isReady, isTrue);
      for (final s in [
        GenerationStatus.pending,
        GenerationStatus.generating,
        GenerationStatus.failed,
      ]) {
        expect(s.isReady, isFalse, reason: '$s must not read as ready');
      }
    });
  });

  group('ContentQuizScope', () {
    test('parses the four server scopes', () {
      expect(ContentQuizScope.byName('topic'), ContentQuizScope.topic);
      expect(ContentQuizScope.byName('chapter'), ContentQuizScope.chapter);
      expect(ContentQuizScope.byName('book'), ContentQuizScope.book);
      expect(ContentQuizScope.byName('selection'), ContentQuizScope.selection);
    });

    test('an unknown scope falls back to the widest real scope', () {
      // The server rejects an unknown scope with 422 via `in:`; this default only
      // guards against a client-side guess at a value it should not send.
      expect(ContentQuizScope.byName('everything'), ContentQuizScope.selection);
      expect(ContentQuizScope.byName(null), ContentQuizScope.selection);
    });

    test('the wire value matches the server token exactly', () {
      for (final s in ContentQuizScope.values) {
        expect(ContentQuizScope.byName(s.wireValue), s);
      }
    });
  });

  group('ContentQuiz readiness', () {
    const ready = ContentQuiz(
      id: 1,
      scope: ContentQuizScope.chapter,
      questionCount: 10,
      generationStatus: GenerationStatus.ready,
      questionIds: [1, 2, 3],
    );

    test('a ready quiz with questions can start', () {
      expect(ready.canStart, isTrue);
      expect(ready.statusLabel, 'Ready to take');
    });

    test('a pending quiz cannot start', () {
      const pending = ContentQuiz(
        id: 1,
        scope: ContentQuizScope.chapter,
        generationStatus: GenerationStatus.pending,
        questionCount: 10,
        questionIds: [1, 2, 3],
      );
      expect(pending.canStart, isFalse);
      expect(pending.statusLabel, 'Waiting to be prepared');
    });

    test('a generating quiz says so rather than "ready"', () {
      const generating = ContentQuiz(
        id: 1,
        scope: ContentQuizScope.book,
        generationStatus: GenerationStatus.generating,
        questionIds: [1, 2],
      );
      expect(generating.canStart, isFalse);
      expect(generating.statusLabel, 'Being prepared…');
    });

    test('a failed quiz says so', () {
      const failed = ContentQuiz(
        id: 1,
        scope: ContentQuizScope.topic,
        generationStatus: GenerationStatus.failed,
      );
      expect(failed.canStart, isFalse);
      expect(failed.statusLabel, 'Could not be generated');
    });

    test('ready with no question ids cannot start, and says why', () {
      // A server inconsistency. Offering a start button would be a lie, and the
      // label must not simply say "Ready to take".
      const inconsistent = ContentQuiz(
        id: 1,
        scope: ContentQuizScope.chapter,
        questionCount: 10,
        generationStatus: GenerationStatus.ready,
        questionIds: [],
      );
      expect(inconsistent.canStart, isFalse);
      expect(inconsistent.statusLabel, isNot('Ready to take'));
      expect(inconsistent.statusLabel, contains('no questions'));
    });

    test('the question count is not trusted as a substitute for the ids', () {
      const counted = ContentQuiz(
        id: 1,
        scope: ContentQuizScope.chapter,
        questionCount: 10,
        generationStatus: GenerationStatus.ready,
        questionIds: [],
      );
      expect(counted.questionCount, 10);
      expect(counted.canStart, isFalse);
    });

    test('a brand-new quiz defaults to pending', () {
      const fresh = ContentQuiz(id: 9, scope: ContentQuizScope.selection);
      expect(fresh.generationStatus, GenerationStatus.pending);
      expect(fresh.canStart, isFalse);
    });
  });
}

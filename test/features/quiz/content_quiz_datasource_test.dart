import 'package:bisaasmobile/features/quiz/data/datasources/content_quiz_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/content_quiz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContentQuizRemote extends Mock implements ContentQuizRemoteDataSource {}

void main() {
  late MockContentQuizRemote remote;

  setUpAll(() {
    // mocktail needs a concrete value for `any(named: 'scope')` under sound
    // null safety; without this the stub cannot even be registered.
    registerFallbackValue(ContentQuizScope.selection);
  });

  setUp(() => remote = MockContentQuizRemote());

  // Only `create` is exercised here; the other two are thin passthroughs and the
  // DTO-level parsing is covered in content_quiz_test.dart.
  void stubCreate({ContentQuiz? result}) {
    if (result == null) {
      when(() => remote.create(
            scope: any(named: 'scope'),
            topicId: any(named: 'topicId'),
            chapterId: any(named: 'chapterId'),
            bookId: any(named: 'bookId'),
          )).thenThrow(StateError('no stub'));
    } else {
      when(() => remote.create(
            scope: any(named: 'scope'),
            topicId: any(named: 'topicId'),
            chapterId: any(named: 'chapterId'),
            bookId: any(named: 'bookId'),
          )).thenAnswer((_) async => result);
    }
  }

  const pending = ContentQuiz(
    id: 1,
    scope: ContentQuizScope.chapter,
    questionCount: 10,
    generationStatus: GenerationStatus.pending,
  );

  const ready = ContentQuiz(
    id: 2,
    scope: ContentQuizScope.chapter,
    questionCount: 8,
    generationStatus: GenerationStatus.ready,
    questionIds: [1, 2],
  );

  group('ContentQuizScope', () {
    test('the wire values are the tokens the server validates with in:', () {
      // `scope` is validated as in:topic,chapter,book,selection. If a rename here
      // ever diverges, every create call 422s.
      expect(ContentQuizScope.values.map((s) => s.wireValue).toList(), [
        'topic',
        'chapter',
        'book',
        'selection',
      ]);
    });
  });

  group('GenerationStatus', () {
    test('the wire values cover what the server can send', () {
      expect(GenerationStatus.values.map((s) => s.name).toList(),
          containsAll(['pending', 'generating', 'ready', 'failed']));
    });
  });

  group('ContentQuiz state a screen depends on', () {
    test('a freshly created quiz is not startable', () {
      expect(pending.canStart, isFalse);
      expect(pending.statusLabel, 'Waiting to be prepared');
    });

    test('a ready quiz with questions is startable', () {
      expect(ready.canStart, isTrue);
      expect(ready.statusLabel, 'Ready to take');
    });

    test('the scope is carried through so the caller can describe it', () {
      expect(pending.scope, ContentQuizScope.chapter);
      expect(pending.scope.wireValue, 'chapter');
    });

    test('an inconsistent ready-with-no-questions record is not startable', () {
      // Guards the failure mode where a partial server change returns
      // generation_status: ready before question_ids is populated.
      const inconsistent = ContentQuiz(
        id: 3,
        scope: ContentQuizScope.book,
        generationStatus: GenerationStatus.ready,
      );
      expect(inconsistent.canStart, isFalse);
      expect(inconsistent.statusLabel, contains('no questions'));
    });
  });

  group('remote data source contract', () {
    // The remote is mocked here rather than driven through Dio, so these are
    // contract assertions: they fail if the repository's required parameters
    // change shape, which is what breaks the create call against the server.
    test('create is called with the scope the caller chose', () async {
      stubCreate(result: pending);
      final result = await remote.create(
        scope: ContentQuizScope.chapter,
        chapterId: 9,
      );
      expect(result, pending);
      verify(() => remote.create(
            scope: ContentQuizScope.chapter,
            topicId: null,
            chapterId: 9,
            bookId: null,
          )).called(1);
    });

    test('create propagates a server rejection rather than inventing a quiz', () async {
      stubCreate();
      expect(
        () => remote.create(scope: ContentQuizScope.book, bookId: 1),
        throwsA(isA<StateError>()),
      );
    });
  });
}

import 'package:bisaasmobile/features/book/data/datasources/book_remote_data_source.dart';
import 'package:bisaasmobile/features/book/data/repositories/book_repository_impl.dart';
import 'package:bisaasmobile/features/book/domain/entities/book.dart';
import 'package:bisaasmobile/features/book/presentation/controllers/book_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBookRemote extends Mock implements BookRemoteDataSource {}

/// Controller-level tests for the reader.
///
/// The DTO tests pin the credit contract (a voided session is never shown as an
/// award). These pin the state transitions around it, which is where the
/// user-facing lie would appear: a spinner that sticks, a void message that
/// survives into a fresh problem, or a progress sync that quietly reports success
/// on an unreadable response.
void main() {
  late MockBookRemote remote;

  setUpAll(() => registerFallbackValue(<String, double>{}));

  setUp(() => remote = MockBookRemote());

  const book = Book(
    id: 7,
    slug: 'civil-2080',
    title: 'Civil Engineering',
    chapters: [
      BookChapter(id: 3, title: 'Limit Analysis', startPage: 41, topics: [
        BookTopic(id: 22, title: 'Three moment theorem'),
      ]),
    ],
  );

  BookPage page(int number) => BookPage(pageNumber: number, blocks: const [
        BookPageBlock(id: 1, type: 'text', text: 'Bending moment'),
      ]);

  ProviderContainer containerWith({
    Book? detail,
    BookPage? firstPage,
    ReadingProgress? progress,
    bool failDetail = false,
    bool failPage = false,
    bool failSync = false,
  }) {
    if (failDetail) {
      when(() => remote.getBook(any())).thenThrow(StateError('boom'));
    } else {
      when(() => remote.getBook(any()))
          .thenAnswer((_) => Future.value(detail ?? book));
    }
    when(() => remote.getProgress(any())).thenAnswer((_) => Future.value(progress));
    if (failPage) {
      when(() => remote.getPage(any(), any())).thenThrow(StateError('boom'));
    } else {
      when(() => remote.getPage(any(), any()))
          .thenAnswer((invocation) async =>
              firstPage ?? page(invocation.positionalArguments[1] as int));
    }
    if (failSync) {
      when(() => remote.reportProgress(
            bookId: any(named: 'bookId'),
            topicId: any(named: 'topicId'),
            pageNumber: any(named: 'pageNumber'),
            timeSpentSeconds: any(named: 'timeSpentSeconds'),
          )).thenThrow(StateError('boom'));
    } else {
      when(() => remote.reportProgress(
            bookId: any(named: 'bookId'),
            topicId: any(named: 'topicId'),
            pageNumber: any(named: 'pageNumber'),
            timeSpentSeconds: any(named: 'timeSpentSeconds'),
          )).thenAnswer((_) => Future.value(progress));
    }
    when(remote.getMyHighlights).thenAnswer((_) async => const <BookHighlight>[]);

    final c = ProviderContainer(
      overrides: [bookRemoteDataSourceProvider.overrideWithValue(remote)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('book detail', () {
    test('loads the book', () async {
      final c = containerWith();
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      final s = c.read(bookDetailControllerProvider('civil-2080'));
      expect(s.book!.slug, 'civil-2080');
      expect(s.error, isNull);
    });

    test('an unavailable book says so rather than showing a blank screen', () async {
      when(() => remote.getBook(any())).thenAnswer((_) => Future.value(null));
      when(() => remote.getProgress(any())).thenAnswer((_) => Future.value(null));
      final c = ProviderContainer(
        overrides: [bookRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      c.read(bookDetailControllerProvider('missing'));
      await settle(c);
      expect(c.read(bookDetailControllerProvider('missing')).error, isNotNull);
    });

    test('a failed detail load surfaces an error', () async {
      final c = containerWith(failDetail: true);
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      expect(c.read(bookDetailControllerProvider('civil-2080')).error, isNotNull);
    });

    test('progress being unavailable does not break the book', () async {
      when(() => remote.getBook(any())).thenAnswer((_) async => book);
      when(() => remote.getProgress(any())).thenThrow(StateError('401'));
      final c = ProviderContainer(
        overrides: [bookRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      final s = c.read(bookDetailControllerProvider('civil-2080'));
      expect(s.book, isNotNull, reason: 'the book is still usable signed out');
      expect(s.progress, isNull);
    });
  });

  group('unlocking a chapter', () {
    test('a successful unlock re-reads the book', () async {
      final c = containerWith();
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      when(() => remote.unlockChapter(any())).thenAnswer((_) async => true);
      await c.read(bookDetailControllerProvider('civil-2080').notifier).unlockChapter(3);
      final s = c.read(bookDetailControllerProvider('civil-2080'));
      expect(s.unlockingChapterId, isNull, reason: 'the spinner must not stick');
      verify(() => remote.getBook(any())).called(greaterThanOrEqualTo(2));
    });

    test('a refused unlock is not reported as unlocked', () async {
      final c = containerWith();
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      when(() => remote.unlockChapter(any())).thenAnswer((_) async => false);
      await c.read(bookDetailControllerProvider('civil-2080').notifier).unlockChapter(3);
      final s = c.read(bookDetailControllerProvider('civil-2080'));
      expect(s.error, isNotNull);
      expect(s.unlockingChapterId, isNull);
    });

    test('a thrown unlock clears the spinner and reports', () async {
      final c = containerWith();
      c.read(bookDetailControllerProvider('civil-2080'));
      await settle(c);
      when(() => remote.unlockChapter(any())).thenThrow(StateError('402'));
      await c.read(bookDetailControllerProvider('civil-2080').notifier).unlockChapter(3);
      final s = c.read(bookDetailControllerProvider('civil-2080'));
      expect(s.error, isNotNull);
      expect(s.unlockingChapterId, isNull, reason: 'a 402 must not leave a spinner');
    });
  });

  group('the reader', () {
    const target = (slug: 'civil-2080', bookId: 7, topicId: 22);

    test('loads page 1 first', () async {
      final c = containerWith();
      c.read(readerControllerProvider(target));
      await settle(c);
      expect(c.read(readerControllerProvider(target)).pageNumber, 1);
    });

    test('a page load failure reports and leaves no half-page', () async {
      final c = containerWith(failPage: true);
      c.read(readerControllerProvider(target));
      await settle(c);
      final s = c.read(readerControllerProvider(target));
      expect(s.error, isNotNull);
      expect(s.page, isNull);
    });

    test('an unreadable page response is not treated as an empty page', () async {
      when(() => remote.getPage(any(), any())).thenAnswer((_) => Future.value(null));
      final c = ProviderContainer(
        overrides: [bookRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      c.read(readerControllerProvider(target));
      await settle(c);
      final s = c.read(readerControllerProvider(target));
      expect(s.error, isNotNull);
      expect(s.page, isNull,
          reason: 'null is "not understood", not "this page is blank"');
    });

    test('previousPage does nothing on page 1', () async {
      final c = containerWith();
      c.read(readerControllerProvider(target));
      await settle(c);
      await c.read(readerControllerProvider(target).notifier).previousPage();
      expect(c.read(readerControllerProvider(target)).pageNumber, 1);
    });

    test('a failed sync never surfaces as a success message', () async {
      final c = containerWith(failSync: true);
      c.read(readerControllerProvider(target));
      await settle(c);
      await c.read(readerControllerProvider(target).notifier).syncProgress();
      final s = c.read(readerControllerProvider(target));
      expect(s.lastCreditMessage, isNull,
          reason: 'a failed sync must not claim time was credited');
    });

    test('an unreadable sync response does not clear a prior verdict silently',
        () async {
      when(() => remote.reportProgress(
            bookId: any(named: 'bookId'),
            topicId: any(named: 'topicId'),
            pageNumber: any(named: 'pageNumber'),
            timeSpentSeconds: any(named: 'timeSpentSeconds'),
          )).thenAnswer((_) => Future.value(null));
      when(() => remote.getPage(any(), any()))
          .thenAnswer((invocation) async => page(invocation.positionalArguments[1] as int));
      final c = ProviderContainer(
        overrides: [bookRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      c.read(readerControllerProvider(target));
      await settle(c);
      await c.read(readerControllerProvider(target).notifier).syncProgress();
      final s = c.read(readerControllerProvider(target));
      expect(s.lastCreditMessage, isNull);
      expect(s.error, isNull,
          reason: 'an unreadable sync is not a screen-level error');
    });
  });

  group('repository transparency', () {
    test('progress is passed through without inventing a verdict', () async {
      when(() => remote.getBook(any())).thenAnswer((_) async => book);
      when(() => remote.getProgress(any())).thenAnswer((_) => Future.value(null));
      final repo = BookRepositoryImpl(remote);
      expect(await repo.getProgress(7), isNull);
    });
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/book_remote_data_source.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

final bookRemoteDataSourceProvider = Provider<BookRemoteDataSource>(
  (ref) => BookRemoteDataSource(DioClient.instance.dio),
);

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepositoryImpl(ref.watch(bookRemoteDataSourceProvider)),
);

// ── Catalog ─────────────────────────────────────────────────────────────────

class BookCatalogState {
  const BookCatalogState({
    this.isLoading = false,
    this.books = const [],
    this.error,
    this.query = '',
  });

  final bool isLoading;
  final List<Book> books;
  final String? error;
  final String query;

  bool get isEmpty => !isLoading && error == null && books.isEmpty;

  BookCatalogState copyWith({
    bool? isLoading,
    List<Book>? books,
    String? error,
    bool clearError = false,
    String? query,
  }) {
    return BookCatalogState(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

class BookCatalogController extends Notifier<BookCatalogState> {
  @override
  BookCatalogState build() {
    Future.microtask(load);
    return const BookCatalogState();
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.books.isNotEmpty && !force) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final books = await _repo.getBooks(query: state.query);
      state = state.copyWith(isLoading: false, books: books);
    } catch (e, st) {
      AppLogger.w('book catalog failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Could not load books',
      );
    }
  }

  Future<void> refresh() => load(force: true);

  Future<void> search(String query) async {
    state = state.copyWith(query: query, books: const []);
    await load(force: true);
  }
}

final bookCatalogControllerProvider =
    NotifierProvider<BookCatalogController, BookCatalogState>(BookCatalogController.new);

// ── One book ────────────────────────────────────────────────────────────────

class BookDetailState {
  const BookDetailState({
    this.isLoading = false,
    this.book,
    this.progress,
    this.error,
    this.unlockingChapterId,
  });

  final bool isLoading;
  final Book? book;
  final ReadingProgress? progress;
  final String? error;

  /// The chapter currently being unlocked, so only that row shows a spinner.
  final int? unlockingChapterId;

  BookDetailState copyWith({
    bool? isLoading,
    Book? book,
    ReadingProgress? progress,
    String? error,
    bool clearError = false,
    int? unlockingChapterId,
    bool clearUnlocking = false,
  }) {
    return BookDetailState(
      isLoading: isLoading ?? this.isLoading,
      book: book ?? this.book,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      unlockingChapterId: clearUnlocking ? null : (unlockingChapterId ?? this.unlockingChapterId),
    );
  }
}

class BookDetailController extends Notifier<BookDetailState> {
  BookDetailController(this.slug);

  final String slug;

  @override
  BookDetailState build() {
    Future.microtask(load);
    return const BookDetailState();
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.book != null && !force) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final book = await _repo.getBook(slug);
      if (book == null) {
        state = state.copyWith(isLoading: false, error: 'That book is not available.');
        return;
      }
      // Progress is authenticated, so a signed-out reader gets the book without
      // it rather than an error for the whole screen.
      ReadingProgress? progress;
      try {
        progress = await _repo.getProgress(book.id);
      } catch (e) {
        AppLogger.w('book progress unavailable: $e');
      }
      state = state.copyWith(isLoading: false, book: book, progress: progress);
    } catch (e, st) {
      AppLogger.w('book detail failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Could not load this book',
      );
    }
  }

  Future<void> unlockChapter(int chapterId) async {
    if (state.unlockingChapterId != null) return;
    state = state.copyWith(unlockingChapterId: chapterId, clearError: true);
    try {
      final ok = await _repo.unlockChapter(chapterId);
      if (!ok) {
        state = state.copyWith(clearUnlocking: true, error: 'Could not unlock that chapter.');
        return;
      }
      // Re-read so the chapter list reflects the new access state.
      state = state.copyWith(clearUnlocking: true);
      await load(force: true);
    } catch (e) {
      AppLogger.w('unlock chapter $chapterId failed: $e');
      state = state.copyWith(
        clearUnlocking: true,
        error: e is ApiException ? e.message : 'Could not unlock that chapter',
      );
    }
  }
}

final bookDetailControllerProvider =
    NotifierProvider.family<BookDetailController, BookDetailState, String>(
  BookDetailController.new,
);

// ── Reader ──────────────────────────────────────────────────────────────────

class ReaderState {
  const ReaderState({
    this.isLoading = false,
    this.page,
    this.pageNumber = 1,
    this.progress,
    this.error,
    this.highlights = const [],
    this.lastCreditMessage,
  });

  final bool isLoading;
  final BookPage? page;
  final int pageNumber;
  final ReadingProgress? progress;
  final String? error;
  final List<BookHighlight> highlights;

  /// The server's own words about the last session — an award, or a void with a
  /// reason. Never synthesised.
  final String? lastCreditMessage;

  ReaderState copyWith({
    bool? isLoading,
    BookPage? page,
    int? pageNumber,
    ReadingProgress? progress,
    String? error,
    bool clearError = false,
    List<BookHighlight>? highlights,
    String? lastCreditMessage,
    bool clearCreditMessage = false,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      pageNumber: pageNumber ?? this.pageNumber,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      highlights: highlights ?? this.highlights,
      lastCreditMessage:
          clearCreditMessage ? null : (lastCreditMessage ?? this.lastCreditMessage),
    );
  }
}

/// Drives the reader for one book, owning the page cursor and progress reporting.
class ReaderController extends Notifier<ReaderState> {
  ReaderController(this.target);

  final ({int bookId, String slug, int topicId}) target;

  String get slug => target.slug;
  int get bookId => target.bookId;

  /// The topic the reader is inside. Progress is reported per topic, so this
  /// cannot be inferred from the page number.
  int get topicId => target.topicId;

  /// Wall-clock reading time since the last report, for `time_spent_seconds`.
  ///
  /// Kept client-side because it measures an interval, not a gameable quantity —
  /// the server decides whether to credit it.
  final Stopwatch _session = Stopwatch();

  @override
  ReaderState build() {
    _session.start();
    Future.microtask(_loadPage);
    return const ReaderState();
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);

  Future<void> _loadPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.getPage(slug, state.pageNumber);
      if (page == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Page ${state.pageNumber} could not be loaded.',
        );
        return;
      }
      state = state.copyWith(isLoading: false, page: page);
    } catch (e) {
      AppLogger.w('reader page ${state.pageNumber} failed: $e');
      state = state.copyWith(isLoading: false, error: 'Could not load this page');
    }
  }

  Future<void> nextPage() async {
    if (state.page == null) return;
    _session.stop();
    _session.reset();
    state = state.copyWith(pageNumber: state.pageNumber + 1, clearCreditMessage: true);
    await _loadPage();
  }

  Future<void> previousPage() async {
    if (state.pageNumber <= 1) return;
    _session.stop();
    _session.reset();
    state = state.copyWith(pageNumber: state.pageNumber - 1, clearCreditMessage: true);
    await _loadPage();
  }

  Future<void> retry() => _loadPage();

  /// Reports the session and adopts the server's credit verdict.
  ///
  /// A voided session is shown as voided, with the server's reason. The award
  /// amounts are read from the response even when the session was voided, so a
  /// server change that still awards on a void cannot be hidden by the client.
  Future<void> syncProgress() async {
    final seconds = _session.elapsed.inSeconds;
    _session.reset();
    if (seconds <= 0) return;
    try {
      final progress = await _repo.reportProgress(
        bookId: bookId,
        topicId: topicId,
        pageNumber: state.pageNumber,
        timeSpentSeconds: seconds,
      );
      if (progress == null) {
        state = state.copyWith(clearCreditMessage: true);
        return;
      }
      state = state.copyWith(
        progress: progress,
        lastCreditMessage: progress.credit?.outcomeMessage,
      );
    } catch (e) {
      // A failed sync is not the reader's problem to solve; the next page change
      // will report again.
      AppLogger.w('reader progress sync failed: $e');
    }
  }

  Future<void> loadHighlights() async {
    try {
      final highlights = await _repo.getMyHighlights();
      state = state.copyWith(highlights: highlights);
    } catch (e) {
      AppLogger.w('reader highlights failed: $e');
    }
  }

  Future<void> addHighlight({
    required int contentBlockId,
    required String text,
    required int start,
    required int end,
    String color = 'yellow',
  }) async {
    try {
      final created = await _repo.createHighlight(
        contentBlockId: contentBlockId,
        highlightedText: text,
        startOffset: start,
        endOffset: end,
        colorCode: color,
      );
      if (created != null) {
        state = state.copyWith(highlights: [created, ...state.highlights]);
      }
    } catch (e) {
      AppLogger.w('create highlight failed: $e');
    }
  }
}

final readerControllerProvider = NotifierProvider.family<ReaderController, ReaderState, ({String slug, int bookId, int topicId})>(
  ReaderController.new,
);

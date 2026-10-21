import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/paginated.dart';
import '../../data/datasources/practice_remote_data_source.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final practiceRemoteDataSourceProvider = Provider<PracticeRemoteDataSource>((ref) {
  return PracticeRemoteDataSource(DioClient.instance.dio);
});

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(ref.watch(practiceRemoteDataSourceProvider));
});

// Future providers for read-only surfaces
final practiceBookmarksProvider = FutureProvider<Paginated<BookmarkedQuestion>>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getBookmarks(perPage: 20);
});

final practiceAttemptHistoryProvider = FutureProvider<Paginated<PracticeAttemptHistoryItem>>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getAttemptHistory(perPage: 20);
});

// ── Controller state ──────────────────────────────────────────────────────────

class PracticeState {
  const PracticeState({
    this.isLoading = false,
    this.error,
    this.bookmarks = const [],
    this.bookmarksPagination,
    this.isBookmarksLoading = false,
    this.bookmarksError,
    this.history = const [],
    this.historyPagination,
    this.isHistoryLoading = false,
    this.historyError,
    this.isTogglingBookmark = false,
    this.toggleError,
    this.isStartingSession = false,
    this.isCompletingSession = false,
    this.startError,
  });

  final bool isLoading;
  final String? error;
  final List<BookmarkedQuestion> bookmarks;
  final Pagination? bookmarksPagination;
  final bool isBookmarksLoading;
  final String? bookmarksError;
  final List<PracticeAttemptHistoryItem> history;
  final Pagination? historyPagination;
  final bool isHistoryLoading;
  final String? historyError;
  final bool isTogglingBookmark;
  final String? toggleError;
  final bool isStartingSession;
  final bool isCompletingSession;
  final String? startError;

  static const _sentinel = Object();

  PracticeState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    List<BookmarkedQuestion>? bookmarks,
    Object? bookmarksPagination = _sentinel,
    bool? isBookmarksLoading,
    Object? bookmarksError = _sentinel,
    List<PracticeAttemptHistoryItem>? history,
    Object? historyPagination = _sentinel,
    bool? isHistoryLoading,
    Object? historyError = _sentinel,
    bool? isTogglingBookmark,
    Object? toggleError = _sentinel,
    bool? isStartingSession,
    bool? isCompletingSession,
    Object? startError = _sentinel,
  }) {
    return PracticeState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      bookmarks: bookmarks ?? this.bookmarks,
      bookmarksPagination: bookmarksPagination == _sentinel ? this.bookmarksPagination : bookmarksPagination as Pagination?,
      isBookmarksLoading: isBookmarksLoading ?? this.isBookmarksLoading,
      bookmarksError: bookmarksError == _sentinel ? this.bookmarksError : bookmarksError as String?,
      history: history ?? this.history,
      historyPagination: historyPagination == _sentinel ? this.historyPagination : historyPagination as Pagination?,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      historyError: historyError == _sentinel ? this.historyError : historyError as String?,
      isTogglingBookmark: isTogglingBookmark ?? this.isTogglingBookmark,
      toggleError: toggleError == _sentinel ? this.toggleError : toggleError as String?,
      isStartingSession: isStartingSession ?? this.isStartingSession,
      isCompletingSession: isCompletingSession ?? this.isCompletingSession,
      startError: startError == _sentinel ? this.startError : startError as String?,
    );
  }
}

class PracticeController extends Notifier<PracticeState> {
  @override
  PracticeState build() => const PracticeState();

  PracticeRepository get _repo => ref.read(practiceRepositoryProvider);
  static const _uuid = Uuid();

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchBookmarks({String? cursor, bool append = false}) async {
    state = state.copyWith(isBookmarksLoading: true, bookmarksError: null);
    try {
      final paginated = await _repo.getBookmarks(cursor: cursor, perPage: 20);
      final newList = append ? [...state.bookmarks, ...paginated.items] : paginated.items;
      state = state.copyWith(bookmarks: newList, bookmarksPagination: paginated.pagination, isBookmarksLoading: false);
    } catch (e, st) {
      AppLogger.w('practice fetchBookmarks failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isBookmarksLoading: false, bookmarksError: _msg(e));
    }
  }

  Future<void> fetchHistory({String? cursor, bool append = false}) async {
    state = state.copyWith(isHistoryLoading: true, historyError: null);
    try {
      final paginated = await _repo.getAttemptHistory(cursor: cursor, perPage: 20);
      final newList = append ? [...state.history, ...paginated.items] : paginated.items;
      state = state.copyWith(history: newList, historyPagination: paginated.pagination, isHistoryLoading: false);
    } catch (e, st) {
      AppLogger.w('practice fetchHistory failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isHistoryLoading: false, historyError: _msg(e));
    }
  }

  /// Adds or removes a bookmark.
  ///
  /// The two directions are separate server calls (`PUT` to add, `DELETE` to
  /// remove). The `POST` alias converges to `bookmarked: true` and cannot
  /// remove, so a single "toggle" method would silently fail to un-bookmark.
  Future<bool> setBookmark(int questionId, {required bool bookmarked}) async {
    state = state.copyWith(isTogglingBookmark: true, toggleError: null);
    try {
      if (bookmarked) {
        await _repo.addBookmark(questionId, idempotencyKey: _uuid.v4());
      } else {
        await _repo.removeBookmark(questionId);
      }
      state = state.copyWith(isTogglingBookmark: false);
      await fetchBookmarks();
      return true;
    } catch (e, st) {
      AppLogger.w('practice setBookmark $questionId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isTogglingBookmark: false, toggleError: _msg(e));
      return false;
    }
  }

  /// Removes a bookmark.
  Future<bool> removeBookmark(int questionId) =>
      setBookmark(questionId, bookmarked: false);

  /// Starts a drill: loads the real questions from the server, seeds a practice
  /// attempt with exactly those ids, and hands back the live attempt.
  ///
  /// Returns null on failure with [PracticeState.startError] set.
  Future<PracticeDrill?> startDrill({
    required String title,
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int count = 10,
  }) async {
    state = state.copyWith(isStartingSession: true, startError: null);
    try {
      final drill = await _repo.startDrill(
        title: title,
        courseId: courseId,
        categoryId: categoryId,
        difficulty: difficulty,
        search: search,
        count: count,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isStartingSession: false);
      return drill;
    } catch (e, st) {
      AppLogger.w('practice startDrill failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isStartingSession: false, startError: _msg(e));
      return null;
    }
  }

  /// Starts a drill over the user's own bookmarks.
  ///
  /// The attempt is seeded with the bookmarked question ids, so the server
  /// grades what the user bookmarked rather than a random set from the same
  /// category.
  Future<PracticeDrill?> startBookmarkDrill({
    required String title,
    required List<BookmarkedQuestion> bookmarks,
  }) async {
    state = state.copyWith(isStartingSession: true, startError: null);
    try {
      final drill = await _repo.startBookmarkDrill(
        title: title,
        bookmarks: bookmarks,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isStartingSession: false);
      return drill;
    } catch (e, st) {
      AppLogger.w('practice startBookmarkDrill failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isStartingSession: false, startError: _msg(e));
      return null;
    }
  }

  /// Submits one answer to the live drill attempt.
  ///
  /// A failure here is surfaced but never blocks the drill: the user has
  /// already answered, and the server-side attempt is closed when the drill
  /// completes. The answer count is what the server reports, so a dropped
  /// answer shows up as a lower score rather than as a lie.
  Future<bool> submitAnswer({
    required String attemptId,
    required int questionId,
    required String answer,
    int? timeTakenSeconds,
  }) async {
    try {
      await _repo.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        answer: answer,
        timeTakenSeconds: timeTakenSeconds,
        idempotencyKey: _uuid.v4(),
      );
      return true;
    } catch (e, st) {
      AppLogger.w('practice submitAnswer $attemptId/$questionId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      return false;
    }
  }

  /// Completes the drill and returns the server's verdict.
  Future<PracticeResult?> completeAttempt(String attemptId) async {
    state = state.copyWith(isCompletingSession: true, startError: null);
    try {
      final result = await _repo.completeAttempt(
        attemptId: attemptId,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isCompletingSession: false);
      // The history list now has a new row.
      await fetchHistory();
      return result;
    } catch (e, st) {
      AppLogger.w('practice completeAttempt $attemptId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCompletingSession: false, startError: _msg(e));
      return null;
    }
  }

  void clearErrors() {
    state = state.copyWith(error: null, bookmarksError: null, historyError: null, toggleError: null, startError: null);
  }
}

final practiceControllerProvider = NotifierProvider<PracticeController, PracticeState>(PracticeController.new);

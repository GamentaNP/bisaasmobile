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
  return repo.getAttemptHistory(page: 1, perPage: 20);
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

  Future<void> fetchHistory({int page = 1, bool append = false}) async {
    state = state.copyWith(isHistoryLoading: true, historyError: null);
    try {
      final paginated = await _repo.getAttemptHistory(page: page, perPage: 20);
      final newList = append ? [...state.history, ...paginated.items] : paginated.items;
      state = state.copyWith(history: newList, historyPagination: paginated.pagination, isHistoryLoading: false);
    } catch (e, st) {
      AppLogger.w('practice fetchHistory failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isHistoryLoading: false, historyError: _msg(e));
    }
  }

  Future<bool> toggleBookmark(int questionId) async {
    state = state.copyWith(isTogglingBookmark: true, toggleError: null);
    try {
      await _repo.toggleBookmark(questionId, idempotencyKey: _uuid.v4());
      state = state.copyWith(isTogglingBookmark: false);
      // Refresh bookmarks
      await fetchBookmarks();
      return true;
    } catch (e, st) {
      AppLogger.w('practice toggleBookmark $questionId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isTogglingBookmark: false, toggleError: _msg(e));
      return false;
    }
  }

  Future<String?> startSession({
    List<int>? questionIds,
    int? topicId,
    int? categoryId,
    int? courseId,
    int questionCount = 10,
  }) async {
    state = state.copyWith(isStartingSession: true, startError: null);
    try {
      final attemptId = await _repo.startPracticeAttempt(
        questionIds: questionIds,
        topicId: topicId,
        categoryId: categoryId,
        courseId: courseId,
        questionCount: questionCount,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isStartingSession: false);
      return attemptId;
    } catch (e, st) {
      AppLogger.w('practice startSession failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isStartingSession: false, startError: _msg(e));
      return null;
    }
  }

  void clearErrors() {
    state = state.copyWith(error: null, bookmarksError: null, historyError: null, toggleError: null, startError: null);
  }
}

final practiceControllerProvider = NotifierProvider<PracticeController, PracticeState>(PracticeController.new);

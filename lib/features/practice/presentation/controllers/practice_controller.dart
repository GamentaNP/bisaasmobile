import 'package:bisaasmobile/shared/utils/debug_stack.dart';
import 'package:bisaasmobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../../../../app/providers.dart';
import '../../../../app/localization/l10n.dart';
import '../../../../shared/domain/paginated.dart';
import '../../data/datasources/practice_remote_data_source.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final practiceRemoteDataSourceProvider = Provider<PracticeRemoteDataSource>((ref) {
  return PracticeRemoteDataSource(ref.watch(dioProvider));
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
  PracticeRemoteDataSource get _remote => ref.read(practiceRemoteDataSourceProvider);
  static const _uuid = Uuid();

  /// One key per logical drill start. The screen retries by calling
  /// `startDrill` again with the same intent, so the key must not be re-minted
  /// on that second call.
  final Map<String, String> _drillKeys = <String, String>{};

  /// Answer writes are keyed per (attempt, question) so a retry cannot consume
  /// a second question on the server.
  final Map<String, String> _answerKeys = <String, String>{};

  /// Completion credits the server's score; the key is stable per attempt and
  /// the cached verdict is replayed when the write reports a conflict.
  final Map<String, PracticeResult> _completionResults = <String, PracticeResult>{};

  Future<void> fetchBookmarks({String? cursor, bool append = false}) async {
    state = state.copyWith(isBookmarksLoading: true, bookmarksError: null);
    try {
      final paginated = await _repo.getBookmarks(cursor: cursor, perPage: 20);
      final newList = append ? [...state.bookmarks, ...paginated.items] : paginated.items;
      state = state.copyWith(bookmarks: newList, bookmarksPagination: paginated.pagination, isBookmarksLoading: false);
    } catch (e, st) {
      AppLogger.w('practice fetchBookmarks failed: $e');
      debugStack(st);
      state = state.copyWith(isBookmarksLoading: false, bookmarksError: errorMessage(e));
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
      debugStack(st);
      state = state.copyWith(isHistoryLoading: false, historyError: errorMessage(e));
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
      debugStack(st);
      state = state.copyWith(isTogglingBookmark: false, toggleError: errorMessage(e));
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
    int? topicId,
    String? difficulty,
    String? search,
    int count = 10,
  }) async {
    state = state.copyWith(isStartingSession: true, startError: null);
    final intent = '$title|$courseId|$categoryId|$topicId|$difficulty|$search|$count';
    final key = _drillKeys.putIfAbsent(intent, () => 'practice-start-${_uuid.v4()}');
    try {
      late final PracticeDrill drill;
      if (topicId != null) {
        // `topic_id` is a server filter on GET /quiz/questions now. The
        // repository does not expose it yet, so the scoped read and the seed
        // go through this feature's own data source until that interface can
        // be widened.
        final questions = await _remote.getQuestions(
          courseId: courseId,
          categoryId: categoryId,
          topicId: topicId,
          difficulty: difficulty,
          search: search,
          limit: count,
        );
        if (questions.isEmpty) {
          throw PracticeDrillException(appL10n().quizEmptySession);
        }
        final start = await _remote.startPracticeAttempt(
          questionIds: questions.map((q) => q.id).toList(),
          idempotencyKey: key,
        );
        drill = PracticeDrill(
          attemptId: start.attemptId,
          title: title,
          questions: questions.map((q) => q.toDomain()).toList(),
        );
      } else {
        drill = await _repo.startDrill(
          title: title,
          courseId: courseId,
          categoryId: categoryId,
          difficulty: difficulty,
          search: search,
          count: count,
          idempotencyKey: key,
        );
      }
      _drillKeys.remove(intent);
      state = state.copyWith(isStartingSession: false);
      return drill;
    } catch (e, st) {
      AppLogger.w('practice startDrill failed: $e');
      debugStack(st);
      state = state.copyWith(isStartingSession: false, startError: errorMessage(e));
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
      debugStack(st);
      state = state.copyWith(isStartingSession: false, startError: errorMessage(e));
      return null;
    }
  }

  /// Submits one answer to the live drill attempt.
  ///
  /// A failure is **thrown**, never swallowed: the screen must keep the
  /// selection in an unsent state and offer a retry. A dropped answer is not
  /// something to narrate as "answer sent".
  Future<void> submitAnswer({
    required String attemptId,
    required int questionId,
    required String answer,
    int? timeTakenSeconds,
  }) async {
    final logicalKey = '$attemptId:$questionId';
    final idempotencyKey = _answerKeys.putIfAbsent(
      logicalKey,
      () => 'practice-answer-$attemptId-$questionId-${_uuid.v4()}',
    );
    try {
      await _repo.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        answer: answer,
        timeTakenSeconds: timeTakenSeconds,
        idempotencyKey: idempotencyKey,
      );
    } catch (e, st) {
      // A keyed replay/409 means the server already stored this answer, so it
      // is not a failure and must not be shown as one.
      if (_isIdempotentReplay(e)) return;
      AppLogger.w('practice submitAnswer $attemptId/$questionId failed: $e');
      debugStack(st);
      state = state.copyWith(error: errorMessage(e));
      rethrow;
    }
  }

  /// Completes the drill and returns the server's verdict.
  ///
  /// The key is derived from the attempt, so the retry a failed completion
  /// offers is a replay of the same write, never a second completion.
  Future<PracticeResult?> completeAttempt(String attemptId) async {
    state = state.copyWith(isCompletingSession: true, startError: null);
    try {
      final result = await _repo.completeAttempt(
        attemptId: attemptId,
        idempotencyKey: 'practice-complete-$attemptId',
      );
      _completionResults[attemptId] = result;
      state = state.copyWith(isCompletingSession: false);
      // The history list now has a new row.
      await fetchHistory();
      return result;
    } catch (e, st) {
      if (_completionResults[attemptId] != null && _isIdempotentReplay(e)) {
        state = state.copyWith(isCompletingSession: false);
        return _completionResults[attemptId];
      }
      AppLogger.w('practice completeAttempt $attemptId failed: $e');
      debugStack(st);
      state = state.copyWith(isCompletingSession: false, startError: errorMessage(e));
      return null;
    }
  }

  /// Rebuilds an interrupted drill from the server's attempt snapshot.
  /// Questions already answered are left on the server; the client resumes at
  /// the first question with no answer and never guesses a score.
  Future<PracticeDrill?> resumeDrill(String attemptId) async {
    state = state.copyWith(isStartingSession: true, startError: null);
    try {
      final payload = await _remote.fetchAttempt(attemptId);
      if (payload.questions.isEmpty) {
        throw PracticeDrillException(appL10n().quizEmptySession);
      }
      final drill = PracticeDrill(
        attemptId: attemptId,
        title: appL10n().practiceDrill,
        questions: payload.questions.map((q) => q.toDomain()).toList(),
        undrillableCount: payload.rows.length - payload.questions.length,
      );
      state = state.copyWith(isStartingSession: false);
      return drill;
    } catch (e, st) {
      AppLogger.w('practice resumeDrill $attemptId failed: $e');
      debugStack(st);
      state = state.copyWith(isStartingSession: false, startError: errorMessage(e));
      return null;
    }
  }

  bool _isIdempotentReplay(Object error) =>
      toApiException(error).code == ApiErrorCode.idempotencyConflict;

  void clearErrors() {
    state = state.copyWith(error: null, bookmarksError: null, historyError: null, toggleError: null, startError: null);
  }
}

final practiceControllerProvider = NotifierProvider<PracticeController, PracticeState>(PracticeController.new);

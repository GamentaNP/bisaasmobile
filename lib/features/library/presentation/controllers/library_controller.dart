import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/library.dart';
import '../../domain/repositories/library_repository.dart';
import '../../../../core/network/api_response.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>((ref) {
  return LibraryRemoteDataSource(DioClient.instance.dio);
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(ref.watch(libraryRemoteDataSourceProvider));
});

// ── State ───────────────────────────────────────────────────────────────────

class LibraryState {
  const LibraryState({
    this.isLoading = false,
    this.error,
    this.categories = const [],
    this.isCategoriesLoading = false,
    this.categoriesError,
    this.files = const [],
    this.filesPagination,
    this.isFilesLoading = false,
    this.filesError,
    this.selectedFile,
    this.isFileLoading = false,
    this.fileError,
    this.reviews = const [],
    this.reviewsPagination,
    this.isReviewsLoading = false,
    this.reviewsError,
    this.trending = const [],
    this.isTrendingLoading = false,
    this.trendingError,
    this.recommendations = const [],
    this.isRecommendationsLoading = false,
    this.recommendationsError,
    this.myUnlocks = const [],
    this.isMyUnlocksLoading = false,
    this.myUnlocksError,
    this.isUnlocking = false,
    this.unlockError,
    this.lastUnlockResult,
    this.isDownloading = false,
    this.downloadUrl,
    this.downloadError,
    this.isSubmittingReview = false,
    this.submitReviewError,
    // filters
    this.currentQuery = '',
    this.selectedCategoryId,
  });

  final bool isLoading;
  final String? error;

  final List<LibraryCategory> categories;
  final bool isCategoriesLoading;
  final String? categoriesError;

  final List<LibraryFile> files;
  final Pagination? filesPagination;
  final bool isFilesLoading;
  final String? filesError;

  final LibraryFile? selectedFile;
  final bool isFileLoading;
  final String? fileError;

  final List<LibraryReview> reviews;
  final Pagination? reviewsPagination;
  final bool isReviewsLoading;
  final String? reviewsError;

  final List<LibraryFile> trending;
  final bool isTrendingLoading;
  final String? trendingError;

  final List<LibraryFile> recommendations;
  final bool isRecommendationsLoading;
  final String? recommendationsError;

  final List<LibraryUnlockItem> myUnlocks;
  final bool isMyUnlocksLoading;
  final String? myUnlocksError;

  final bool isUnlocking;
  final String? unlockError;
  final LibraryUnlockResult? lastUnlockResult;

  final bool isDownloading;
  final String? downloadUrl;
  final String? downloadError;

  final bool isSubmittingReview;
  final String? submitReviewError;

  final String currentQuery;
  final int? selectedCategoryId;

  static const _sentinel = Object();

  LibraryState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    List<LibraryCategory>? categories,
    bool? isCategoriesLoading,
    Object? categoriesError = _sentinel,
    List<LibraryFile>? files,
    Object? filesPagination = _sentinel,
    bool? isFilesLoading,
    Object? filesError = _sentinel,
    Object? selectedFile = _sentinel,
    bool? isFileLoading,
    Object? fileError = _sentinel,
    List<LibraryReview>? reviews,
    Object? reviewsPagination = _sentinel,
    bool? isReviewsLoading,
    Object? reviewsError = _sentinel,
    List<LibraryFile>? trending,
    bool? isTrendingLoading,
    Object? trendingError = _sentinel,
    List<LibraryFile>? recommendations,
    bool? isRecommendationsLoading,
    Object? recommendationsError = _sentinel,
    List<LibraryUnlockItem>? myUnlocks,
    bool? isMyUnlocksLoading,
    Object? myUnlocksError = _sentinel,
    bool? isUnlocking,
    Object? unlockError = _sentinel,
    Object? lastUnlockResult = _sentinel,
    bool? isDownloading,
    Object? downloadUrl = _sentinel,
    Object? downloadError = _sentinel,
    bool? isSubmittingReview,
    Object? submitReviewError = _sentinel,
    String? currentQuery,
    Object? selectedCategoryId = _sentinel,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      categories: categories ?? this.categories,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      categoriesError: categoriesError == _sentinel ? this.categoriesError : categoriesError as String?,
      files: files ?? this.files,
      filesPagination: filesPagination == _sentinel ? this.filesPagination : filesPagination as Pagination?,
      isFilesLoading: isFilesLoading ?? this.isFilesLoading,
      filesError: filesError == _sentinel ? this.filesError : filesError as String?,
      selectedFile: selectedFile == _sentinel ? this.selectedFile : selectedFile as LibraryFile?,
      isFileLoading: isFileLoading ?? this.isFileLoading,
      fileError: fileError == _sentinel ? this.fileError : fileError as String?,
      reviews: reviews ?? this.reviews,
      reviewsPagination: reviewsPagination == _sentinel ? this.reviewsPagination : reviewsPagination as Pagination?,
      isReviewsLoading: isReviewsLoading ?? this.isReviewsLoading,
      reviewsError: reviewsError == _sentinel ? this.reviewsError : reviewsError as String?,
      trending: trending ?? this.trending,
      isTrendingLoading: isTrendingLoading ?? this.isTrendingLoading,
      trendingError: trendingError == _sentinel ? this.trendingError : trendingError as String?,
      recommendations: recommendations ?? this.recommendations,
      isRecommendationsLoading: isRecommendationsLoading ?? this.isRecommendationsLoading,
      recommendationsError: recommendationsError == _sentinel ? this.recommendationsError : recommendationsError as String?,
      myUnlocks: myUnlocks ?? this.myUnlocks,
      isMyUnlocksLoading: isMyUnlocksLoading ?? this.isMyUnlocksLoading,
      myUnlocksError: myUnlocksError == _sentinel ? this.myUnlocksError : myUnlocksError as String?,
      isUnlocking: isUnlocking ?? this.isUnlocking,
      unlockError: unlockError == _sentinel ? this.unlockError : unlockError as String?,
      lastUnlockResult: lastUnlockResult == _sentinel ? this.lastUnlockResult : lastUnlockResult as LibraryUnlockResult?,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadUrl: downloadUrl == _sentinel ? this.downloadUrl : downloadUrl as String?,
      downloadError: downloadError == _sentinel ? this.downloadError : downloadError as String?,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      submitReviewError: submitReviewError == _sentinel ? this.submitReviewError : submitReviewError as String?,
      currentQuery: currentQuery ?? this.currentQuery,
      selectedCategoryId: selectedCategoryId == _sentinel ? this.selectedCategoryId : selectedCategoryId as int?,
    );
  }

  // For preserving selectedFile when nulling errors
  LibraryState clearSelectedFile() => LibraryState(
        isLoading: isLoading,
        error: error,
        categories: categories,
        isCategoriesLoading: isCategoriesLoading,
        categoriesError: categoriesError,
        files: files,
        filesPagination: filesPagination,
        isFilesLoading: isFilesLoading,
        filesError: filesError,
        selectedFile: null,
        isFileLoading: isFileLoading,
        fileError: null,
        reviews: reviews,
        reviewsPagination: reviewsPagination,
        isReviewsLoading: isReviewsLoading,
        reviewsError: reviewsError,
        trending: trending,
        isTrendingLoading: isTrendingLoading,
        trendingError: trendingError,
        recommendations: recommendations,
        isRecommendationsLoading: isRecommendationsLoading,
        recommendationsError: recommendationsError,
        myUnlocks: myUnlocks,
        isMyUnlocksLoading: isMyUnlocksLoading,
        myUnlocksError: myUnlocksError,
        isUnlocking: isUnlocking,
        unlockError: unlockError,
        lastUnlockResult: lastUnlockResult,
        isDownloading: isDownloading,
        downloadUrl: downloadUrl,
        downloadError: downloadError,
        isSubmittingReview: isSubmittingReview,
        submitReviewError: submitReviewError,
        currentQuery: currentQuery,
        selectedCategoryId: selectedCategoryId,
      );
}

// ── Controller ──────────────────────────────────────────────────────────────

class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() => const LibraryState();

  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  String _msg(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  // ── Categories ──────────────────────────────────────────────────────────

  Future<void> fetchCategories() async {
    state = state.copyWith(isCategoriesLoading: true, categoriesError: null);
    try {
      final cats = await _repo.getCategories();
      state = state.copyWith(categories: cats, isCategoriesLoading: false);
    } catch (e, st) {
      AppLogger.w('library fetchCategories failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCategoriesLoading: false, categoriesError: _msg(e));
    }
  }

  // ── Files (with filters) ────────────────────────────────────────────────

  Future<void> fetchFiles({
    String? query,
    int? categoryId,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    int page = 1,
    int perPage = 20,
    bool append = false,
  }) async {
    // Keep current filters if not overridden
    final q = query ?? state.currentQuery;
    final cat = categoryId ?? state.selectedCategoryId;
    state = state.copyWith(
      isFilesLoading: true,
      filesError: null,
      currentQuery: q,
      selectedCategoryId: cat,
    );
    try {
      final paginated = await _repo.getFiles(
        categoryId: cat,
        query: q.isEmpty ? null : q,
        fileType: fileType,
        visibility: visibility,
        minRating: minRating,
        maxCost: maxCost,
        page: page,
        perPage: perPage,
      );
      final newFiles = append ? [...state.files, ...paginated.items] : paginated.items;
      state = state.copyWith(
        files: newFiles,
        filesPagination: paginated.pagination,
        isFilesLoading: false,
      );
    } catch (e, st) {
      AppLogger.w('library fetchFiles failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFilesLoading: false, filesError: _msg(e));
    }
  }

  Future<void> refreshFiles() => fetchFiles(page: 1, perPage: 20);

  // ── File detail ─────────────────────────────────────────────────────────

  Future<void> fetchFile(String slug) async {
    state = state.copyWith(isFileLoading: true, fileError: null);
    try {
      final file = await _repo.getFile(slug);
      state = state.copyWith(selectedFile: file, isFileLoading: false);
    } catch (e, st) {
      AppLogger.w('library fetchFile $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFileLoading: false, fileError: _msg(e));
    }
  }

  // ── Unlock ──────────────────────────────────────────────────────────────

  Future<LibraryUnlockResult?> unlock(String slug) async {
    state = state.copyWith(isUnlocking: true, unlockError: null);
    try {
      final result = await _repo.unlock(slug);
      state = state.copyWith(isUnlocking: false, lastUnlockResult: result);
      // After unlock, refresh file detail to reflect maybe isUnlocked
      try {
        await fetchFile(slug);
      } catch (_) {}
      return result;
    } catch (e, st) {
      AppLogger.w('library unlock $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isUnlocking: false, unlockError: _msg(e));
      return null;
    }
  }

  // ── Download ────────────────────────────────────────────────────────────

  Future<String?> download(String slug) async {
    state = state.copyWith(isDownloading: true, downloadError: null, downloadUrl: null);
    try {
      final url = await _repo.getDownloadUrl(slug);
      state = state.copyWith(isDownloading: false, downloadUrl: url);
      return url;
    } catch (e, st) {
      AppLogger.w('library download $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isDownloading: false, downloadError: _msg(e));
      return null;
    }
  }

  void clearDownload() {
    state = state.copyWith(downloadUrl: null, downloadError: null);
  }

  // ── Reviews ─────────────────────────────────────────────────────────────

  Future<void> fetchReviews(String slug, {int page = 1, int perPage = 15, bool append = false}) async {
    state = state.copyWith(isReviewsLoading: true, reviewsError: null);
    try {
      final paginated = await _repo.getReviews(slug, page: page, perPage: perPage);
      final newReviews = append ? [...state.reviews, ...paginated.items] : paginated.items;
      state = state.copyWith(
        reviews: newReviews,
        reviewsPagination: paginated.pagination,
        isReviewsLoading: false,
      );
    } catch (e, st) {
      AppLogger.w('library fetchReviews $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isReviewsLoading: false, reviewsError: _msg(e));
    }
  }

  Future<LibraryReview?> submitReview(String slug, {required int rating, String? comment}) async {
    state = state.copyWith(isSubmittingReview: true, submitReviewError: null);
    try {
      final review = await _repo.submitReview(slug, rating: rating, comment: comment);
      state = state.copyWith(isSubmittingReview: false);
      // Refresh reviews after submit
      await fetchReviews(slug, page: 1);
      // Also refresh file to update rating counts
      try {
        await fetchFile(slug);
      } catch (_) {}
      return review;
    } catch (e, st) {
      AppLogger.w('library submitReview $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isSubmittingReview: false, submitReviewError: _msg(e));
      return null;
    }
  }

  // ── Trending ────────────────────────────────────────────────────────────

  Future<void> trending() async {
    state = state.copyWith(isTrendingLoading: true, trendingError: null);
    try {
      final items = await _repo.getTrending();
      state = state.copyWith(trending: items, isTrendingLoading: false);
    } catch (e, st) {
      AppLogger.w('library trending failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isTrendingLoading: false, trendingError: _msg(e));
    }
  }

  // Alias per spec (fetchTrending vs trending) — both work
  Future<void> fetchTrending() => trending();

  // ── Recommendations ─────────────────────────────────────────────────────

  Future<void> recommendations() async {
    state = state.copyWith(isRecommendationsLoading: true, recommendationsError: null);
    try {
      final items = await _repo.getRecommendations();
      state = state.copyWith(recommendations: items, isRecommendationsLoading: false);
    } catch (e, st) {
      AppLogger.w('library recommendations failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isRecommendationsLoading: false, recommendationsError: _msg(e));
    }
  }

  Future<void> fetchRecommendations() => recommendations();

  // ── My unlocks ──────────────────────────────────────────────────────────

  Future<void> fetchMyUnlocks({int page = 1, int perPage = 20, bool append = false}) async {
    state = state.copyWith(isMyUnlocksLoading: true, myUnlocksError: null);
    try {
      final paginated = await _repo.getMyUnlocks(page: page, perPage: perPage);
      final newItems = append ? [...state.myUnlocks, ...paginated.items] : paginated.items;
      state = state.copyWith(myUnlocks: newItems, isMyUnlocksLoading: false);
    } catch (e, st) {
      AppLogger.w('library fetchMyUnlocks failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isMyUnlocksLoading: false, myUnlocksError: _msg(e));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void setQuery(String query) {
    state = state.copyWith(currentQuery: query);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void clearErrors() {
    state = state.copyWith(
      error: null,
      categoriesError: null,
      filesError: null,
      fileError: null,
      reviewsError: null,
      trendingError: null,
      recommendationsError: null,
      unlockError: null,
      downloadError: null,
      submitReviewError: null,
    );
  }
}

final libraryControllerProvider = NotifierProvider<LibraryController, LibraryState>(LibraryController.new);

// Convenience future providers for read-only surfaces (optional)
final libraryCategoriesProvider = FutureProvider<List<LibraryCategory>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getCategories();
});

final libraryTrendingProvider = FutureProvider<List<LibraryFile>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getTrending();
});

final libraryRecommendationsProvider = FutureProvider<List<LibraryFile>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getRecommendations();
});

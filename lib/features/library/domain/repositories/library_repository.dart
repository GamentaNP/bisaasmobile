import 'package:bisaasmobile/shared/domain/paginated.dart';

import '../entities/library.dart';

abstract class LibraryRepository {
  Future<List<LibraryCategory>> getCategories();

  /// Cursor-paginated file list — filters are additive, all optional.
  /// Returns items + pagination so callers can render "load more".
  ///
  /// The endpoint is cursor-paginated (`MOBILE_API_INTEGRATION_GUIDE.md` §4.1),
  /// so the caller passes back the `next_cursor` it was given rather than a
  /// page number.
  Future<Paginated<LibraryFile>> getFiles({
    int? categoryId,
    String? query,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    String? cursor,
    int perPage,
  });

  Future<LibraryFile> getFile(String slug);

  /// Unlock costs coins. Uses Idempotency-Key internally.
  Future<LibraryUnlockResult> unlock(String slug);

  /// Returns a signed, short-lived download URL. Must be unlocked first (403 otherwise).
  Future<String> getDownloadUrl(String slug);

  Future<Paginated<LibraryReview>> getReviews(String slug, {int page, int perPage});

  Future<LibraryReview> submitReview(String slug, {required int rating, String? comment});

  Future<Paginated<LibraryUnlockItem>> getMyUnlocks({int page, int perPage});

  Future<List<LibraryFile>> getTrending();

  Future<List<LibraryFile>> getRecommendations();
}

import '../entities/library.dart';
import '../repositories/library_repository.dart';

/// Reduced tier: thin wrappers over repository for testability.
/// Each use case is a single public method; no business logic beyond mapping,
/// because library is read-mostly (no money/grading mutations beyond unlock/download).
class GetLibraryCategories {
  const GetLibraryCategories(this._repo);
  final LibraryRepository _repo;
  Future<List<LibraryCategory>> call() => _repo.getCategories();
}

class GetLibraryFiles {
  const GetLibraryFiles(this._repo);
  final LibraryRepository _repo;
  Future<dynamic> call({
    int? categoryId,
    String? query,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getFiles(
        categoryId: categoryId,
        query: query,
        fileType: fileType,
        visibility: visibility,
        minRating: minRating,
        maxCost: maxCost,
        page: page,
        perPage: perPage,
      );
}

class GetLibraryFile {
  const GetLibraryFile(this._repo);
  final LibraryRepository _repo;
  Future<LibraryFile> call(String slug) => _repo.getFile(slug);
}

class UnlockLibraryFile {
  const UnlockLibraryFile(this._repo);
  final LibraryRepository _repo;
  Future<LibraryUnlockResult> call(String slug) => _repo.unlock(slug);
}

class GetLibraryDownloadUrl {
  const GetLibraryDownloadUrl(this._repo);
  final LibraryRepository _repo;
  Future<String> call(String slug) => _repo.getDownloadUrl(slug);
}

class GetLibraryReviews {
  const GetLibraryReviews(this._repo);
  final LibraryRepository _repo;
  Future<dynamic> call(String slug, {int page = 1, int perPage = 15}) => _repo.getReviews(slug, page: page, perPage: perPage);
}

class SubmitLibraryReview {
  const SubmitLibraryReview(this._repo);
  final LibraryRepository _repo;
  Future<LibraryReview> call(String slug, {required int rating, String? comment}) =>
      _repo.submitReview(slug, rating: rating, comment: comment);
}

class GetTrendingFiles {
  const GetTrendingFiles(this._repo);
  final LibraryRepository _repo;
  Future<List<LibraryFile>> call() => _repo.getTrending();
}

class GetRecommendations {
  const GetRecommendations(this._repo);
  final LibraryRepository _repo;
  Future<List<LibraryFile>> call() => _repo.getRecommendations();
}

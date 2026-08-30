import 'package:bisaasmobile/shared/domain/paginated.dart';
import '../../domain/entities/library.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._remote);
  final LibraryRemoteDataSource _remote;

  @override
  Future<List<LibraryCategory>> getCategories() async {
    final dtos = await _remote.getCategories();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Paginated<LibraryFile>> getFiles({
    int? categoryId,
    String? query,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _remote.getFiles(
      categoryId: categoryId,
      query: query,
      fileType: fileType,
      visibility: visibility,
      minRating: minRating,
      maxCost: maxCost,
      page: page,
      perPage: perPage,
    );
    return Paginated<LibraryFile>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<LibraryFile> getFile(String slug) async {
    final dto = await _remote.getFile(slug);
    return dto.toDomain();
  }

  @override
  Future<LibraryUnlockResult> unlock(String slug) async {
    final dto = await _remote.unlock(slug);
    return dto.toDomain();
  }

  @override
  Future<String> getDownloadUrl(String slug) => _remote.getDownloadUrl(slug);

  @override
  Future<Paginated<LibraryReview>> getReviews(String slug, {int page = 1, int perPage = 15}) async {
    final res = await _remote.getReviews(slug, page: page, perPage: perPage);
    return Paginated<LibraryReview>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<LibraryReview> submitReview(String slug, {required int rating, String? comment}) async {
    final dto = await _remote.submitReview(slug, rating: rating, comment: comment);
    return dto.toDomain();
  }

  @override
  Future<Paginated<LibraryUnlockItem>> getMyUnlocks({int page = 1, int perPage = 20}) async {
    final res = await _remote.getMyUnlocks(page: page, perPage: perPage);
    return Paginated<LibraryUnlockItem>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<List<LibraryFile>> getTrending() async {
    final dtos = await _remote.getTrending();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<List<LibraryFile>> getRecommendations() async {
    final dtos = await _remote.getRecommendations();
    return dtos.map((d) => d.toDomain()).toList();
  }
}

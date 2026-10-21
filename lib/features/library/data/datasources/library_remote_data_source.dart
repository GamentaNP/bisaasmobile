// ignore_for_file: use_null_aware_elements, unnecessary_cast
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/pagination.dart';
import '../models/library_dto.dart';

/// Server-verified routes (php artisan route:list --path=api/v1 in C:\laragon\www\bisaas):
/// - GET /library/categories
/// - GET /library/files
/// - GET /library/files/{slug}
/// - POST /library/files/{slug}/unlock
/// - GET /library/files/{slug}/download
/// - GET|POST /library/files/{slug}/reviews
/// - GET /library/me/unlocks
/// - GET /library/trending
/// - GET /library/recommendations
///
/// Do NOT hardcode host, do NOT add /api/v1 twice — Dio baseUrl already has it.
class LibraryRemoteDataSource {
  const LibraryRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<LibraryCategoryDto>> getCategories() async {
    final res = await _dio.get<Map<String, dynamic>>('/library/categories');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body');
    }
    // Tolerant: data may be List directly or envelope
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(LibraryCategoryDto.fromJson).toList();
    }
    // Fallback via ApiResponse
    try {
      final envelope = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return (envelope.data ?? []).map(LibraryCategoryDto.fromJson).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ── Files (cursor paginated) ───────────────────────────────────────────

  /// `GET /library/files` is one of the four collections that moved to the
  /// cursor shape (`MOBILE_API_INTEGRATION_GUIDE.md` §4.1). The server already
  /// defaults to it, so sending `?page=2` returns page one forever — the
  /// client walks `next_cursor` instead.
  ///
  /// Filters are sent with the canonical `filter[...]` grammar; the server
  /// also honours the bare spelling, but the bracket form is the documented
  /// one and is rejected loudly when the key is unknown
  /// (`RejectsUnknownListParams`).
  ///
  /// One behavioural note from the contract: the cursor path walks the
  /// deterministic `average_rating → download_count → id` order, while the
  /// text-relevance ordering of a `?q=` search is an offset-shape feature.
  /// A search therefore still returns relevance-ranked rows on the first page.
  Future<Page<LibraryFileDto>> getFiles({
    int? categoryId,
    String? query,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/library/files',
      queryParameters: cursorQuery(
        cursor: cursor,
        perPage: perPage,
        extra: <String, dynamic>{
          if (categoryId != null) 'filter[category_id]': categoryId,
          if (query != null && query.isNotEmpty) 'filter[search]': query,
          if (fileType != null && fileType.isNotEmpty) 'filter[file_type]': fileType,
          if (visibility != null && visibility.isNotEmpty) 'filter[visibility]': visibility,
          if (minRating != null) 'filter[min_rating]': minRating,
          if (maxCost != null) 'filter[max_cost]': maxCost,
        },
      ),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty library files response',
        endpoint: '/library/files',
      );
    }
    return parsePage<LibraryFileDto>(
      body,
      LibraryFileDto.fromJson,
      endpoint: '/library/files',
    );
  }

  // ── File detail ─────────────────────────────────────────────────────────

  Future<LibraryFileDto> getFile(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/library/files/$slug');
    final body = res.data;
    if (body == null) {
        throw ContractViolation('Empty response body', endpoint: '/library/files/$slug');
      }
    // Success envelope: data is object
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      // Fallback via ApiResponse
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) {
        throw ContractViolation('Library file payload not understood', endpoint: '/library/files/$slug');
      }
    return LibraryFileDto.fromJson(data);
  }

  // ── Unlock (idempotent) ─────────────────────────────────────────────────

  Future<LibraryUnlockDto> unlock(String slug, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    // Canonical verb is PUT (`files.unlock`); the POST form is
    // `files.unlock.transition-alias` (routes/api/v1/library.php:33-34).
    final res = await _dio.put<Map<String, dynamic>>(
      '/library/files/$slug/unlock',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: '/library/files/{slug}/unlock');
    }
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) {
      throw const ContractViolation('Unlock payload not understood', endpoint: '/library/files/{slug}/unlock');
    }
    return LibraryUnlockDto.fromJson(data);
  }

  // ── Download URL ────────────────────────────────────────────────────────

  Future<String> getDownloadUrl(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/library/files/$slug/download');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: '/library/files/{slug}/download');
    }
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) {
      throw const ContractViolation('Download payload not understood', endpoint: '/library/files/{slug}/download');
    }
    final url = (data['download_url'] as String?) ?? (data['url'] as String?) ?? '';
    if (url.isEmpty) {
      throw const ContractViolation('Download URL empty', endpoint: '/library/files/{slug}/download');
    }
    return url;
  }

  // ── Reviews (paginated) ─────────────────────────────────────────────────

  Future<({List<LibraryReviewDto> items, Pagination? pagination})> getReviews(
    String slug, {
    int page = 1,
    int perPage = 15,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/library/files/$slug/reviews',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final body = res.data;
    if (body == null) {
  throw const ContractViolation(
    'Empty response body',
  );
}

    Pagination? pagination;
    final pagRaw = body['pagination'];
    if (pagRaw is Map<String, dynamic>) {
      pagination = Pagination.fromJson(pagRaw);
    }

    var raw = <Map<String, dynamic>>[];
    final data = body['data'];
    if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
    } else if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is Map<String, dynamic> && json['items'] is List) {
            return (json['items'] as List).cast<Map<String, dynamic>>();
          }
          if (json is List) return (json as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
        pagination = env.pagination ?? pagination;
      } catch (_) {}
    }

    return (items: raw.map(LibraryReviewDto.fromJson).toList(), pagination: pagination);
  }

  Future<LibraryReviewDto> submitReview(
    String slug, {
    required int rating,
    String? comment,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/library/files/$slug/reviews',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: '/library/files/{slug}/reviews');
    }
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) {
      throw const ContractViolation('Review payload not understood', endpoint: '/library/files/{slug}/reviews');
    }
    return LibraryReviewDto.fromJson(data);
  }

  // ── My unlocks (paginated) ──────────────────────────────────────────────

  Future<({List<LibraryUnlockItemDto> items, Pagination? pagination})> getMyUnlocks({
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/library/me/unlocks',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final body = res.data;
    if (body == null) {
  throw const ContractViolation(
    'Empty response body',
  );
}

    Pagination? pagination;
    final pagRaw = body['pagination'];
    if (pagRaw is Map<String, dynamic>) {
      pagination = Pagination.fromJson(pagRaw);
    }

    var raw = <Map<String, dynamic>>[];
    final data = body['data'];
    if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
    } else if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is Map<String, dynamic> && json['items'] is List) {
            return (json['items'] as List).cast<Map<String, dynamic>>();
          }
          if (json is List) return (json as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
        pagination = env.pagination ?? pagination;
      } catch (_) {}
    }

    return (items: raw.map(LibraryUnlockItemDto.fromJson).toList(), pagination: pagination);
  }

  // ── Trending ────────────────────────────────────────────────────────────

  Future<List<LibraryFileDto>> getTrending() async {
    final res = await _dio.get<Map<String, dynamic>>('/library/trending');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body');
    }
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(LibraryFileDto.fromJson).toList();
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>().map(LibraryFileDto.fromJson).toList();
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(LibraryFileDto.fromJson).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ── Recommendations ─────────────────────────────────────────────────────

  Future<List<LibraryFileDto>> getRecommendations() async {
    final res = await _dio.get<Map<String, dynamic>>('/library/recommendations');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body');
    }
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(LibraryFileDto.fromJson).toList();
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>().map(LibraryFileDto.fromJson).toList();
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(LibraryFileDto.fromJson).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }
}

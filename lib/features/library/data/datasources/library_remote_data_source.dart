// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable, use_null_aware_elements, omit_local_variable_types, unnecessary_cast
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
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
    if (body == null) return [];
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
    } catch (_) {
      return [];
    }
  }

  // ── Files (paginated) ───────────────────────────────────────────────────

  Future<({List<LibraryFileDto> items, Pagination? pagination})> getFiles({
    int? categoryId,
    String? query,
    String? fileType,
    String? visibility,
    double? minRating,
    int? maxCost,
    int page = 1,
    int perPage = 20,
  }) async {
    final qp = <String, dynamic>{
      if (categoryId != null) 'category_id': categoryId,
      if (query != null && query.isNotEmpty) 'q': query,
      if (fileType != null && fileType.isNotEmpty) 'file_type': fileType,
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
      if (minRating != null) 'min_rating': minRating,
      if (maxCost != null) 'max_cost': maxCost,
      'page': page,
      'per_page': perPage,
    };
    final res = await _dio.get<Map<String, dynamic>>('/library/files', queryParameters: qp);
    final body = res.data;
    if (body == null) return (items: <LibraryFileDto>[], pagination: null);

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
      // Try envelope fallback
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

    final items = raw.map(LibraryFileDto.fromJson).toList();
    return (items: items, pagination: pagination);
  }

  // ── File detail ─────────────────────────────────────────────────────────

  Future<LibraryFileDto> getFile(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/library/files/$slug');
    final body = res.data;
    if (body == null) throw Exception('Library file not found: $slug');
    // Success envelope: data is object
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      // Fallback via ApiResponse
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Library file data missing for $slug');
    return LibraryFileDto.fromJson(data);
  }

  // ── Unlock (idempotent) ─────────────────────────────────────────────────

  Future<LibraryUnlockDto> unlock(String slug, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/library/files/$slug/unlock',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Unlock response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Unlock data missing');
    return LibraryUnlockDto.fromJson(data);
  }

  // ── Download URL ────────────────────────────────────────────────────────

  Future<String> getDownloadUrl(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/library/files/$slug/download');
    final body = res.data;
    if (body == null) throw Exception('Download response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Download URL missing');
    final url = (data['download_url'] as String?) ?? (data['url'] as String?) ?? '';
    if (url.isEmpty) throw Exception('Download URL empty');
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
    if (body == null) return (items: <LibraryReviewDto>[], pagination: null);

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
    if (body == null) throw Exception('Review submit response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Review data missing');
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
    if (body == null) return (items: <LibraryUnlockItemDto>[], pagination: null);

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
    if (body == null) return [];
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
    } catch (_) {
      return [];
    }
  }

  // ── Recommendations ─────────────────────────────────────────────────────

  Future<List<LibraryFileDto>> getRecommendations() async {
    final res = await _dio.get<Map<String, dynamic>>('/library/recommendations');
    final body = res.data;
    if (body == null) return [];
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
    } catch (_) {
      return [];
    }
  }
}

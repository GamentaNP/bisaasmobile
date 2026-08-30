// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable, omit_local_variable_types, unnecessary_cast

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/contest_dto.dart';

/// Verified routes:
/// GET /quiz/contests, GET /quiz/contests/{contest}, POST /quiz/contests/{contest}/join,
/// POST /quiz/contests/{contest}/enter, GET /quiz/contests/{contest}/leaderboard,
/// GET /quiz/contests/{contest}/recap, GET /quiz/contests/{contest}/join-intent,
/// PUT/DELETE /quiz/contests/{contest}/participation
class ContestsRemoteDataSource {
  const ContestsRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<({List<ContestDto> items, Pagination? pagination})> getContests({int page = 1, int perPage = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/contests',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final body = res.data;
    if (body == null) return (items: <ContestDto>[], pagination: null);
    Pagination? pagination;
    if (body['pagination'] is Map<String, dynamic>) {
      pagination = Pagination.fromJson(body['pagination'] as Map<String, dynamic>);
    }
    List<Map<String, dynamic>> raw = [];
    final data = body['data'];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
      if (data['pagination'] is Map<String, dynamic> && pagination == null) {
        pagination = Pagination.fromJson(data['pagination'] as Map<String, dynamic>);
      }
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is List) return (json as List).cast<Map<String, dynamic>>();
          if (json is Map<String, dynamic> && json['items'] is List) {
            return (json['items'] as List).cast<Map<String, dynamic>>();
          }
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
        pagination = env.pagination ?? pagination;
      } catch (_) {}
    }
    return (items: raw.map(ContestDto.fromJson).toList(), pagination: pagination);
  }

  Future<ContestDetailDto> getContest(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/contests/$id');
    final body = res.data;
    if (body == null) throw Exception('Contest $id not found');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Contest data missing');
    return ContestDetailDto.fromJson(data);
  }

  Future<Map<String, dynamic>> getJoinIntent(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/contests/$id/join-intent');
    final body = res.data;
    if (body == null) return {};
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return env.data!;
    } catch (_) {}
    return body;
  }

  Future<int> joinContest(int id, {String? joinIntent, String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/contests/$id/join',
      data: {
        if (joinIntent != null && joinIntent.isNotEmpty) 'join_intent': joinIntent,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) return 0;
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    if (data == null) return 0;
    final entryId = data['entry_id'];
    if (entryId is int) return entryId;
    if (entryId is String) return int.tryParse(entryId) ?? 0;
    return 0;
  }

  Future<ContestAttemptDto> enterContest(int id, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/contests/$id/enter',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Enter contest empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Enter contest data missing');
    return ContestAttemptDto.fromJson(data);
  }

  Future<List<ContestEntryDto>> getLeaderboard(int id, {int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/contests/$id/leaderboard',
      queryParameters: {'limit': limit},
    );
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(ContestEntryDto.fromJson).toList();
    }
    // Some responses nest under meta.leaderboard — but data is entries list
    if (body.containsKey('meta') || body.containsKey('leaderboard')) {
      // Try envelope fallback
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is List) return (json as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        if (env.data != null) return env.data!.map(ContestEntryDto.fromJson).toList();
      } catch (_) {}
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(ContestEntryDto.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ContestRecapDto> getRecap(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/contests/$id/recap');
    final body = res.data;
    if (body == null) return ContestRecapDto.fromJson({});
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    return ContestRecapDto.fromJson(data ?? {});
  }

  Future<void> leaveContest(int id) async {
    await _dio.delete<Map<String, dynamic>>('/quiz/contests/$id/participation');
  }
}

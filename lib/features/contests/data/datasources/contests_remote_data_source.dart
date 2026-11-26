import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
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

  /// A required object payload. Previously several methods fell back to the
  /// raw envelope body when `data` was unreadable, which fabricated a success
  /// out of a response the client never understood.
  Map<String, dynamic> _requireData(
    Map<String, dynamic>? body,
    String endpoint,
  ) =>
      requireDataMap(body, endpoint: endpoint);

  /// `/quiz/contests` is cursor-only. Sending `page` is silently ignored by
  /// the server and yields the first page forever.
  Future<({List<ContestDto> items, Pagination? pagination})> getContests({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/contests',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    const endpoint = '/quiz/contests';
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: endpoint);
    }
    Pagination? pagination;
    final rawPagination = body['pagination'];
    if (rawPagination is Map<String, dynamic>) {
      pagination = Pagination.fromJson(rawPagination);
    }
    final data = body['data'];
    late final List<Map<String, dynamic>> raw;
    if (data is List) {
      raw = data.whereType<Map<String, dynamic>>().toList();
    } else if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is! List) {
        throw ContractViolation(
          'Contest list payload not understood: no `items` list',
          endpoint: endpoint,
        );
      }
      raw = items.whereType<Map<String, dynamic>>().toList();
      final nestedPagination = data['pagination'];
      if (nestedPagination is Map<String, dynamic> && pagination == null) {
        pagination = Pagination.fromJson(nestedPagination);
      }
    } else {
      throw ContractViolation(
        'Contest list payload not understood, got ${data.runtimeType}',
        endpoint: endpoint,
      );
    }
    return (items: raw.map(ContestDto.fromJson).toList(), pagination: pagination);
  }

  Future<ContestDetailDto> getContest(int id) async {
    final endpoint = '/quiz/contests/$id';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return ContestDetailDto.fromJson(_requireData(res.data, endpoint));
  }

  Future<Map<String, dynamic>> getJoinIntent(int id) async {
    final endpoint = '/quiz/contests/$id/join-intent';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _requireData(res.data, endpoint);
  }

  Future<int> joinContest(int id, {String? joinIntent, String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    // Canonical transition is PUT /contests/{id}/participation; POST .../join
    // is the alias (routes/api/v1/quiz.php:362-365).
    final endpoint = '/quiz/contests/$id/participation';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: {
        if (joinIntent != null && joinIntent.isNotEmpty) 'join_intent': joinIntent,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final data = _requireData(res.data, endpoint);
    final entryId = data['entry_id'];
    if (entryId is int) return entryId;
    if (entryId is String) {
      final parsed = int.tryParse(entryId);
      if (parsed != null) return parsed;
    }
    throw ContractViolation(
      'Join response missing a usable `entry_id`',
      endpoint: endpoint,
    );
  }

  Future<ContestAttemptDto> enterContest(int id, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final endpoint = '/quiz/contests/$id/entry';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return ContestAttemptDto.fromJson(_requireData(res.data, endpoint));
  }

  Future<List<ContestEntryDto>> getLeaderboard(int id, {int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/contests/$id/leaderboard',
      queryParameters: {'limit': limit},
    );
    final endpoint = '/quiz/contests/$id/leaderboard';
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    final List<dynamic> rows;
    if (data is List) {
      rows = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      rows = data['items'] as List;
    } else {
      throw ContractViolation(
        'Contest leaderboard payload not understood, got ${data.runtimeType}',
        endpoint: endpoint,
      );
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ContestEntryDto.fromJson)
        .toList();
  }

  Future<ContestRecapDto> getRecap(int id) async {
    final endpoint = '/quiz/contests/$id/recap';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return ContestRecapDto.fromJson(_requireData(res.data, endpoint));
  }

  Future<void> leaveContest(int id) async {
    await _dio.delete<Map<String, dynamic>>('/quiz/contests/$id/participation');
  }
}

// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable, omit_local_variable_types, unnecessary_cast

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/leaderboard_dto.dart';
import '../../domain/entities/leaderboard.dart';

/// Verified routes:
/// - GET /quiz/leaderboards/{leaderboard}
/// - GET /quiz/leaderboards/my-rank
/// - POST /quiz/leaderboard
/// - GET /donations/leaderboard
class LeaderboardRemoteDataSource {
  const LeaderboardRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<LeaderboardShow> getLeaderboard(int id, {int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/leaderboards/$id',
      queryParameters: {'limit': limit},
    );
    final body = res.data;
    if (body == null) throw Exception('Leaderboard empty');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return _parseShow(data);
    }
    // Fallback envelope
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return _parseShow(env.data!);
    } catch (_) {}
    throw Exception('Leaderboard missing data');
  }

  LeaderboardShow _parseShow(Map<String, dynamic> data) {
    final lbRaw = data['leaderboard'];
    final entriesRaw = data['entries'];
    final myRankRaw = data['my_rank'] ?? data['myRank'];
    final lbDto = lbRaw is Map<String, dynamic> ? LeaderboardDto.fromJson(lbRaw) : LeaderboardDto.fromJson(data);
    final entries = <LeaderboardEntry>[];
    if (entriesRaw is List) {
      for (final e in entriesRaw) {
        if (e is Map<String, dynamic>) {
          entries.add(LeaderboardEntryDto.fromJson(e).toDomain());
        }
      }
    }
    int? myRank;
    if (myRankRaw is int) myRank = myRankRaw;
    if (myRankRaw is String) myRank = int.tryParse(myRankRaw);
    return LeaderboardShow(leaderboard: lbDto.toDomain(), entries: entries, myRank: myRank);
  }

  Future<List<MyRank>> getMyRanks() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/leaderboards/my-rank');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    if (data is List) {
      return MyRankDto.listFromJson(data);
    }
    if (data is Map<String, dynamic> && data['ranks'] is List) {
      return MyRankDto.listFromJson(data['ranks']);
    }
    try {
      final env = ApiResponse.fromJson(body, (json) => json);
      if (env.data is List) {
        return MyRankDto.listFromJson(env.data);
      }
      if (env.data is Map<String, dynamic>) {
        final m = env.data as Map<String, dynamic>;
        if (m['ranks'] is List) return MyRankDto.listFromJson(m['ranks']);
      }
    } catch (_) {}
    // Fallback: body itself may be list under but handle
    if (body['ranks'] is List) return MyRankDto.listFromJson(body['ranks']);
    return [];
  }

  Future<Map<String, dynamic>> submitScore({
    required String mode,
    required int score,
    required int correct,
    required int total,
    required int streak,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/leaderboard',
      data: {
        'mode': mode,
        'score': score,
        'correct': correct,
        'total': total,
        'streak': streak,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) return {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return env.data!;
    } catch (_) {}
    return body;
  }

  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/donations/leaderboard');
    final body = res.data;
    if (body == null) return [];
    // Data shape: {topDonors: [{donorName, badge, badgeLabel, badgeColor, totalDonatedFormatted, streakMonths}]}
    List<Map<String, dynamic>> raw = [];
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final top = data['topDonors'] ?? data['top_donors'];
      if (top is List) raw = top.cast<Map<String, dynamic>>();
    } else if (body['topDonors'] is List) {
      raw = (body['topDonors'] as List).cast<Map<String, dynamic>>();
    }
    if (raw.isEmpty) {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        if (env.data != null) {
          final d = env.data!;
          final top = d['topDonors'] ?? d['top_donors'];
          if (top is List) raw = (top as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }
    return raw.map((e) => DonorLeaderboardEntryDto.fromJson(e).toDomain()).toList();
  }
}

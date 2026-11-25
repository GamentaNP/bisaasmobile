// ignore_for_file: omit_local_variable_types

import 'package:bisaasmobile/shared/utils/wire_coercion.dart';
import '../../../../app/localization/l10n.dart';
import '../../domain/entities/leaderboard.dart';

class LeaderboardDto {
  const LeaderboardDto({
    required this.id,
    required this.name,
    this.period = 'all_time',
    this.scope = 'global',
    this.scopeId,
    this.isActive = true,
    this.refreshedAt,
  });

  factory LeaderboardDto.fromJson(Map<String, dynamic> j) {
    return LeaderboardDto(
      id: wireInt(j['id']) ?? 0,
      name: (j['name'] as String?) ?? 'Leaderboard',
      period: (j['period'] as String?) ?? 'all_time',
      scope: (j['scope'] as String?) ?? 'global',
      scopeId: wireInt(j['scope_id'] ?? j['scopeId']),
      isActive: (j['is_active'] as bool?) ?? (j['isActive'] as bool?) ?? true,
      refreshedAt: wireDate(j['refreshed_at'] ?? j['refreshedAt']),
    );
  }

  final int id;
  final String name;
  final String period;
  final String scope;
  final int? scopeId;
  final bool isActive;
  final DateTime? refreshedAt;

  Leaderboard toDomain() => Leaderboard(
        id: id,
        name: name,
        period: period,
        scope: scope,
        scopeId: scopeId,
        isActive: isActive,
        refreshedAt: refreshedAt,
      );
}

class LeaderboardEntryDto {
  const LeaderboardEntryDto({
    required this.rank,
    required this.score,
    required this.userId,
    this.displayName,
    this.avatar,
    this.attemptsCount = 0,
    this.leaderboardId,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> j) {
    // User may be nested under `user` key
    final userRaw = j['user'];
    String? name;
    String? avatar;
    int? uid = wireInt(j['user_id'] ?? j['userId'] ?? j['id']);
    if (userRaw is Map<String, dynamic>) {
      name = (userRaw['name'] as String?) ?? (userRaw['display_name'] as String?);
      avatar = (userRaw['avatar'] as String?) ?? (userRaw['avatar_url'] as String?);
      uid = wireInt(userRaw['id']) ?? uid;
    } else {
      name = (j['display_name'] as String?) ?? (j['name'] as String?);
      avatar = (j['avatar'] as String?) ?? (j['avatar_url'] as String?);
    }
    return LeaderboardEntryDto(
      rank: wireInt(j['rank']) ?? 0,
      score: wireDouble(j['score']) ?? 0,
      userId: uid ?? 0,
      displayName: name,
      avatar: avatar,
      attemptsCount: wireInt(j['attempts_count'] ?? j['attemptsCount']) ?? 0,
      leaderboardId: wireInt(j['quiz_leaderboard_id'] ?? j['leaderboard_id']),
    );
  }

  final int rank;
  final double score;
  final int userId;
  final String? displayName;
  final String? avatar;
  final int attemptsCount;
  final int? leaderboardId;

  LeaderboardEntry toDomain({bool isMe = false}) => LeaderboardEntry(
        rank: rank,
        score: score,
        userId: userId,
        displayName: displayName,
        avatar: avatar,
        attemptsCount: attemptsCount,
        isMe: isMe,
        leaderboardId: leaderboardId,
      );
}

class MyRankDto {
  const MyRankDto({required this.leaderboard, this.rank, this.score});

  factory MyRankDto.fromJson(Map<String, dynamic> j) {
    // Two shapes:
    // 1) GET /leaderboards/my-rank returns leaderboard object with entries [{rank, score}]
    // 2) GET /leaderboards/{id} includes my_rank int
    // We normalize: if `entries` contains one filtered to my user, use it.
    final leaderboardRaw = j['leaderboard'] is Map<String, dynamic> ? j['leaderboard'] as Map<String, dynamic> : j;
    final leaderboard = LeaderboardDto.fromJson(leaderboardRaw).toDomain();
    // Try entries path
    int? rank;
    double? score;
    final entries = j['entries'];
    if (entries is List && entries.isNotEmpty) {
      final first = entries.first;
      if (first is Map<String, dynamic>) {
        rank = wireInt(first['rank']);
        score = wireDouble(first['score']);
      }
    }
    rank ??= wireInt(j['rank']);
    score ??= wireDouble(j['score']);
    // Fallback to j's rank/score directly
    return MyRankDto(leaderboard: leaderboard, rank: rank, score: score);
  }

  // For GET /leaderboards/my-rank list parsing
  static List<MyRank> listFromJson(Object? json) {
    if (json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final lbDto = LeaderboardDto.fromJson(item);
          // entries is filtered to my user: [{quiz_leaderboard_id, rank, score}]
          int? rank;
          double? score;
          final entries = item['entries'];
          if (entries is List && entries.isNotEmpty) {
            final e = entries.first;
            if (e is Map<String, dynamic>) {
              rank = wireInt(e['rank']);
              score = wireDouble(e['score']);
            }
          }
          return MyRank(leaderboard: lbDto.toDomain(), rank: rank, score: score);
        })
        .toList();
  }

  final Leaderboard leaderboard;
  final int? rank;
  final double? score;

  MyRank toDomain() => MyRank(leaderboard: leaderboard, rank: rank, score: score);
}

class DonorLeaderboardEntryDto {
  const DonorLeaderboardEntryDto({
    required this.donorName,
    required this.badge,
    required this.badgeLabel,
    required this.badgeColor,
    required this.totalDonatedFormatted,
    this.streakMonths = 0,
  });

  factory DonorLeaderboardEntryDto.fromJson(Map<String, dynamic> j) => DonorLeaderboardEntryDto(
        donorName: (j['donorName'] as String?) ?? (j['donor_name'] as String?) ?? 'Anonymous',
        badge: (j['badge'] as String?) ?? 'bronze',
        badgeLabel: (j['badgeLabel'] as String?) ?? (j['badge_label'] as String?) ?? appL10n().leaderboardTierBronze,
        badgeColor: (j['badgeColor'] as String?) ?? (j['badge_color'] as String?) ?? '#CD7F32',
        totalDonatedFormatted: (j['totalDonatedFormatted'] as String?) ?? (j['total_donated_formatted'] as String?) ?? r'$0.00',
        streakMonths: wireInt(j['streakMonths'] ?? j['streak_months']) ?? 0,
      );

  final String donorName;
  final String badge;
  final String badgeLabel;
  final String badgeColor;
  final String totalDonatedFormatted;
  final int streakMonths;

  DonorLeaderboardEntry toDomain() => DonorLeaderboardEntry(
        donorName: donorName,
        badge: badge,
        badgeLabel: badgeLabel,
        badgeColor: badgeColor,
        totalDonatedFormatted: totalDonatedFormatted,
        streakMonths: streakMonths,
      );
}

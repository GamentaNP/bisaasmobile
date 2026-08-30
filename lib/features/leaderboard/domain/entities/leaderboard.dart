import 'package:meta/meta.dart';

@immutable
class Leaderboard {
  const Leaderboard({
    required this.id,
    required this.name,
    this.period = 'all_time',
    this.scope = 'global',
    this.scopeId,
    this.isActive = true,
    this.refreshedAt,
  });

  final int id;
  final String name;
  final String period; // daily, weekly, monthly, all_time, etc.
  final String scope; // global, friends, league, etc.
  final int? scopeId;
  final bool isActive;
  final DateTime? refreshedAt;
}

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.score,
    required this.userId,
    this.displayName,
    this.avatar,
    this.attemptsCount = 0,
    this.isMe = false,
    this.leaderboardId,
  });

  final int rank;
  final double score;
  final int userId;
  final String? displayName;
  final String? avatar;
  final int attemptsCount;
  final bool isMe;
  final int? leaderboardId;
}

@immutable
class MyRank {
  const MyRank({
    required this.leaderboard,
    this.rank,
    this.score,
  });

  final Leaderboard leaderboard;
  final int? rank;
  final double? score;
}

@immutable
class DonorLeaderboardEntry {
  const DonorLeaderboardEntry({
    required this.donorName,
    required this.badge,
    required this.badgeLabel,
    required this.badgeColor,
    required this.totalDonatedFormatted,
    this.streakMonths = 0,
  });

  final String donorName;
  final String badge;
  final String badgeLabel;
  final String badgeColor;
  final String totalDonatedFormatted;
  final int streakMonths;
}

@immutable
class LeaderboardShow {
  const LeaderboardShow({
    required this.leaderboard,
    required this.entries,
    this.myRank,
  });

  final Leaderboard leaderboard;
  final List<LeaderboardEntry> entries;
  final int? myRank;
}

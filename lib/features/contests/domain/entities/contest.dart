import 'package:meta/meta.dart';

@immutable
class Contest {
  const Contest({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.quizBlueprintId,
    this.maxParticipants,
    required this.entryFeeCoins,
    required this.prizePoolCoins,
    this.prizeDistribution,
    this.lifelinePolicy,
    this.scoringRules,
    this.tieBreakPolicy,
    this.startsAt,
    this.endsAt,
    this.isRegistered = false,
    this.entryId,
    this.participantCount,
  });

  final int id;
  final String title;
  final String? description;
  final String status; // upcoming, active, ended, etc.
  final int? quizBlueprintId;
  final int? maxParticipants;
  final int entryFeeCoins;
  final int prizePoolCoins;
  final Map<String, dynamic>? prizeDistribution;
  final Map<String, dynamic>? lifelinePolicy;
  final Map<String, dynamic>? scoringRules;
  final Map<String, dynamic>? tieBreakPolicy;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isRegistered;
  final int? entryId;
  final int? participantCount;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isEnded => status.toLowerCase() == 'ended';
  bool get isFree => entryFeeCoins == 0;
}

@immutable
class ContestEntry {
  const ContestEntry({
    required this.id,
    required this.contestId,
    required this.userId,
    this.score = 0,
    this.completed = false,
    this.rank,
    this.displayName,
  });

  final int id;
  final int contestId;
  final int userId;
  final double score;
  final bool completed;
  final int? rank;
  final String? displayName;
}

@immutable
class ContestLeaderboardMeta {
  const ContestLeaderboardMeta({
    this.cached = false,
    this.refreshed = false,
    this.generatedAt,
    this.refreshBudgetRemaining = 0,
  });

  final bool cached;
  final bool refreshed;
  final DateTime? generatedAt;
  final int refreshBudgetRemaining;
}

@immutable
class ContestDetail {
  const ContestDetail({
    required this.contest,
    this.isRegistered = false,
    this.leaderboard = const [],
    this.leaderboardMeta,
    this.sponsorSlots = const [],
  });

  final Contest contest;
  final bool isRegistered;
  final List<ContestEntry> leaderboard;
  final ContestLeaderboardMeta? leaderboardMeta;
  final List<Map<String, dynamic>> sponsorSlots;
}

@immutable
class ContestRecap {
  const ContestRecap({
    this.title,
    this.summary,
    this.winners = const [],
    this.stats = const {},
    this.raw = const {},
  });

  final String? title;
  final String? summary;
  final List<ContestEntry> winners;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> raw;
}

@immutable
class ContestAttempt {
  const ContestAttempt({required this.attemptId, this.expiresAt, this.serverNow});

  final int attemptId;
  final DateTime? expiresAt;
  final DateTime? serverNow;
}

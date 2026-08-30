// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types

import '../../domain/entities/contest.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class ContestDto {
  const ContestDto({
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
  });

  factory ContestDto.fromJson(Map<String, dynamic> j) {
    return ContestDto(
      id: _asInt(j['id']) ?? 0,
      title: (j['title'] as String?) ?? 'Contest',
      description: j['description'] as String?,
      status: (j['status'] as String?) ?? (j['state'] as String?) ?? 'upcoming',
      quizBlueprintId: _asInt(j['quiz_blueprint_id'] ?? j['blueprint_id']),
      maxParticipants: _asInt(j['max_participants']),
      entryFeeCoins: _asInt(j['entry_fee_coins'] ?? j['entry_fee']) ?? 0,
      prizePoolCoins: _asInt(j['prize_pool_coins'] ?? j['prize_pool']) ?? 0,
      prizeDistribution: j['prize_distribution'] is Map<String, dynamic> ? j['prize_distribution'] as Map<String, dynamic> : null,
      lifelinePolicy: j['lifeline_policy'] is Map<String, dynamic> ? j['lifeline_policy'] as Map<String, dynamic> : null,
      scoringRules: j['scoring_rules'] is Map<String, dynamic> ? j['scoring_rules'] as Map<String, dynamic> : null,
      tieBreakPolicy: j['tie_break_policy'] is Map<String, dynamic> ? j['tie_break_policy'] as Map<String, dynamic> : null,
      startsAt: _asDate(j['starts_at']),
      endsAt: _asDate(j['ends_at']),
      isRegistered: (j['is_registered'] as bool?) ?? (j['isRegistered'] as bool?) ?? false,
    );
  }

  final int id;
  final String title;
  final String? description;
  final String status;
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

  Contest toDomain() => Contest(
        id: id,
        title: title,
        description: description,
        status: status,
        quizBlueprintId: quizBlueprintId,
        maxParticipants: maxParticipants,
        entryFeeCoins: entryFeeCoins,
        prizePoolCoins: prizePoolCoins,
        prizeDistribution: prizeDistribution,
        lifelinePolicy: lifelinePolicy,
        scoringRules: scoringRules,
        tieBreakPolicy: tieBreakPolicy,
        startsAt: startsAt,
        endsAt: endsAt,
        isRegistered: isRegistered,
      );
}

class ContestEntryDto {
  const ContestEntryDto({
    required this.id,
    required this.contestId,
    required this.userId,
    this.score = 0,
    this.completed = false,
    this.rank,
    this.displayName,
  });

  factory ContestEntryDto.fromJson(Map<String, dynamic> j) {
    // Handle user nesting
    String? name;
    final userRaw = j['user'];
    if (userRaw is Map<String, dynamic>) {
      name = (userRaw['name'] as String?) ?? (userRaw['display_name'] as String?);
    } else {
      name = (j['display_name'] as String?) ?? (j['name'] as String?);
    }
    return ContestEntryDto(
      id: _asInt(j['id']) ?? 0,
      contestId: _asInt(j['quiz_contest_id'] ?? j['contest_id']) ?? 0,
      userId: _asInt(j['user_id']) ?? 0,
      score: _asDouble(j['score']) ?? 0,
      completed: (j['completed'] as bool?) ?? false,
      rank: _asInt(j['rank']),
      displayName: name,
    );
  }

  final int id;
  final int contestId;
  final int userId;
  final double score;
  final bool completed;
  final int? rank;
  final String? displayName;

  ContestEntry toDomain() => ContestEntry(id: id, contestId: contestId, userId: userId, score: score, completed: completed, rank: rank, displayName: displayName);
}

class ContestDetailDto {
  const ContestDetailDto({
    required this.contest,
    this.isRegistered = false,
    this.leaderboard = const [],
    this.leaderboardMeta,
    this.sponsorSlots = const [],
  });

  factory ContestDetailDto.fromJson(Map<String, dynamic> j) {
    // j is already the `data` object from envelope containing contest, is_registered, leaderboard, etc.
    final contestRaw = j['contest'];
    ContestDto contestDto;
    if (contestRaw is Map<String, dynamic>) {
      contestDto = ContestDto.fromJson(contestRaw);
    } else {
      contestDto = ContestDto.fromJson(j);
    }
    final isReg = (j['is_registered'] as bool?) ?? (j['isRegistered'] as bool?) ?? false;

    final leaderboardRaw = j['leaderboard'];
    List<ContestEntryDto> lb = [];
    if (leaderboardRaw is List) {
      lb = leaderboardRaw.whereType<Map<String, dynamic>>().map(ContestEntryDto.fromJson).toList();
    }

    ContestLeaderboardMeta? meta;
    final metaRaw = j['leaderboard_meta'] ?? j['leaderboardMeta'];
    if (metaRaw is Map<String, dynamic>) {
      meta = ContestLeaderboardMeta(
        cached: (metaRaw['cached'] as bool?) ?? false,
        refreshed: (metaRaw['refreshed'] as bool?) ?? false,
        generatedAt: _asDate(metaRaw['generated_at']),
        refreshBudgetRemaining: _asInt(metaRaw['refresh_budget_remaining']) ?? 0,
      );
    }

    final sponsorRaw = j['sponsor_slots'] ?? j['sponsorSlots'];
    List<Map<String, dynamic>> sponsors = [];
    if (sponsorRaw is List) {
      sponsors = sponsorRaw.whereType<Map<String, dynamic>>().toList();
    }

    return ContestDetailDto(contest: contestDto, isRegistered: isReg, leaderboard: lb, leaderboardMeta: meta, sponsorSlots: sponsors);
  }

  final ContestDto contest;
  final bool isRegistered;
  final List<ContestEntryDto> leaderboard;
  final ContestLeaderboardMeta? leaderboardMeta;
  final List<Map<String, dynamic>> sponsorSlots;

  ContestDetail toDomain() => ContestDetail(
        contest: contest.toDomain().copyWithRegistered(isRegistered),
        isRegistered: isRegistered,
        leaderboard: leaderboard.map((e) => e.toDomain()).toList(),
        leaderboardMeta: leaderboardMeta,
        sponsorSlots: sponsorSlots,
      );
}

extension _ContestCopy on Contest {
  Contest copyWithRegistered(bool reg) => Contest(
        id: id,
        title: title,
        description: description,
        status: status,
        quizBlueprintId: quizBlueprintId,
        maxParticipants: maxParticipants,
        entryFeeCoins: entryFeeCoins,
        prizePoolCoins: prizePoolCoins,
        prizeDistribution: prizeDistribution,
        lifelinePolicy: lifelinePolicy,
        scoringRules: scoringRules,
        tieBreakPolicy: tieBreakPolicy,
        startsAt: startsAt,
        endsAt: endsAt,
        isRegistered: reg,
      );
}

class ContestRecapDto {
  const ContestRecapDto({required this.raw});

  factory ContestRecapDto.fromJson(Map<String, dynamic> j) => ContestRecapDto(raw: j);

  final Map<String, dynamic> raw;

  ContestRecap toDomain() {
    // Try to extract common keys
    final title = (raw['title'] as String?) ?? (raw['contest'] is Map ? (raw['contest'] as Map)['title'] as String? : null);
    final summary = (raw['summary'] as String?) ?? (raw['description'] as String?);
    final winnersRaw = raw['winners'] ?? raw['top'] ?? raw['entries'];
    List<ContestEntry> winners = [];
    if (winnersRaw is List) {
      winners = winnersRaw.whereType<Map<String, dynamic>>().map((e) => ContestEntryDto.fromJson(e).toDomain()).toList();
    }
    return ContestRecap(title: title, summary: summary, winners: winners, stats: raw, raw: raw);
  }
}

class ContestAttemptDto {
  const ContestAttemptDto({required this.attemptId, this.expiresAt, this.serverNow});

  factory ContestAttemptDto.fromJson(Map<String, dynamic> j) => ContestAttemptDto(
        attemptId: _asInt(j['attempt_id'] ?? j['attemptId'] ?? j['id']) ?? 0,
        expiresAt: _asDate(j['expires_at']),
        serverNow: _asDate(j['server_now']),
      );

  final int attemptId;
  final DateTime? expiresAt;
  final DateTime? serverNow;

  ContestAttempt toDomain() => ContestAttempt(attemptId: attemptId, expiresAt: expiresAt, serverNow: serverNow);
}

// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types

import '../../domain/entities/live_event.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class LiveEventDto {
  const LiveEventDto({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.status,
    required this.questionCount,
    required this.startsAt,
    this.endsAt,
    required this.questionDurationSeconds,
    this.maxParticipants,
    required this.activeParticipantCount,
    required this.waitlistedParticipantCount,
    required this.entryFeeCoins,
    required this.prizePoolCoins,
    required this.waitlistEnabled,
    required this.replayEnabled,
    this.commentatorMessage,
  });

  factory LiveEventDto.fromJson(Map<String, dynamic> j) {
    // Handle both snake_case and camelCase keys for tolerance
    return LiveEventDto(
      id: _asInt(j['id']) ?? 0,
      title: (j['title'] as String?) ?? 'Live Event',
      description: j['description'] as String?,
      eventType: (j['event_type'] as String?) ?? (j['eventType'] as String?) ?? 'quiz',
      status: (j['status'] as String?) ?? 'scheduled',
      questionCount: _asInt(j['question_count'] ?? j['questionCount']) ?? 0,
      startsAt: _asDate(j['starts_at'] ?? j['startsAt']) ?? DateTime.now(),
      endsAt: _asDate(j['ends_at'] ?? j['endsAt']),
      questionDurationSeconds: _asInt(j['question_duration_seconds'] ?? j['questionDurationSeconds']) ?? 30,
      maxParticipants: _asInt(j['max_participants'] ?? j['maxParticipants']),
      activeParticipantCount: _asInt(j['active_participant_count'] ?? j['activeParticipantCount']) ?? 0,
      waitlistedParticipantCount: _asInt(j['waitlisted_participant_count'] ?? j['waitlistedParticipantCount']) ?? 0,
      entryFeeCoins: _asInt(j['entry_fee_coins'] ?? j['entryFeeCoins']) ?? 0,
      prizePoolCoins: _asInt(j['prize_pool_coins'] ?? j['prizePoolCoins']) ?? 0,
      waitlistEnabled: (j['waitlist_enabled'] as bool?) ?? (j['waitlistEnabled'] as bool?) ?? false,
      replayEnabled: (j['replay_enabled'] as bool?) ?? (j['replayEnabled'] as bool?) ?? false,
      commentatorMessage: j['commentator_message'] as String? ?? j['commentatorMessage'] as String?,
    );
  }

  final int id;
  final String title;
  final String? description;
  final String eventType;
  final String status;
  final int questionCount;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int questionDurationSeconds;
  final int? maxParticipants;
  final int activeParticipantCount;
  final int waitlistedParticipantCount;
  final int entryFeeCoins;
  final int prizePoolCoins;
  final bool waitlistEnabled;
  final bool replayEnabled;
  final String? commentatorMessage;

  LiveEvent toDomain() => LiveEvent(
        id: id,
        title: title,
        description: description,
        eventType: eventType,
        status: status,
        questionCount: questionCount,
        startsAt: startsAt,
        endsAt: endsAt,
        questionDurationSeconds: questionDurationSeconds,
        maxParticipants: maxParticipants,
        activeParticipantCount: activeParticipantCount,
        waitlistedParticipantCount: waitlistedParticipantCount,
        entryFeeCoins: entryFeeCoins,
        prizePoolCoins: prizePoolCoins,
        waitlistEnabled: waitlistEnabled,
        replayEnabled: replayEnabled,
        commentatorMessage: commentatorMessage,
      );
}

class LiveEventParticipantDto {
  const LiveEventParticipantDto({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.answeredCount,
    this.lastAnsweredQuestionIndex,
    required this.registeredAt,
    this.checkedInAt,
    this.finishedAt,
  });

  factory LiveEventParticipantDto.fromJson(Map<String, dynamic> j) {
    return LiveEventParticipantDto(
      id: _asInt(j['id']) ?? 0,
      eventId: _asInt(j['event_id'] ?? j['eventId'] ?? j['quiz_live_event_id']) ?? 0,
      userId: _asInt(j['user_id'] ?? j['userId']) ?? 0,
      status: (j['status'] as String?) ?? 'registered',
      score: _asInt(j['score']) ?? 0,
      correctCount: _asInt(j['correct_count'] ?? j['correctCount']) ?? 0,
      answeredCount: _asInt(j['answered_count'] ?? j['answeredCount']) ?? 0,
      lastAnsweredQuestionIndex: _asInt(j['last_answered_question_index'] ?? j['lastAnsweredQuestionIndex']),
      registeredAt: _asDate(j['registered_at'] ?? j['registeredAt']) ?? DateTime.now(),
      checkedInAt: _asDate(j['checked_in_at'] ?? j['checkedInAt']),
      finishedAt: _asDate(j['finished_at'] ?? j['finishedAt']),
    );
  }

  final int id;
  final int eventId;
  final int userId;
  final String status;
  final int score;
  final int correctCount;
  final int answeredCount;
  final int? lastAnsweredQuestionIndex;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final DateTime? finishedAt;

  LiveEventParticipant toDomain() => LiveEventParticipant(
        id: id,
        eventId: eventId,
        userId: userId,
        status: status,
        score: score,
        correctCount: correctCount,
        answeredCount: answeredCount,
        lastAnsweredQuestionIndex: lastAnsweredQuestionIndex,
        registeredAt: registeredAt,
        checkedInAt: checkedInAt,
        finishedAt: finishedAt,
      );
}

class LiveEventSnapshotDto {
  const LiveEventSnapshotDto({required this.raw});

  factory LiveEventSnapshotDto.fromJson(Map<String, dynamic> j) => LiveEventSnapshotDto(raw: j);

  final Map<String, dynamic> raw;

  LiveEventSnapshot toDomain() {
    // Snapshot shape from LiveEventService::snapshotFor: includes ...snapshot, participant
    // We keep raw and try to extract current_question if present
    Map<String, dynamic>? cq;
    final snapshot = raw['snapshot'] is Map<String, dynamic> ? raw['snapshot'] as Map<String, dynamic> : raw;
    final current = snapshot['current_question'] ?? raw['current_question'];
    if (current is Map<String, dynamic>) {
      cq = current;
    }
    LiveEventParticipant? participant;
    final pRaw = raw['participant'] ?? snapshot['participant'];
    if (pRaw is Map<String, dynamic>) {
      participant = LiveEventParticipantDto.fromJson(pRaw).toDomain();
    }
    List<Map<String, dynamic>>? board;
    final lb = raw['leaderboard'] ?? snapshot['leaderboard'];
    if (lb is List) {
      board = lb.whereType<Map<String, dynamic>>().toList();
    }
    return LiveEventSnapshot(raw: raw, currentQuestion: cq, participant: participant, leaderboard: board);
  }
}

class LiveEventDetailDto {
  const LiveEventDetailDto({required this.event, this.leaderboard = const []});

  factory LiveEventDetailDto.fromJson(Map<String, dynamic> j) {
    final eventRaw = j['event'] is Map<String, dynamic> ? j['event'] as Map<String, dynamic> : j;
    final event = LiveEventDto.fromJson(eventRaw);
    List<Map<String, dynamic>> board = [];
    final lb = j['leaderboard'];
    if (lb is List) board = lb.whereType<Map<String, dynamic>>().toList();
    return LiveEventDetailDto(event: event, leaderboard: board);
  }

  final LiveEventDto event;
  final List<Map<String, dynamic>> leaderboard;

  LiveEventDetail toDomain() => LiveEventDetail(event: event.toDomain(), leaderboard: leaderboard);
}

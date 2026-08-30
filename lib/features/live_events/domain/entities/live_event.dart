import 'package:meta/meta.dart';

@immutable
class LiveEvent {
  const LiveEvent({
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

  final int id;
  final String title;
  final String? description;
  final String eventType;
  final String status; // scheduled, countdown, live, finished, cancelled
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

  bool get isLive => status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isCountdown => status == 'countdown';
  bool get isFinished => status == 'finished';
  bool get isJoinable => status == 'scheduled' || status == 'countdown';
}

@immutable
class LiveEventParticipant {
  const LiveEventParticipant({
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

  final int id;
  final int eventId;
  final int userId;
  final String status; // registered, waitlisted, checked_in, active, completed
  final int score;
  final int correctCount;
  final int answeredCount;
  final int? lastAnsweredQuestionIndex;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final DateTime? finishedAt;

  bool get isWaitlisted => status == 'waitlisted';
}

@immutable
class LiveEventSnapshot {
  const LiveEventSnapshot({
    required this.raw,
    this.currentQuestion,
    this.participant,
    this.leaderboard,
  });

  final Map<String, dynamic> raw;
  final Map<String, dynamic>? currentQuestion;
  final LiveEventParticipant? participant;
  final List<Map<String, dynamic>>? leaderboard;

  bool get hasCurrentQuestion => currentQuestion != null && currentQuestion!['question_id'] != null;
}

@immutable
class LiveEventDetail {
  const LiveEventDetail({required this.event, this.leaderboard = const []});
  final LiveEvent event;
  final List<Map<String, dynamic>> leaderboard;
}

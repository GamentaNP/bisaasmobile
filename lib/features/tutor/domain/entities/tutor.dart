import 'package:meta/meta.dart';

@immutable
class TutorMessage {
  const TutorMessage({
    required this.role,
    required this.content,
    this.timestamp,
  });

  final String role; // user | assistant | system
  final String content;
  final DateTime? timestamp;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

@immutable
class TutorPlanDay {
  const TutorPlanDay({
    required this.dayIndex,
    required this.title,
    this.description,
    this.tasks = const [],
    this.completed = false,
    this.isCurrent = false,
    this.dueAt,
  });

  final int dayIndex;
  final String title;
  final String? description;
  final List<String> tasks;
  final bool completed;
  final bool isCurrent;
  final DateTime? dueAt;
}

@immutable
class TutorPlan {
  const TutorPlan({
    required this.id,
    required this.title,
    this.description,
    this.totalDays = 0,
    this.days = const [],
    this.currentDayIndex,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final int totalDays;
  final List<TutorPlanDay> days;
  final int? currentDayIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEmpty => days.isEmpty;
}

@immutable
class TutorToday {
  const TutorToday({
    required this.date,
    this.title = 'Today',
    this.tasks = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.summary,
    this.isCompleted = false,
  });

  final DateTime date;
  final String title;
  final List<String> tasks;
  final int completedCount;
  final int totalCount;
  final String? summary;
  final bool isCompleted;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}

@immutable
class WeakArea {
  const WeakArea({
    required this.topic,
    this.topicId,
    this.slug,
    this.accuracy,
    this.attempts = 0,
    this.recommendation,
    this.reason,
  });

  final String topic;
  final String? topicId;
  final String? slug;
  final double? accuracy;
  final int attempts;
  final String? recommendation;
  final String? reason;
}

@immutable
class ProjectedScore {
  const ProjectedScore({
    required this.score,
    this.maxScore = 100,
    this.confidence,
    this.breakdown = const {},
    this.trend,
    this.updatedAt,
  });

  final double score;
  final double maxScore;
  final double? confidence;
  final Map<String, dynamic> breakdown;
  final String? trend;
  final DateTime? updatedAt;

  double get percentage => maxScore == 0 ? 0 : (score / maxScore) * 100;
}

@immutable
class WeeklyReport {
  const WeeklyReport({
    this.weekStart,
    this.weekEnd,
    this.tasksCompleted = 0,
    this.tasksPlanned = 0,
    this.averageScore,
    this.summary,
    this.insights = const [],
    this.hoursStudied,
  });

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final int tasksCompleted;
  final int tasksPlanned;
  final double? averageScore;
  final String? summary;
  final List<String> insights;
  final double? hoursStudied;

  double get completionRate =>
      tasksPlanned == 0 ? 0 : tasksCompleted / tasksPlanned;
}

@immutable
class RevisionItem {
  const RevisionItem({
    required this.id,
    required this.questionId,
    required this.dueAt,
    this.topic,
    this.title,
    this.priority,
  });

  final String id;
  final String questionId;
  final DateTime dueAt;
  final String? topic;
  final String? title;
  final String? priority;

  bool get isOverdue => DateTime.now().isAfter(dueAt);
}

@immutable
class TutorOnboardingSession {
  const TutorOnboardingSession({
    required this.sessionId,
    this.prompt,
    this.stage,
    this.isCompleted = false,
  });

  final String sessionId;
  final String? prompt;
  final String? stage;
  final bool isCompleted;
}

@immutable
class TutorChatResult {
  const TutorChatResult({
    required this.answer,
    this.degraded = false,
    this.sentinel,
    this.citations = const [],
    this.messageId,
  });

  final String answer;
  final bool degraded;
  final String? sentinel; // NO_DATA | RETRIEVAL_FAILED | null
  final List<String> citations;
  final String? messageId;

  bool get isNoData => sentinel == 'NO_DATA';
  bool get isRetrievalFailed => sentinel == 'RETRIEVAL_FAILED';
  bool get isDegraded => degraded;
}

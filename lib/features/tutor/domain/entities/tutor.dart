import 'package:meta/meta.dart';

// Shared learning read models live in shared/domain so tutor and coaching
// do not import each other. Re-exported for existing tutor consumers.
export '../../../../shared/domain/learning_read_models.dart';

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
    this.title,
    this.tasks = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.summary,
    this.isCompleted = false,
  });

  final DateTime date;

  /// Null when the server did not name the section — the screen renders the
  /// localized "Today" instead of a hardcoded default living here.
  final String? title;
  final List<String> tasks;
  final int completedCount;
  final int totalCount;
  final String? summary;
  final bool isCompleted;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
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

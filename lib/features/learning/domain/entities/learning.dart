import 'package:meta/meta.dart';

@immutable
class LearningTrack {
  const LearningTrack({
    required this.id,
    required this.title,
    this.description,
    this.trackType,
    this.status,
    this.syllabusNodesCount,
    this.goalsCount,
    this.slug,
  });

  final int id;
  final String title;
  final String? description;
  final String? trackType;
  final String? status;
  final int? syllabusNodesCount;
  final int? goalsCount;
  final String? slug;

  String get displayType => trackType ?? 'track';
  // Backward compat for old screens expecting `name`
  String get name => title;
}

@immutable
class LearningTrackRef {
  const LearningTrackRef({required this.id, required this.title, this.trackType});
  final int id;
  final String title;
  final String? trackType;
}

@immutable
class LearningGoal {
  const LearningGoal({
    required this.id,
    required this.trackId,
    this.track,
    this.targetDate,
    this.dailyMinutes,
    this.intensity,
    this.placementMeta,
    this.status,
  });

  final int id;
  final int trackId;
  final LearningTrackRef? track;
  final DateTime? targetDate;
  final int? dailyMinutes;
  final String? intensity;
  final Map<String, dynamic>? placementMeta;
  final String? status;

  bool get isActive => status == 'active';
}

@immutable
class LearningGoalReadiness {
  const LearningGoalReadiness({
    required this.goalId,
    required this.readiness,
    required this.topicCount,
  });

  final int goalId;
  final int readiness; // 0-100
  final int topicCount;

  double get readinessFraction => readiness / 100.0;
}

@immutable
class DailyPlanItem {
  const DailyPlanItem({
    required this.type,
    required this.id,
    required this.label,
    this.estimatedMinutes = 0,
    this.completed = false,
    this.raw,
  });

  final String type; // review | topic | etc
  final int id;
  final String label;
  final int estimatedMinutes;
  final bool completed;
  final Map<String, dynamic>? raw;
}

@immutable
class DailyPlan {
  const DailyPlan({
    required this.id,
    required this.goalId,
    required this.planDate,
    this.items = const [],
    this.minutesBudget,
    this.status,
    this.completedItems = 0,
  });

  final int id;
  final int goalId;
  final DateTime planDate;
  final List<DailyPlanItem> items;
  final int? minutesBudget;
  final String? status;
  final int completedItems;

  int get totalItems => items.length;
  int get pendingItems => items.where((e) => !e.completed).length;
  double get progress => totalItems == 0 ? 0 : completedItems / totalItems;
  bool get isCompleted => status == 'completed' || (totalItems > 0 && completedItems >= totalItems);
}

@immutable
class KnowledgeAtomRef {
  const KnowledgeAtomRef({this.id, this.title, this.content});
  final int? id;
  final String? title;
  final String? content;
}

@immutable
class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.knowledgeAtomId,
    this.knowledgeAtom,
    required this.dueAt,
    this.intervalIndex,
    this.state,
    this.lapses,
  });

  final int id;
  final int knowledgeAtomId;
  final KnowledgeAtomRef? knowledgeAtom;
  final DateTime dueAt;
  final int? intervalIndex;
  final String? state;
  final int? lapses;

  bool get isOverdue => DateTime.now().isAfter(dueAt);
}

@immutable
class TutorReply {
  const TutorReply({
    required this.hint,
    required this.workedExample,
    required this.confidence,
    required this.nextStep,
  });

  final String hint;
  final String workedExample;
  final double confidence;
  final String nextStep;
}

// Backward compatibility aliases kept for old learning_home_screen
@immutable
class TodayPlan {
  const TodayPlan({required this.id, required this.title, this.tasks = const []});
  final String id;
  final String title;
  final List<String> tasks;
}

@immutable
class TutorMessage {
  const TutorMessage({required this.role, required this.content});
  final String role;
  final String content;
}

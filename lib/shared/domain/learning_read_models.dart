/// Cross-feature learning read models.
///
/// These are projections of server-authored learning analytics, not entities
/// owned by the tutor feature. Both tutor and coaching consume them, so they
/// live in `shared/domain` to keep features from importing one another.
library;

import 'package:meta/meta.dart';

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

/// The narrow slice of learning analytics other features need. Declared here
/// so a consumer depends on a shared contract, not on the tutor feature.
abstract class LearningAnalyticsSource {
  Future<List<WeakArea>> getWeakAreas();
  Future<ProjectedScore?> getProjectedScore();
  Future<WeeklyReport?> getWeeklyReport();
  Future<List<RevisionItem>> getRevisionsDue();
}

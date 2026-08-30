// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types

import '../../domain/entities/coaching.dart';
import '../../../tutor/domain/entities/tutor.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  if (v is num) return v.toDouble();
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is DateTime) return v;
  return null;
}

List<String> _asStringList(Object? v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  return [];
}

class ReadinessDto {
  const ReadinessDto({
    required this.goalId,
    this.score,
    this.level,
    this.breakdown = const {},
    this.missingTopics = const [],
    this.nextSteps = const [],
    this.updatedAt,
  });

  factory ReadinessDto.fromJson(String goalId, Map<String, dynamic> j) {
    // Tolerant: readiness may be under 'readiness' or j itself
    final src = j['readiness'] is Map<String, dynamic>
        ? j['readiness'] as Map<String, dynamic>
        : j['data'] is Map<String, dynamic>
            ? j['data'] as Map<String, dynamic>
            : j;
    return ReadinessDto(
      goalId: goalId,
      score: _asDouble(src['score'] ?? src['readiness_score'] ?? src['readiness'] ?? src['percentage']),
      level: src['level'] as String? ?? src['readiness_level'] as String?,
      breakdown: (src['breakdown'] as Map<String, dynamic>?) ?? (src['details'] as Map<String, dynamic>?) ?? {},
      missingTopics: _asStringList(src['missing_topics'] ?? src['weak_topics'] ?? src['gaps']),
      nextSteps: _asStringList(src['next_steps'] ?? src['recommendations'] ?? src['actions']),
      updatedAt: _asDate(src['updated_at'] ?? src['created_at']),
    );
  }

  final String goalId;
  final double? score;
  final String? level;
  final Map<String, dynamic> breakdown;
  final List<String> missingTopics;
  final List<String> nextSteps;
  final DateTime? updatedAt;

  Readiness toDomain() => Readiness(
        goalId: goalId,
        score: score,
        level: level,
        breakdown: breakdown,
        missingTopics: missingTopics,
        nextSteps: nextSteps,
        updatedAt: updatedAt,
      );
}

class CoachingTrackDto {
  const CoachingTrackDto({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
  });

  factory CoachingTrackDto.fromJson(Map<String, dynamic> j) => CoachingTrackDto(
        id: (j['id'] ?? j['slug'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        name: (j['name'] ?? j['title'] ?? '').toString(),
        description: j['description'] as String?,
      );

  final String id;
  final String slug;
  final String name;
  final String? description;

  CoachingTrack toDomain() => CoachingTrack(id: id, slug: slug, name: name, description: description);
}

class CoachingTodayDto {
  const CoachingTodayDto({
    required this.date,
    this.title = 'Today',
    this.tasks = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.summary,
  });

  factory CoachingTodayDto.fromJson(Map<String, dynamic> j) {
    final src = j['today'] is Map<String, dynamic> ? j['today'] as Map<String, dynamic> : j;
    final tasks = _asStringList(src['tasks'] ?? src['items'] ?? src['plan'] ?? src['activities']);
    return CoachingTodayDto(
      date: _asDate(src['date'] ?? src['due_at']) ?? DateTime.now(),
      title: (src['title'] ?? src['name'] ?? 'Today').toString(),
      tasks: tasks,
      completedCount: _asInt(src['completed_count'] ?? src['completed']) ?? 0,
      totalCount: _asInt(src['total_count'] ?? src['total'] ?? tasks.length) ?? tasks.length,
      summary: src['summary'] as String?,
    );
  }

  final DateTime date;
  final String title;
  final List<String> tasks;
  final int completedCount;
  final int totalCount;
  final String? summary;

  CoachingToday toDomain() => CoachingToday(
        date: date,
        title: title,
        tasks: tasks,
        completedCount: completedCount,
        totalCount: totalCount,
        summary: summary,
      );
}

// Re-export helpers for coaching's aggregated use

class CoachingDashboardDto {
  const CoachingDashboardDto({
    this.readiness,
    this.today,
    this.tracks = const [],
    this.weakAreas = const [],
    this.projectedScore,
    this.weeklyReport,
    this.revisionsDue = const [],
  });

  // This DTO is never parsed from a single endpoint; it's assembled
  // client-side from multiple calls. So fromJson is not used directly.
  final ReadinessDto? readiness;
  final CoachingTodayDto? today;
  final List<CoachingTrackDto> tracks;
  final List<WeakArea> weakAreas;
  final ProjectedScore? projectedScore;
  final WeeklyReport? weeklyReport;
  final List<RevisionItem> revisionsDue;
}

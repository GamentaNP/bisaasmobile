// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types, unnecessary_cast

import '../../domain/entities/tutor.dart';

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
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

List<String> _asStringList(Object? v) {
  if (v == null) return [];
  if (v is List) {
    return v.map((e) {
      if (e == null) return '';
      if (e is String) return e;
      if (e is Map && e['title'] != null) return e['title'].toString();
      if (e is Map && e['task'] != null) return e['task'].toString();
      if (e is Map && e['name'] != null) return e['name'].toString();
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
  }
  return [];
}

// ── TutorChat ───────────────────────────────────────────────────────────────

class TutorChatResponseDto {
  const TutorChatResponseDto({
    required this.answer,
    this.degraded = false,
    this.sentinel,
    this.citations = const [],
    this.messageId,
  });

  factory TutorChatResponseDto.fromJson(Map<String, dynamic> j) {
    // Tolerant: server may return {answer, response, content, message}
    // plus degraded flag and sentinel NO_DATA / RETRIEVAL_FAILED
    final ans = (j['answer'] ?? j['response'] ?? j['content'] ?? j['message'] ?? '').toString();
    final degraded = (j['degraded'] as bool?) ?? (j['is_degraded'] as bool?) ?? false;
    final sentinel = (j['sentinel'] as String?) ?? (j['status'] as String?) ?? (j['code'] as String?);
    // Normalize sentinel to canonical values only
    String? normSentinel;
    if (sentinel == 'NO_DATA' || sentinel == 'RETRIEVAL_FAILED') {
      normSentinel = sentinel;
    } else if (j['no_data'] == true) {
      normSentinel = 'NO_DATA';
    } else if (j['retrieval_failed'] == true) {
      normSentinel = 'RETRIEVAL_FAILED';
    }
    final citsRaw = j['citations'] ?? j['sources'] ?? [];
    final cits = citsRaw is List ? citsRaw.map((e) => e.toString()).toList() : <String>[];
    return TutorChatResponseDto(
      answer: ans,
      degraded: degraded,
      sentinel: normSentinel,
      citations: cits,
      messageId: (j['id'] ?? j['message_id'])?.toString(),
    );
  }

  final String answer;
  final bool degraded;
  final String? sentinel;
  final List<String> citations;
  final String? messageId;

  TutorChatResult toDomain() => TutorChatResult(
        answer: answer,
        degraded: degraded,
        sentinel: sentinel,
        citations: citations,
        messageId: messageId,
      );
}

// ── Legacy tutor (POST /learning/tutor) ────────────────────────────────────

class LegacyTutorDto {
  const LegacyTutorDto({required this.answer, this.degraded = false});
  factory LegacyTutorDto.fromJson(Map<String, dynamic> j) {
    final ans = (j['answer'] ?? j['response'] ?? j['content'] ?? j['message'] ?? '').toString();
    return LegacyTutorDto(
      answer: ans,
      degraded: (j['degraded'] as bool?) ?? false,
    );
  }

  final String answer;
  final bool degraded;
}

// ── TutorPlan ───────────────────────────────────────────────────────────────

class TutorPlanDayDto {
  const TutorPlanDayDto({
    required this.dayIndex,
    required this.title,
    this.description,
    this.tasks = const [],
    this.completed = false,
    this.isCurrent = false,
    this.dueAt,
  });

  factory TutorPlanDayDto.fromJson(Map<String, dynamic> j) {
    return TutorPlanDayDto(
      dayIndex: _asInt(j['day_index'] ?? j['day'] ?? j['index']) ?? 0,
      title: (j['title'] ?? j['name'] ?? 'Day ${j['day_index'] ?? ''}').toString(),
      description: j['description'] as String?,
      tasks: _asStringList(j['tasks'] ?? j['items'] ?? j['activities']),
      completed: (j['completed'] as bool?) ?? (j['is_completed'] as bool?) ?? false,
      isCurrent: (j['is_current'] as bool?) ?? (j['current'] as bool?) ?? false,
      dueAt: _asDate(j['due_at'] ?? j['date']),
    );
  }

  final int dayIndex;
  final String title;
  final String? description;
  final List<String> tasks;
  final bool completed;
  final bool isCurrent;
  final DateTime? dueAt;

  TutorPlanDay toDomain() => TutorPlanDay(
        dayIndex: dayIndex,
        title: title,
        description: description,
        tasks: tasks,
        completed: completed,
        isCurrent: isCurrent,
        dueAt: dueAt,
      );
}

class TutorPlanDto {
  const TutorPlanDto({
    required this.id,
    required this.title,
    this.description,
    this.totalDays = 0,
    this.days = const [],
    this.currentDayIndex,
    this.createdAt,
    this.updatedAt,
  });

  factory TutorPlanDto.fromJson(Map<String, dynamic> j) {
    // Tolerant: plan may be under j['plan'] or j itself.
    final src = j['plan'] is Map<String, dynamic> ? j['plan'] as Map<String, dynamic> : j;
    final rawDays = src['days'] ?? src['plan_days'] ?? src['items'] ?? [];
    List<TutorPlanDayDto> days = [];
    if (rawDays is List) {
      days = rawDays.whereType<Map<String, dynamic>>().map(TutorPlanDayDto.fromJson).toList();
    }
    return TutorPlanDto(
      id: (src['id'] ?? src['plan_id'] ?? 'plan').toString(),
      title: (src['title'] ?? src['name'] ?? 'Study Plan').toString(),
      description: src['description'] as String?,
      totalDays: _asInt(src['total_days'] ?? src['totalDays'] ?? days.length) ?? days.length,
      days: days,
      currentDayIndex: _asInt(src['current_day'] ?? src['current_day_index']),
      createdAt: _asDate(src['created_at']),
      updatedAt: _asDate(src['updated_at']),
    );
  }

  final String id;
  final String title;
  final String? description;
  final int totalDays;
  final List<TutorPlanDayDto> days;
  final int? currentDayIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TutorPlan toDomain() => TutorPlan(
        id: id,
        title: title,
        description: description,
        totalDays: totalDays,
        days: days.map((d) => d.toDomain()).toList(),
        currentDayIndex: currentDayIndex,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ── TutorToday ──────────────────────────────────────────────────────────────

class TutorTodayDto {
  const TutorTodayDto({
    required this.date,
    this.title = 'Today',
    this.tasks = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.summary,
    this.isCompleted = false,
  });

  factory TutorTodayDto.fromJson(Map<String, dynamic> j) {
    final src = j['today'] is Map<String, dynamic> ? j['today'] as Map<String, dynamic> : j;
    final tasks = _asStringList(src['tasks'] ?? src['items'] ?? src['plan'] ?? src['activities']);
    return TutorTodayDto(
      date: _asDate(src['date'] ?? src['due_at']) ?? DateTime.now(),
      title: (src['title'] ?? src['name'] ?? 'Today').toString(),
      tasks: tasks,
      completedCount: _asInt(src['completed_count'] ?? src['completed']) ?? 0,
      totalCount: _asInt(src['total_count'] ?? src['total'] ?? tasks.length) ?? tasks.length,
      summary: src['summary'] as String?,
      isCompleted: (src['is_completed'] as bool?) ?? (src['completed'] as bool?) ?? false,
    );
  }

  final DateTime date;
  final String title;
  final List<String> tasks;
  final int completedCount;
  final int totalCount;
  final String? summary;
  final bool isCompleted;

  TutorToday toDomain() => TutorToday(
        date: date,
        title: title,
        tasks: tasks,
        completedCount: completedCount,
        totalCount: totalCount,
        summary: summary,
        isCompleted: isCompleted,
      );
}

// ── WeakAreas ───────────────────────────────────────────────────────────────

class WeakAreaDto {
  const WeakAreaDto({
    required this.topic,
    this.topicId,
    this.slug,
    this.accuracy,
    this.attempts = 0,
    this.recommendation,
    this.reason,
  });

  factory WeakAreaDto.fromJson(Map<String, dynamic> j) => WeakAreaDto(
        topic: (j['topic'] ?? j['name'] ?? j['title'] ?? '').toString(),
        topicId: (j['topic_id'] ?? j['id'])?.toString(),
        slug: (j['slug'] as String?) ?? (j['topic_slug'] as String?),
        accuracy: _asDouble(j['accuracy'] ?? j['score'] ?? j['correct_rate']),
        attempts: _asInt(j['attempts'] ?? j['count']) ?? 0,
        recommendation: j['recommendation'] as String? ?? j['suggestion'] as String?,
        reason: j['reason'] as String? ?? j['weak_reason'] as String?,
      );

  final String topic;
  final String? topicId;
  final String? slug;
  final double? accuracy;
  final int attempts;
  final String? recommendation;
  final String? reason;

  WeakArea toDomain() => WeakArea(
        topic: topic,
        topicId: topicId,
        slug: slug,
        accuracy: accuracy,
        attempts: attempts,
        recommendation: recommendation,
        reason: reason,
      );
}

// ── ProjectedScore ──────────────────────────────────────────────────────────

class ProjectedScoreDto {
  const ProjectedScoreDto({
    required this.score,
    this.maxScore = 100,
    this.confidence,
    this.breakdown = const {},
    this.trend,
    this.updatedAt,
  });

  factory ProjectedScoreDto.fromJson(Map<String, dynamic> j) {
    // Source may be nested under 'projected_score' or 'data'
    final src = j['projected_score'] is Map<String, dynamic>
        ? j['projected_score'] as Map<String, dynamic>
        : j['score'] is Map<String, dynamic>
            ? j['score'] as Map<String, dynamic>
            : j;
    return ProjectedScoreDto(
      score: _asDouble(src['score'] ?? src['projected'] ?? src['value']) ?? 0,
      maxScore: _asDouble(src['max_score'] ?? src['maxScore'] ?? src['total']) ?? 100,
      confidence: _asDouble(src['confidence']),
      breakdown: (src['breakdown'] as Map<String, dynamic>?) ?? (src['details'] as Map<String, dynamic>?) ?? {},
      trend: src['trend'] as String?,
      updatedAt: _asDate(src['updated_at'] ?? src['created_at']),
    );
  }

  final double score;
  final double maxScore;
  final double? confidence;
  final Map<String, dynamic> breakdown;
  final String? trend;
  final DateTime? updatedAt;

  ProjectedScore toDomain() => ProjectedScore(
        score: score,
        maxScore: maxScore,
        confidence: confidence,
        breakdown: breakdown,
        trend: trend,
        updatedAt: updatedAt,
      );
}

// ── WeeklyReport ────────────────────────────────────────────────────────────

class WeeklyReportDto {
  const WeeklyReportDto({
    this.weekStart,
    this.weekEnd,
    this.tasksCompleted = 0,
    this.tasksPlanned = 0,
    this.averageScore,
    this.summary,
    this.insights = const [],
    this.hoursStudied,
  });

  factory WeeklyReportDto.fromJson(Map<String, dynamic> j) {
    final src = j['weekly_report'] is Map<String, dynamic>
        ? j['weekly_report'] as Map<String, dynamic>
        : j['report'] is Map<String, dynamic>
            ? j['report'] as Map<String, dynamic>
            : j;
    return WeeklyReportDto(
      weekStart: _asDate(src['week_start'] ?? src['start_date']),
      weekEnd: _asDate(src['week_end'] ?? src['end_date']),
      tasksCompleted: _asInt(src['tasks_completed'] ?? src['completed']) ?? 0,
      tasksPlanned: _asInt(src['tasks_planned'] ?? src['planned'] ?? src['total']) ?? 0,
      averageScore: _asDouble(src['average_score'] ?? src['avg_score']),
      summary: src['summary'] as String? ?? src['content'] as String?,
      insights: _asStringList(src['insights'] ?? src['highlights']),
      hoursStudied: _asDouble(src['hours_studied'] ?? src['hours']),
    );
  }

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final int tasksCompleted;
  final int tasksPlanned;
  final double? averageScore;
  final String? summary;
  final List<String> insights;
  final double? hoursStudied;

  WeeklyReport toDomain() => WeeklyReport(
        weekStart: weekStart,
        weekEnd: weekEnd,
        tasksCompleted: tasksCompleted,
        tasksPlanned: tasksPlanned,
        averageScore: averageScore,
        summary: summary,
        insights: insights,
        hoursStudied: hoursStudied,
      );
}

// ── RevisionsDue ────────────────────────────────────────────────────────────

class RevisionItemDto {
  const RevisionItemDto({
    required this.id,
    required this.questionId,
    required this.dueAt,
    this.topic,
    this.title,
    this.priority,
  });

  factory RevisionItemDto.fromJson(Map<String, dynamic> j) => RevisionItemDto(
        id: (j['id'] ?? j['revision_id'] ?? '').toString(),
        questionId: (j['question_id'] ?? j['questionId'] ?? j['id'] ?? '').toString(),
        dueAt: _asDate(j['due_at'] ?? j['dueAt'] ?? j['due_date']) ?? DateTime.now(),
        topic: j['topic'] as String? ?? j['subject'] as String?,
        title: j['title'] as String? ?? j['question_title'] as String?,
        priority: j['priority'] as String?,
      );

  final String id;
  final String questionId;
  final DateTime dueAt;
  final String? topic;
  final String? title;
  final String? priority;

  RevisionItem toDomain() => RevisionItem(
        id: id,
        questionId: questionId,
        dueAt: dueAt,
        topic: topic,
        title: title,
        priority: priority,
      );
}

// ── Onboarding ──────────────────────────────────────────────────────────────

class TutorOnboardingStartDto {
  const TutorOnboardingStartDto({
    required this.sessionId,
    this.prompt,
    this.stage,
  });

  factory TutorOnboardingStartDto.fromJson(Map<String, dynamic> j) {
    final src = j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;
    return TutorOnboardingStartDto(
      sessionId: (src['session_id'] ?? src['sessionId'] ?? src['id'] ?? '').toString(),
      prompt: src['prompt'] as String? ?? src['message'] as String?,
      stage: src['stage'] as String? ?? src['step'] as String?,
    );
  }

  final String sessionId;
  final String? prompt;
  final String? stage;

  TutorOnboardingSession toDomain() => TutorOnboardingSession(
        sessionId: sessionId,
        prompt: prompt,
        stage: stage,
      );
}

class TutorOnboardingCompleteDto {
  const TutorOnboardingCompleteDto({this.success = true, this.message});

  factory TutorOnboardingCompleteDto.fromJson(Map<String, dynamic> j) => TutorOnboardingCompleteDto(
        success: (j['success'] as bool?) ?? true,
        message: j['message'] as String?,
      );

  final bool success;
  final String? message;
}

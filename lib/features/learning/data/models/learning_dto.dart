// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types, unnecessary_cast, dead_code, noop_primitive_operations, unnecessary_type_check
import '../../domain/entities/learning.dart';

// ── helpers ───────────────────────────────────────────────────────────────────
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

// ── LearningTrack ─────────────────────────────────────────────────────────────

class LearningTrackDto {
  const LearningTrackDto({
    required this.id,
    required this.title,
    this.description,
    this.trackType,
    this.status,
    this.syllabusNodesCount,
    this.goalsCount,
    this.slug,
  });

  factory LearningTrackDto.fromJson(Map<String, dynamic> j) {
    // tolerant: server sends {id, title, description, track_type, status, syllabus_nodes_count, goals_count}
    // or {id, slug, name, trackType}. Ignore unknown keys.
    final id = _asInt(j['id']) ?? 0;
    final title = (j['title'] ?? j['name'] ?? j['slug'] ?? '').toString();
    return LearningTrackDto(
      id: id,
      title: title,
      description: j['description'] as String?,
      trackType: (j['track_type'] as String?) ?? (j['trackType'] as String?),
      status: j['status'] as String?,
      syllabusNodesCount: _asInt(j['syllabus_nodes_count']),
      goalsCount: _asInt(j['goals_count']),
      slug: (j['slug'] as String?) ?? (j['track_type'] as String?),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String? trackType;
  final String? status;
  final int? syllabusNodesCount;
  final int? goalsCount;
  final String? slug;

  LearningTrack toDomain() => LearningTrack(
        id: id,
        title: title,
        description: description,
        trackType: trackType,
        status: status,
        syllabusNodesCount: syllabusNodesCount,
        goalsCount: goalsCount,
        slug: slug,
      );
}

// ── LearningGoal ──────────────────────────────────────────────────────────────

class LearningTrackRefDto {
  const LearningTrackRefDto({required this.id, required this.title, this.trackType});
  factory LearningTrackRefDto.fromJson(Map<String, dynamic> j) => LearningTrackRefDto(
        id: _asInt(j['id']) ?? 0,
        title: (j['title'] ?? j['name'] ?? '').toString(),
        trackType: (j['track_type'] as String?) ?? (j['trackType'] as String?),
      );
  final int id;
  final String title;
  final String? trackType;
  LearningTrackRef toDomain() => LearningTrackRef(id: id, title: title, trackType: trackType);
}

class LearningGoalDto {
  const LearningGoalDto({
    required this.id,
    required this.trackId,
    this.track,
    this.targetDate,
    this.dailyMinutes,
    this.intensity,
    this.placementMeta,
    this.status,
  });

  factory LearningGoalDto.fromJson(Map<String, dynamic> j) {
    final trackRaw = j['track'];
    LearningTrackRefDto? track;
    if (trackRaw is Map<String, dynamic>) {
      track = LearningTrackRefDto.fromJson(trackRaw);
    }
    Map<String, dynamic>? placement;
    final pm = j['placement_meta'] ?? j['placementMeta'];
    if (pm is Map<String, dynamic>) placement = pm;
    if (pm is Map) placement = pm.cast<String, dynamic>();

    return LearningGoalDto(
      id: _asInt(j['id']) ?? 0,
      trackId: _asInt(j['track_id'] ?? j['trackId']) ?? 0,
      track: track,
      targetDate: _asDate(j['target_date'] ?? j['targetDate']),
      dailyMinutes: _asInt(j['daily_minutes'] ?? j['dailyMinutes']),
      intensity: (j['intensity'] as String?)?.toString(),
      placementMeta: placement,
      status: (j['status'] as String?)?.toString(),
    );
  }

  final int id;
  final int trackId;
  final LearningTrackRefDto? track;
  final DateTime? targetDate;
  final int? dailyMinutes;
  final String? intensity;
  final Map<String, dynamic>? placementMeta;
  final String? status;

  LearningGoal toDomain() => LearningGoal(
        id: id,
        trackId: trackId,
        track: track?.toDomain(),
        targetDate: targetDate,
        dailyMinutes: dailyMinutes,
        intensity: intensity,
        placementMeta: placementMeta,
        status: status,
      );
}

class LearningGoalReadinessDto {
  const LearningGoalReadinessDto({required this.goalId, required this.readiness, required this.topicCount});
  factory LearningGoalReadinessDto.fromJson(Map<String, dynamic> j) => LearningGoalReadinessDto(
        goalId: _asInt(j['goal_id'] ?? j['goalId']) ?? 0,
        readiness: _asInt(j['readiness']) ?? 0,
        topicCount: _asInt(j['topic_count'] ?? j['topicCount']) ?? 0,
      );
  final int goalId;
  final int readiness;
  final int topicCount;
  LearningGoalReadiness toDomain() => LearningGoalReadiness(goalId: goalId, readiness: readiness, topicCount: topicCount);
}

// ── DailyPlan ─────────────────────────────────────────────────────────────────

class DailyPlanItemDto {
  const DailyPlanItemDto({
    required this.type,
    required this.id,
    required this.label,
    this.estimatedMinutes = 0,
    this.completed = false,
    this.raw,
  });

  factory DailyPlanItemDto.fromJson(Map<String, dynamic> j) {
    return DailyPlanItemDto(
      type: (j['type'] as String?) ?? 'unknown',
      id: _asInt(j['id']) ?? 0,
      label: (j['label'] as String?) ?? (j['title'] as String?) ?? '',
      estimatedMinutes: _asInt(j['estimated_minutes'] ?? j['estimatedMinutes']) ?? 0,
      completed: (j['completed'] as bool?) ?? false,
      raw: j,
    );
  }

  final String type;
  final int id;
  final String label;
  final int estimatedMinutes;
  final bool completed;
  final Map<String, dynamic>? raw;

  DailyPlanItem toDomain() => DailyPlanItem(
        type: type,
        id: id,
        label: label,
        estimatedMinutes: estimatedMinutes,
        completed: completed,
        raw: raw,
      );
}

class DailyPlanDto {
  const DailyPlanDto({
    required this.id,
    required this.goalId,
    required this.planDate,
    this.items = const [],
    this.minutesBudget,
    this.status,
    this.completedItems = 0,
  });

  factory DailyPlanDto.fromJson(Map<String, dynamic> j) {
    // Server shape: {id, goal_id, plan_date, items:[{type,id,label,estimated_minutes,completed}], minutes_budget, status, completed_items}
    // Also handle legacy shape where data may be under j['today'] or j itself, and items may be strings.
    final src = j['today'] is Map<String, dynamic> ? j['today'] as Map<String, dynamic> : j;
    final rawItems = src['items'] ?? src['tasks'] ?? src['plan'] ?? [];
    List<DailyPlanItemDto> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) {
        if (e is String) {
          return DailyPlanItemDto(type: 'task', id: 0, label: e, estimatedMinutes: 0, completed: false, raw: {'label': e});
        }
        if (e is Map<String, dynamic>) {
          // Ensure label fallback to title if missing.
          return DailyPlanItemDto.fromJson(e);
        }
        if (e is Map) {
          return DailyPlanItemDto.fromJson(e.cast<String, dynamic>());
        }
        return DailyPlanItemDto(type: 'unknown', id: 0, label: e.toString(), raw: {});
      }).toList();
    }

    // id may be string or int; goal_id similar. Provide defaults.
    final id = _asInt(src['id'] ?? src['plan_id'] ?? 0) ?? 0;
    final goalId = _asInt(src['goal_id'] ?? src['goalId'] ?? 0) ?? 0;
    final planDate = _asDate(src['plan_date'] ?? src['planDate'] ?? src['date']) ?? DateTime.now();

    return DailyPlanDto(
      id: id,
      goalId: goalId,
      planDate: planDate,
      items: items,
      minutesBudget: _asInt(src['minutes_budget']),
      status: src['status'] as String?,
      completedItems: _asInt(src['completed_items']) ?? items.where((e) => e.completed).length,
    );
  }

  final int id;
  final int goalId;
  final DateTime planDate;
  final List<DailyPlanItemDto> items;
  final int? minutesBudget;
  final String? status;
  final int completedItems;

  DailyPlan toDomain() => DailyPlan(
        id: id,
        goalId: goalId,
        planDate: planDate,
        items: items.map((e) => e.toDomain()).toList(),
        minutesBudget: minutesBudget,
        status: status,
        completedItems: completedItems,
      );
}

// Legacy TodayPlan DTO for backward compatibility with learning_home_screen's TodayPlanDto usage
class TodayPlanDtoLegacy {
  const TodayPlanDtoLegacy({required this.id, required this.title, this.tasks = const []});
  factory TodayPlanDtoLegacy.fromJson(Map<String, dynamic> j) {
    final rawTasks = j['tasks'] ?? j['items'] ?? j['plan'] ?? [];
    final tasks = rawTasks is List
        ? rawTasks
            .map((e) => e is String
                ? e
                : (e is Map ? (e['title'] ?? e['label'] ?? e.toString()).toString() : e.toString()))
            .cast<String>()
            .toList()
        : <String>[];
    return TodayPlanDtoLegacy(
      id: (j['id'] ?? j['plan_id'] ?? 'today').toString(),
      title: (j['title'] ?? j['name'] ?? 'Today').toString(),
      tasks: tasks.cast<String>(),
    );
  }

  final String id;
  final String title;
  final List<String> tasks;
  TodayPlan toDomain() => TodayPlan(id: id, title: title, tasks: tasks);
}

// ── Reviews ───────────────────────────────────────────────────────────────────

class KnowledgeAtomRefDto {
  const KnowledgeAtomRefDto({this.id, this.title, this.content});
  factory KnowledgeAtomRefDto.fromJson(Map<String, dynamic> j) => KnowledgeAtomRefDto(
        id: _asInt(j['id']),
        title: _extractTitle(j['title']),
        content: j['content'] as String?,
      );

  static String? _extractTitle(Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      // title may be {en: "..."} per DailyPlanBuilder
      if (v['en'] is String) return v['en'] as String;
      if (v['title'] is String) return v['title'] as String;
      return v.values.firstOrNull?.toString();
    }
    return v.toString();
  }

  final int? id;
  final String? title;
  final String? content;

  KnowledgeAtomRef toDomain() => KnowledgeAtomRef(id: id, title: title, content: content);
}

class ReviewItemDto {
  const ReviewItemDto({
    required this.id,
    required this.knowledgeAtomId,
    this.knowledgeAtom,
    required this.dueAt,
    this.intervalIndex,
    this.state,
    this.lapses,
  });

  factory ReviewItemDto.fromJson(Map<String, dynamic> j) {
    final atomRaw = j['knowledge_atom'] ?? j['knowledgeAtom'];
    KnowledgeAtomRefDto? atom;
    if (atomRaw is Map<String, dynamic>) {
      atom = KnowledgeAtomRefDto.fromJson(atomRaw);
    } else if (atomRaw is Map) {
      atom = KnowledgeAtomRefDto.fromJson(atomRaw.cast<String, dynamic>());
    }
    return ReviewItemDto(
      id: _asInt(j['id']) ?? 0,
      knowledgeAtomId: _asInt(j['knowledge_atom_id'] ?? j['knowledgeAtomId']) ?? 0,
      knowledgeAtom: atom,
      dueAt: _asDate(j['due_at'] ?? j['dueAt'] ?? j['due_date']) ?? DateTime.now(),
      intervalIndex: _asInt(j['interval_index']),
      state: j['state'] as String?,
      lapses: _asInt(j['lapses']),
    );
  }

  final int id;
  final int knowledgeAtomId;
  final KnowledgeAtomRefDto? knowledgeAtom;
  final DateTime dueAt;
  final int? intervalIndex;
  final String? state;
  final int? lapses;

  ReviewItem toDomain() => ReviewItem(
        id: id,
        knowledgeAtomId: knowledgeAtomId,
        knowledgeAtom: knowledgeAtom?.toDomain(),
        dueAt: dueAt,
        intervalIndex: intervalIndex,
        state: state,
        lapses: lapses,
      );
}

// ── Tutor (POST /learning/tutor non-streaming) ───────────────────────────────

class LearningTutorReplyDto {
  const LearningTutorReplyDto({
    required this.hint,
    required this.workedExample,
    required this.confidence,
    required this.nextStep,
  });

  factory LearningTutorReplyDto.fromJson(Map<String, dynamic> j) {
    // Server learning/tutor returns {ok, reply:{hint, worked_example, confidence, next_step}, meta}
    // or envelope {data:{reply...}} or direct reply map. Tolerant to all.
    Map<String, dynamic> src = j;
    if (j['reply'] is Map<String, dynamic>) {
      src = j['reply'] as Map<String, dynamic>;
    } else if (j['data'] is Map<String, dynamic> && (j['data'] as Map<String, dynamic>)['reply'] is Map<String, dynamic>) {
      src = (j['data'] as Map<String, dynamic>)['reply'] as Map<String, dynamic>;
    } else if (j['data'] is Map<String, dynamic> && j.containsKey('success')) {
      // Envelope with data being the reply directly
      final data = j['data'] as Map<String, dynamic>;
      if (data.containsKey('hint')) src = data;
    }

    // Alternate keys: socratic_hint, worked_example may be nested object {scenario, steps[], outcome_question}
    final hint = (src['hint'] ?? src['socratic_hint'] ?? '').toString();
    final weRaw = src['worked_example'] ?? src['workedExample'] ?? src['example'] ?? '';
    String weStr = '';
    if (weRaw is String) {
      weStr = weRaw;
    } else if (weRaw is Map) {
      final parts = <String>[];
      if (weRaw['scenario'] is String) parts.add(weRaw['scenario'] as String);
      if (weRaw['steps'] is List) {
        for (final s in weRaw['steps'] as List) {
          if (s is Map && (s['description'] ?? s['calculation']) is String) {
            parts.add('- ${(s['description'] ?? s['calculation']).toString()}');
          }
        }
      }
      final outcome = weRaw['outcome_question'] ?? weRaw['outcome'];
      if (outcome is String && outcome.isNotEmpty) parts.add(outcome);
      weStr = parts.join('\n');
    }

    return LearningTutorReplyDto(
      hint: hint,
      workedExample: weStr,
      confidence: _asDouble(src['confidence']) ?? 0,
      nextStep: (src['next_step'] ?? src['nextStep'] ?? src['recommended_action'] ?? 'try_again').toString(),
    );
  }

  final String hint;
  final String workedExample;
  final double confidence;
  final String nextStep;

  TutorReply toDomain() => TutorReply(hint: hint, workedExample: workedExample, confidence: confidence, nextStep: nextStep);
}

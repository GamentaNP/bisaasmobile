/// A server-published study-planner payload.
///
/// The coach / triage / sprint / weekly endpoints answer a payload whose shape
/// the server owns and evolves. Wrapping it rather than re-parsing it here is
/// deliberate: this entity is the domain's handle on that payload, and it does
/// not invent fields the response did not publish. The derived values below
/// (exam id, day rows, exam name, target date, days remaining) are the only
/// places that know the wire field names, so presentation never has to read the
/// raw map itself.
library;

class EicePayload {
  const EicePayload(this.raw);

  /// The untouched `data` object from the envelope. Presentation renders it
  /// verbatim through `PayloadView`, so no server field is lost on the way.
  final Map<String, dynamic> raw;

  /// `exam_id` is the server's own field on the coach payload. Both spellings
  /// are accepted because the server has published both over time; a string is
  /// parsed rather than guessed at.
  int? get examId {
    final value = raw['exam_id'] ?? raw['examId'] ?? _exam['id'];
    return _intOf(value);
  }

  /// The web planner publishes a combined plan spanning every enrolled course
  /// under `combined_daily_plan`. When that field is present it wins over the
  /// single-exam `daily_plan`, even when it is an empty list: an empty combined
  /// plan is a real answer, not a reason to fall back to stale single-exam rows.
  bool get hasCombinedDailyPlan => raw['combined_daily_plan'] is List;

  /// Up to seven day rows, read only through the published field names.
  List<StudyPlanDay> get dailyPlan {
    final source = hasCombinedDailyPlan
        ? raw['combined_daily_plan']
        : raw['daily_plan'];
    if (source is! List) return const <StudyPlanDay>[];
    return source
        .whereType<Map<String, dynamic>>()
        .map(StudyPlanDay.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> get _exam =>
      raw['exam'] is Map<String, dynamic>
          ? raw['exam'] as Map<String, dynamic>
          : const <String, dynamic>{};

  /// The server nests exam details under `exam` on the full plan and publishes
  /// `exam_name` directly on the coach payload. Both are its own fields.
  String? get examName => _stringOf(_exam['exam_name'] ?? raw['exam_name']);

  String? get targetDate =>
      _stringOf(_exam['target_date'] ?? raw['target_date']);

  int? get daysRemaining =>
      _intOf(raw['days_remaining'] ?? raw['days_to_exam']);
}

/// One day of the server's plan. The client never computes question counts or
/// rest days — it only presents the values the server published.
class StudyPlanDay {
  const StudyPlanDay({
    required this.date,
    required this.questionCount,
    required this.isRestDay,
    required this.allocations,
  });

  factory StudyPlanDay.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'];
    return StudyPlanDay(
      date: _stringOf(json['date']) ?? '',
      // The combined plan rolls several exams up into `total_question_count`;
      // the single-exam plan publishes `question_count`.
      questionCount:
          _intOf(json['question_count'] ?? json['total_question_count']) ?? 0,
      isRestDay: json['is_rest_day'] == true ||
          json['is_rest_day'] == 'true',
      allocations: rawAllocations is List
          ? rawAllocations
              .whereType<Map<String, dynamic>>()
              .map(StudyPlanAllocation.fromJson)
              .toList(growable: false)
          : const <StudyPlanAllocation>[],
    );
  }

  final String date;
  final int questionCount;
  final bool isRestDay;
  final List<StudyPlanAllocation> allocations;
}

/// One allocation chip inside a day. The combined plan also carries the owning
/// exam/course, so a course name is shown when the server published one.
class StudyPlanAllocation {
  const StudyPlanAllocation({
    required this.title,
    required this.progressPercent,
    required this.categoryName,
    required this.courseName,
  });

  factory StudyPlanAllocation.fromJson(Map<String, dynamic> json) {
    return StudyPlanAllocation(
      title: _stringOf(json['title']) ?? '',
      progressPercent: _intOf(json['progress_percent']) ?? 0,
      categoryName: _stringOf(json['category_name']),
      courseName:
          _stringOf(json['course_name'] ?? json['exam_name']),
    );
  }

  final String title;
  final int progressPercent;
  final String? categoryName;
  final String? courseName;

  /// The most specific published name wins; nothing is invented when neither
  /// field is present.
  String? get contextName => categoryName ?? courseName;
}

int? _intOf(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _stringOf(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

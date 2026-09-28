import '../../domain/entities/syllabus.dart';

/// Wire models for the Syllabus Engine.
///
/// Every `fromJson` is hand-written and defensive. The server is the only writer
/// of these payloads, but a missing optional key must degrade to a sensible
/// value rather than throw, because a syllabus screen that crashes on one
/// untranslatable title is worse than one that shows the English title.
///
/// Server resources verified against source:
/// - `app/Http/Resources/Api/Syllabus/SyllabusVersionResource.php`
/// - `app/Http/Resources/Api/Syllabus/SyllabusNodeResource.php`
/// - `app/Http/Resources/Api/Syllabus/UserSyllabusResource.php`
/// - `app/Domains/Quiz/Syllabus/Services/SyllabusTreeService.php` (summary, tree)

double? _toDoubleOrNull(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String? _toStrOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _toDateOrNull(Object? v) {
  final s = _toStrOrNull(v);
  if (s == null) return null;
  return DateTime.tryParse(s);
}

class SyllabusExamDto {
  const SyllabusExamDto(this.domain);
  final SyllabusExam domain;

  static SyllabusExamDto? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = _toStrOrNull(json['name']);
    if (id == null || name == null) return null;
    return SyllabusExamDto(SyllabusExam(
      id: _toInt(id),
      name: name,
      post: _toStrOrNull(json['post']),
      level: _toStrOrNull(json['level']),
      groupName: _toStrOrNull(json['group_name']),
      authority: _toStrOrNull(json['authority']),
    ));
  }
}

class SyllabusVersionDto {
  const SyllabusVersionDto(this.domain);
  final SyllabusVersion domain;

  /// Accepts either a bare resource object or an envelope row.
  static SyllabusVersionDto? fromJson(Map<String, dynamic> json) {
    final publicId = _toStrOrNull(json['public_id']);
    if (publicId == null) return null;
    final examJson = json['exam'];
    return SyllabusVersionDto(SyllabusVersion(
      publicId: publicId,
      versionCode: _toStrOrNull(json['version_code']) ?? publicId,
      title: _toStrOrNull(json['title']) ?? 'Untitled syllabus',
      titleNe: _toStrOrNull(json['title_ne']),
      status: _toStrOrNull(json['status']) ?? 'unknown',
      effectiveFrom: _toDateOrNull(json['effective_from']),
      effectiveTo: _toDateOrNull(json['effective_to']),
      effectiveWindow: _toStrOrNull(json['effective_window']),
      structureHash: _toStrOrNull(json['structure_hash']),
      nodeCount: _toInt(json['node_count']),
      examinableNodeCount: _toInt(json['examinable_node_count']),
      exam: examJson is Map<String, dynamic> ? SyllabusExamDto.fromJson(examJson)?.domain : null,
    ));
  }
}

class SyllabusNodeDto {
  const SyllabusNodeDto(this.domain);
  final SyllabusNode domain;

  static SyllabusNodeDto? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = _toStrOrNull(json['title']);
    if (id == null || title == null) return null;

    final childrenJson = json['children'];
    final children = <SyllabusNode>[];
    if (childrenJson is List) {
      for (final c in childrenJson) {
        if (c is! Map) continue;
        final parsed = fromJson(c.cast<String, dynamic>());
        // A child that fails to parse must not take the subtree with it: the
        // server's `nest()` already ordered these, so a dropped child leaves a
        // visible gap but keeps every sibling readable.
        if (parsed != null) children.add(parsed.domain);
      }
    }

    return SyllabusNodeDto(SyllabusNode(
      id: _toInt(id),
      title: title,
      titleNe: _toStrOrNull(json['title_ne']),
      nodeType: _toStrOrNull(json['node_type']) ?? 'unknown',
      depth: _toInt(json['depth']),
      nodeCode: _toStrOrNull(json['node_code']),
      displayCode: _toStrOrNull(json['display_code']),
      path: _toStrOrNull(json['path']),
      isExaminable: json['is_examinable'] == true,
      marksHint: _toDoubleOrNull(json['marks_hint']),
      needsReview: json['needs_review'] == true,
      sourceText: _toStrOrNull(json['source_text']),
      questionCount: _toInt(json['question_count']),
      materialCount: _toInt(json['material_count']),
      childCount: _toInt(json['child_count']),
      children: children,
    ));
  }
}

class SyllabusTreeDto {
  const SyllabusTreeDto(this.domain);
  final SyllabusTree domain;

  /// `GET /syllabi/{v}/tree` returns `{nodes, node_count, examinable_node_count}`.
  ///
  /// [depthLimited] is passed in by the caller because the payload does not say
  /// whether the counts were depth-scoped; only the request knows.
  factory SyllabusTreeDto.fromJson(Map<String, dynamic> json, {bool depthLimited = false}) {
    final nodesJson = json['nodes'];
    final nodes = <SyllabusNode>[];
    if (nodesJson is List) {
      for (final n in nodesJson) {
        if (n is! Map) continue;
        final parsed = SyllabusNodeDto.fromJson(n.cast<String, dynamic>());
        if (parsed != null) nodes.add(parsed.domain);
      }
    }
    return SyllabusTreeDto(SyllabusTree(
      nodes: nodes,
      nodeCount: _toInt(json['node_count']),
      examinableNodeCount: _toInt(json['examinable_node_count']),
      depthLimited: depthLimited,
    ));
  }
}

class SyllabusNodeDetailDto {
  const SyllabusNodeDetailDto(this.domain);
  final SyllabusNodeDetail? domain;

  /// True when the payload had no usable node, e.g. an error body.
  bool get isEmpty => domain == null;

  /// `GET /syllabi/{v}/nodes/{node}` returns `{node, coverage, children}`.
  factory SyllabusNodeDetailDto.fromJson(Map<String, dynamic> json) {
    final nodeJson = json['node'];
    if (nodeJson is! Map) return const SyllabusNodeDetailDto(null);
    final node = SyllabusNodeDto.fromJson(nodeJson.cast<String, dynamic>());
    if (node == null) return const SyllabusNodeDetailDto(null);

    final children = <SyllabusNode>[];
    final childrenJson = json['children'];
    if (childrenJson is List) {
      for (final c in childrenJson) {
        if (c is! Map) continue;
        final parsed = SyllabusNodeDto.fromJson(c.cast<String, dynamic>());
        if (parsed != null) children.add(parsed.domain);
      }
    }

    final coverageJson = json['coverage'];
    return SyllabusNodeDetailDto(SyllabusNodeDetail(
      node: node.domain,
      coverage: coverageJson is Map<String, dynamic> ? coverageJson : null,
      children: children,
    ));
  }
}

class SyllabusBlueprintRuleDto {
  const SyllabusBlueprintRuleDto(this.rule);
  final SyllabusBlueprintRule rule;

  static SyllabusBlueprintRuleDto? fromJson(Map<String, dynamic> json) {
    final nodeId = json['quiz_syllabus_node_id'];
    return SyllabusBlueprintRuleDto(SyllabusBlueprintRule(
      nodeId: nodeId == null ? null : _toInt(nodeId),
      nodeCode: _toStrOrNull(json['node_code']),
      nodeTitle: _toStrOrNull(json['node_title']),
      marksEach: _toDoubleOrNull(json['marks_each']) ?? 0,
      questionCount: _toInt(json['question_count']),
      weight: _toDoubleOrNull(json['weight']) ?? 0,
    ));
  }
}

class SyllabusBlueprintSectionDto {
  const SyllabusBlueprintSectionDto(this.section);
  final SyllabusBlueprintSection section;

  /// `section_code` is **nullable** in the real payload — the live API returns
  /// `null` for the unnamed trailing "Part II" — so a missing code must not
  /// cause the section to be dropped. Only the name is required, and the server
  /// always sends it.
  static SyllabusBlueprintSectionDto? fromJson(Map<String, dynamic> json) {
    final name = _toStrOrNull(json['name']);
    if (name == null) return null;
    return SyllabusBlueprintSectionDto(SyllabusBlueprintSection(
      sectionCode: _toStrOrNull(json['section_code']),
      name: name,
      // The server sends a precomputed `marks`; question_count * marks_each is
      // only derivable when the rules carry it, so the server value wins.
      marks: _toDoubleOrNull(json['marks']) ?? 0,
      questionCount: _toInt(json['question_count']),
    ));
  }
}

class SyllabusBlueprintDto {
  const SyllabusBlueprintDto(this.items);
  final List<SyllabusBlueprint> items;

  /// A version can define several papers, and the controller returns a **list**
  /// (`$blueprints` mapped), so this parses a list rather than a single object.
  factory SyllabusBlueprintDto.fromList(Object? json) {
    if (json is! List) return const SyllabusBlueprintDto([]);
    final out = <SyllabusBlueprint>[];
    for (final b in json) {
      if (b is! Map) continue;
      final map = b.cast<String, dynamic>();
      final code = _toStrOrNull(map['paper_code']);
      final name = _toStrOrNull(map['name']);
      if (code == null || name == null) continue;
      final sections = <SyllabusBlueprintSection>[];
      final sectionsJson = map['sections'];
      if (sectionsJson is List) {
        for (final s in sectionsJson) {
          if (s is! Map) continue;
          final parsed = SyllabusBlueprintSectionDto.fromJson(s.cast<String, dynamic>());
          if (parsed != null) sections.add(parsed.section);
        }
      }
      // `rules` sits on the paper, not on each section. Verified live on
      // 2026-09-28: one paper returned 13 rules and no section had any.
      final rules = <SyllabusBlueprintRule>[];
      final rulesJson = map['rules'];
      if (rulesJson is List) {
        for (final r in rulesJson) {
          if (r is! Map) continue;
          final parsed = SyllabusBlueprintRuleDto.fromJson(r.cast<String, dynamic>());
          if (parsed != null) rules.add(parsed.rule);
        }
      }
      out.add(SyllabusBlueprint(
        paperCode: code,
        partCode: _toStrOrNull(map['part_code']),
        name: name,
        totalMarks: _toDoubleOrNull(map['total_marks']) ?? 0,
        totalQuestions: _toInt(map['total_questions']),
        negativeMarkingMode: _toStrOrNull(map['negative_marking_mode']),
        unattemptedMarks: _toDoubleOrNull(map['unattempted_marks']) ?? 0,
        sections: sections,
        rules: rules,
      ));
    }
    return SyllabusBlueprintDto(out);
  }
}

class UserSyllabusPlanDto {
  const UserSyllabusPlanDto(this.domain);
  final UserSyllabusPlan domain;

  static UserSyllabusPlanDto? fromJson(Map<String, dynamic> json) {
    final publicId = _toStrOrNull(json['public_id']);
    if (publicId == null) return null;
    return UserSyllabusPlanDto(UserSyllabusPlan(
      publicId: publicId,
      nickname: _toStrOrNull(json['nickname']),
      syllabusVersionId: _toInt(json['syllabus_version_id']),
      versionCode: _toStrOrNull(json['version_code']),
      targetExamDate: _toDateOrNull(json['target_exam_date']),
      dailyMinutes: json['daily_minutes'] == null ? null : _toInt(json['daily_minutes']),
      planningMode: _toStrOrNull(json['planning_mode']) ?? 'unknown',
      scopeMode: _toStrOrNull(json['scope_mode']) ?? 'unknown',
      isActive: json['is_active'] != false,
      lastPlannedAt: _toDateOrNull(json['last_planned_at']),
    ));
  }
}

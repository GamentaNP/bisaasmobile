/// Syllabus domain entities — pure Dart, no Flutter.
///
/// Mirrors the server's Syllabus Engine (`C:\laragon\www\bisaas\app\Domains\Quiz\Syllabus`).
/// The tree is the navigation backbone for an exam product: a user picks a node
/// and sees what is under it and how many questions cover it.
library;

/// A versioned exam syllabus, e.g. "Loksewa Civil 2082".
///
/// [publicId] is the route key. The server binds `{version}` on
/// `SyllabusVersion::getRouteKeyName()`, which returns `public_id` (a ULID) —
/// **not** [versionCode], which is human-facing and not unique in practice.
class SyllabusVersion {
  const SyllabusVersion({
    required this.publicId,
    required this.versionCode,
    required this.title,
    required this.status,
    this.titleNe,
    this.effectiveFrom,
    this.effectiveTo,
    this.effectiveWindow,
    this.structureHash,
    this.nodeCount = 0,
    this.examinableNodeCount = 0,
    this.exam,
  });

  final String publicId;
  final String versionCode;
  final String title;
  final String status;
  final String? titleNe;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// Human label the server already computed, e.g. "2082/01/01 – 2083/12/31".
  final String? effectiveWindow;
  final String? structureHash;
  final int nodeCount;
  final int examinableNodeCount;
  final SyllabusExam? exam;

  /// The title in the reader's language, falling back to English.
  ///
  /// The server ships a Nepali title on the same row rather than a translations
  /// table, so this is a two-field choice rather than a lookup. Renders through
  /// `ScriptFonts` from the text, so it needs no locale of its own.
  String titleFor({required bool preferNative}) {
    if (preferNative && titleNe != null && titleNe!.trim().isNotEmpty) return titleNe!;
    return title;
  }

  /// A version is only worth offering as "current" while it is effective.
  bool get isEffectiveNow {
    final now = DateTime.now();
    if (effectiveFrom != null && now.isBefore(effectiveFrom!)) return false;
    if (effectiveTo != null && now.isAfter(effectiveTo!)) return false;
    return true;
  }
}

class SyllabusExam {
  const SyllabusExam({
    required this.id,
    required this.name,
    this.post,
    this.level,
    this.groupName,
    this.authority,
  });

  final int id;
  final String name;
  final String? post;
  final String? level;
  final String? groupName;
  final String? authority;
}

/// A node in the syllabus tree.
///
/// Counts are **subtree-inclusive** on the server: a parent's `questionCount`
/// is the union over its descendants, not just its own direct coverage. That is
/// the useful number for a user deciding where to start, so it is preserved
/// rather than recomputed.
class SyllabusNode {
  const SyllabusNode({
    required this.id,
    required this.title,
    required this.nodeType,
    required this.depth,
    this.nodeCode,
    this.displayCode,
    this.titleNe,
    this.path,
    this.isExaminable = false,
    this.marksHint,
    this.needsReview = false,
    this.sourceText,
    this.questionCount = 0,
    this.materialCount = 0,
    this.childCount = 0,
    this.children = const [],
  });

  final int id;
  final String title;
  final String nodeType;
  final int depth;
  final String? nodeCode;
  final String? displayCode;
  final String? titleNe;
  final String? path;
  final bool isExaminable;
  final double? marksHint;
  final bool needsReview;
  final String? sourceText;
  final int questionCount;
  final int materialCount;

  /// Direct children only, from the flat `nodes` summary endpoint.
  final int childCount;
  final List<SyllabusNode> children;

  bool get hasChildren => children.isNotEmpty || childCount > 0;

  /// A node with questions under it is worth tapping; a pure grouping node is not.
  bool get hasContent => questionCount > 0 || materialCount > 0;

  /// Marks per question, when the server supplied a hint.
  ///
  /// The field is named `marks_hint` because the blueprint is the authority on
  /// marks, so this is advisory and must not be presented as authoritative.
  String? get marksLabel {
    final m = marksHint;
    if (m == null) return null;
    return m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(2);
  }
}

/// Node detail, which adds coverage the list endpoints omit.
class SyllabusNodeDetail {
  const SyllabusNodeDetail({required this.node, this.coverage, this.children = const []});

  final SyllabusNode node;

  /// Opaque coverage payload from the server. Left unparsed rather than guessed
  /// at: the server computes it, and inventing a shape here would show the user
  /// numbers the client made up.
  final Map<String, dynamic>? coverage;
  final List<SyllabusNode> children;
}

/// The nested tree from `GET /syllabi/{version}/tree`.
class SyllabusTree {
  const SyllabusTree({
    required this.nodes,
    required this.nodeCount,
    required this.examinableNodeCount,
    this.depthLimited = false,
  });

  final List<SyllabusNode> nodes;
  final int nodeCount;
  final int examinableNodeCount;

  /// True when the request carried a `depth`, so [nodeCount] counts only the
  /// levels fetched rather than the whole syllabus.
  ///
  /// Verified against the live API on 2026-09-28: the version resource reported
  /// `node_count: 542` while `/tree?depth=2` returned `node_count: 33`. Showing
  /// both as "topics" without saying so would look like a data bug to the user.
  final bool depthLimited;

  bool get isEmpty => nodes.isEmpty;

  /// Total questions across the whole syllabus, counted once per node at the top
  /// level so overlapping subtrees are not double counted.
  int get totalQuestionCount {
    var sum = 0;
    for (final n in nodes) {
      sum += n.questionCount;
    }
    return sum;
  }

  /// Every node, flattened depth-first, for search and filtering.
  List<SyllabusNode> get flattened {
    final out = <SyllabusNode>[];
    void walk(List<SyllabusNode> list) {
      for (final n in list) {
        out.add(n);
        if (n.children.isNotEmpty) walk(n.children);
      }
    }

    walk(nodes);
    return out;
  }

  /// Nodes matching [query] on title or code, ignoring case.
  List<SyllabusNode> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return flattened
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            (n.nodeCode ?? '').toLowerCase().contains(q) ||
            (n.titleNe ?? '').toLowerCase().contains(q))
        .toList();
  }
}

/// A paper blueprint: how marks map onto syllabus nodes.
class SyllabusBlueprint {
  const SyllabusBlueprint({
    required this.paperCode,
    required this.name,
    required this.totalMarks,
    required this.totalQuestions,
    required this.sections,
    this.rules = const [],
    this.partCode,
    this.negativeMarkingMode,
    this.unattemptedMarks = 0,
  });

  final String paperCode;
  final String? partCode;
  final String name;
  final double totalMarks;
  final int totalQuestions;
  final String? negativeMarkingMode;
  final double unattemptedMarks;
  final List<SyllabusBlueprintSection> sections;

  /// Which syllabus nodes this paper draws from, with their weight.
  ///
  /// **Paper-level, not per section.** The controller emits one `rules` array per
  /// blueprint; sections carry only `section_code`, `name`, `marks` and
  /// `question_count`. Verified against the live API on 2026-09-28, where a paper
  /// returned 13 rules and no section had any.
  final List<SyllabusBlueprintRule> rules;

  /// Sums the section marks and compares them with the declared total, so a
  /// mismatch is visible instead of being shown as if it were correct.
  bool get marksReconcile {
    final sum = sections.fold<double>(0, (a, s) => a + s.marks);
    return (sum - totalMarks).abs() < 0.01;
  }
}

class SyllabusBlueprintSection {
  const SyllabusBlueprintSection({
    this.sectionCode,
    required this.name,
    required this.marks,
    required this.questionCount,
  });

  /// Null for a part that has no letter, e.g. "Part II".
  ///
  /// Verified against the live API on 2026-09-28: `/syllabi/{v}/blueprint` returns
  /// a `section_code` of `null` for the unnamed trailing part, so a parser that
  /// required a non-null code would silently drop a third of the paper's marks.
  final String? sectionCode;
  final String name;

  /// Precomputed by the server as `marks_per_question * question_count`.
  final double marks;
  final int questionCount;
}

class SyllabusBlueprintRule {
  const SyllabusBlueprintRule({
    required this.marksEach,
    required this.questionCount,
    required this.weight,
    this.nodeId,
    this.nodeCode,
    this.nodeTitle,
  });

  final int? nodeId;
  final String? nodeCode;
  final String? nodeTitle;
  final double marksEach;
  final int questionCount;
  final double weight;
}

/// A learner's own plan against a syllabus version.
class UserSyllabusPlan {
  const UserSyllabusPlan({
    required this.publicId,
    required this.syllabusVersionId,
    required this.planningMode,
    required this.scopeMode,
    this.nickname,
    this.versionCode,
    this.targetExamDate,
    this.dailyMinutes,
    this.isActive = true,
    this.lastPlannedAt,
  });

  final String publicId;
  final String? nickname;
  final int syllabusVersionId;
  final String? versionCode;
  final DateTime? targetExamDate;
  final int? dailyMinutes;

  /// Server-side planner strategy, e.g. `exam_date` / `daily_minutes`.
  final String planningMode;

  /// How much of the syllabus the plan covers.
  final String scopeMode;
  final bool isActive;
  final DateTime? lastPlannedAt;

  /// Days until the exam, or null when no date is set. Never negative: a passed
  /// exam date means "today or earlier", not a negative countdown.
  int? get daysRemaining {
    final target = targetExamDate;
    if (target == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = DateTime(target.year, target.month, target.day);
    return exam.difference(today).inDays < 0 ? 0 : exam.difference(today).inDays;
  }
}

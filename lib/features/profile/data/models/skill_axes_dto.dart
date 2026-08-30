import 'package:meta/meta.dart';

/// One axis of the skill radar — per-category graded accuracy.
///
/// Contract: `GET /api/v1/profile/skills` → `{axes: [{key, label, answered, correct, accuracy}]}`.
@immutable
class SkillAxis {
  const SkillAxis({
    required this.key,
    required this.label,
    required this.answered,
    required this.correct,
    required this.accuracy,
  });

  factory SkillAxis.fromJson(Map<String, dynamic> j) => SkillAxis(
        key: (j['key'] as num?)?.toInt() ?? 0,
        label: (j['label'] as String?) ?? '',
        answered: (j['answered'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0.0,
      );

  final int key;
  final String label;
  final int answered;
  final int correct;

  /// 0.0 .. 1.0 — server-computed; never recomputed client-side.
  final double accuracy;
}

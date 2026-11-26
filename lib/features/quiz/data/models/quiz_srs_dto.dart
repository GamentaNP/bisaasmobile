import 'dart:convert';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/quiz_srs.dart';

/// DTOs for the unified quiz SRS queue.
///
/// A 2xx body the client cannot understand is contract drift: the `fromJson`
/// factories throw [ContractViolation] instead of quietly producing a card with
/// fabricated fields. Only a genuinely empty collection yields no cards.
abstract final class _Parse {
  static int? intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? doubleOf(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? dateOf(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String requireId(Object? value, {required String endpoint}) {
    final id = value?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw ContractViolation('A review card has no id', endpoint: endpoint);
    }
    return id;
  }

  static String requireType(Object? value, {required String endpoint}) {
    final type = value?.toString() ?? '';
    if (!QuizSrsCardType.isValid(type)) {
      // An unknown card family must fail loudly: grading it with a guessed
      // `type` would either 422 or, worse, grade the wrong progress row.
      throw ContractViolation(
        'Unexpected review card type: $type',
        endpoint: endpoint,
      );
    }
    return type;
  }
}

class QuizSrsCardDto {
  const QuizSrsCardDto({
    required this.id,
    required this.type,
    required this.content,
    required this.dueAt,
    required this.options,
    this.questionId,
    this.wordId,
    this.itemType,
    this.difficulty,
    this.definition,
    this.example,
    this.dueReason,
    this.overdueDays = 0,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
  });

  factory QuizSrsCardDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/reviews/due',
  }) {
    final type = _Parse.requireType(j['type'], endpoint: endpoint);
    final dueAt = _Parse.dateOf(j['due_at'] ?? j['dueAt']);
    if (dueAt == null) {
      throw ContractViolation(
        'A review card has no parseable due_at',
        endpoint: endpoint,
      );
    }

    return QuizSrsCardDto(
      id: _Parse.requireId(j['id'], endpoint: endpoint),
      type: type,
      content: (j['content'] ?? j['term'] ?? '').toString(),
      dueAt: dueAt,
      questionId: _Parse.intOf(j['question_id']),
      wordId: _Parse.intOf(j['word_id']),
      options: _options(j['options']),
      itemType: j['item_type'] as String?,
      difficulty: j['difficulty'] as String?,
      definition: j['definition'] as String?,
      example: j['example'] as String?,
      dueReason: j['due_reason'] as String?,
      overdueDays: _Parse.intOf(j['overdue_days']) ?? 0,
      intervalDays: _Parse.intOf(j['interval_days']) ?? 0,
      repetitions: _Parse.intOf(j['repetitions']) ?? 0,
      easinessFactor: _Parse.doubleOf(j['easiness_factor']) ?? 0,
    );
  }

  final String id;
  final String type;
  final String content;
  final DateTime dueAt;
  final List<QuizSrsOption> options;
  final int? questionId;
  final int? wordId;
  final String? itemType;
  final String? difficulty;
  final String? definition;
  final String? example;
  final String? dueReason;
  final int overdueDays;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;

  static List<QuizSrsOption> _options(Object? raw) {
    if (raw is String) {
      try {
        return _options(jsonDecode(raw));
      } on FormatException {
        return const <QuizSrsOption>[];
      }
    }
    if (raw is Map) {
      final options = <QuizSrsOption>[];
      for (final entry in raw.entries) {
        final label = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          options.add(QuizSrsOption(
            label: (value['key'] ?? label).toString(),
            text: (value['text'] ?? value['label'] ?? value['body'] ?? '')
                .toString(),
          ));
        } else {
          options.add(QuizSrsOption(label: label, text: value.toString()));
        }
      }
      return options;
    }
    if (raw is List) {
      final options = <QuizSrsOption>[];
      for (var i = 0; i < raw.length; i++) {
        final value = raw[i];
        if (value is Map) {
          options.add(QuizSrsOption(
            label: (value['key'] ?? value['id'] ?? value['position'] ?? i + 1)
                .toString(),
            text: (value['text'] ?? value['label'] ?? value['body'] ?? '')
                .toString(),
          ));
        } else if (value != null) {
          options.add(QuizSrsOption(label: '${i + 1}', text: value.toString()));
        }
      }
      return options;
    }
    return const <QuizSrsOption>[];
  }

  QuizSrsCard toDomain() => QuizSrsCard(
        id: id,
        type: type,
        content: content,
        dueAt: dueAt,
        questionId: questionId,
        wordId: wordId,
        options: options,
        itemType: itemType,
        difficulty: difficulty,
        definition: definition,
        example: example,
        dueReason: dueReason,
        overdueDays: overdueDays,
        intervalDays: intervalDays,
        repetitions: repetitions,
        easinessFactor: easinessFactor,
      );
}

class QuizSrsGradeResultDto {
  const QuizSrsGradeResultDto({
    required this.id,
    required this.type,
    required this.quality,
    required this.intervalDays,
    required this.repetitions,
    required this.easinessFactor,
    this.dueAt,
  });

  factory QuizSrsGradeResultDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/reviews/{review}/grade',
  }) {
    final quality = _Parse.intOf(j['quality'] ?? j['grade']);
    if (quality == null || !QuizSrsQuality.isValid(quality)) {
      throw ContractViolation(
        'A grade response has no valid quality',
        endpoint: endpoint,
      );
    }
    return QuizSrsGradeResultDto(
      id: _Parse.requireId(j['id'], endpoint: endpoint),
      type: _Parse.requireType(j['type'], endpoint: endpoint),
      quality: quality,
      intervalDays: _Parse.intOf(j['interval_days']) ?? 0,
      repetitions: _Parse.intOf(j['repetitions']) ?? 0,
      easinessFactor: _Parse.doubleOf(j['easiness_factor']) ?? 0,
      dueAt: _Parse.dateOf(j['due_at']),
    );
  }

  final String id;
  final String type;
  final int quality;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;
  final DateTime? dueAt;

  QuizSrsGradeResult toDomain() => QuizSrsGradeResult(
        id: id,
        type: type,
        quality: quality,
        intervalDays: intervalDays,
        repetitions: repetitions,
        easinessFactor: easinessFactor,
        dueAt: dueAt,
      );
}

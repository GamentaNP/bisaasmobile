import 'dart:convert';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/review.dart';

/// Wire DTOs for `/quiz/review/due`, `/quiz/attempts/{attempt}/review` and
/// `PUT /quiz/reviews/{review}/grade`.
///
/// A 2xx body that cannot be read is contract drift, never an empty result:
/// every mandatory field is checked and failing checks throw [ContractViolation].
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
    if (!ReviewCardType.isValid(type)) {
      // A guessed type would grade the wrong progress family.
      throw ContractViolation('Unexpected review card type: $type', endpoint: endpoint);
    }
    return type;
  }

  static List<Map<String, dynamic>> requireList(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value == null) {
      throw ContractViolation('Missing $key', endpoint: endpoint);
    }
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static Map<String, dynamic> requireMap(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static bool boolOf(Object? value) => value == true || value == 'true';
}

class ReviewCardDto {
  const ReviewCardDto({
    required this.id,
    required this.type,
    required this.content,
    required this.dueAt,
    required this.options,
    this.questionId,
    this.wordId,
    this.itemType,
    this.difficulty,
    this.dueReason,
    this.definition,
    this.example,
    this.overdueDays = 0,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
  });

  factory ReviewCardDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/review/due',
  }) {
    final type = _Parse.requireType(j['type'], endpoint: endpoint);
    final dueAt = _Parse.dateOf(j['due_at']);
    if (dueAt == null) {
      throw ContractViolation('A review card has no parseable due_at', endpoint: endpoint);
    }
    return ReviewCardDto(
      id: _Parse.requireId(j['id'], endpoint: endpoint),
      type: type,
      content: (j['content'] ?? '').toString(),
      dueAt: dueAt,
      options: _options(j['options']),
      questionId: _Parse.intOf(j['question_id']),
      wordId: _Parse.intOf(j['word_id']),
      itemType: j['item_type'] as String?,
      difficulty: j['difficulty'] as String?,
      dueReason: j['due_reason'] as String?,
      definition: j['definition'] as String?,
      example: j['example'] as String?,
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
  final List<ReviewOption> options;
  final int? questionId;
  final int? wordId;
  final String? itemType;
  final String? difficulty;
  final String? dueReason;
  final String? definition;
  final String? example;
  final int overdueDays;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;

  static List<ReviewOption> _options(Object? raw) {
    if (raw is String) {
      try {
        return _options(jsonDecode(raw));
      } on FormatException {
        return const <ReviewOption>[];
      }
    }
    if (raw is Map) {
      return raw.entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return ReviewOption(
            label: (value['key'] ?? entry.key).toString(),
            text: (value['text'] ?? value['label'] ?? '').toString(),
          );
        }
        return ReviewOption(
          label: entry.key.toString(),
          text: value.toString(),
        );
      }).toList();
    }
    if (raw is List) {
      final options = <ReviewOption>[];
      for (var i = 0; i < raw.length; i++) {
        final value = raw[i];
        if (value is Map) {
          options.add(ReviewOption(
            label: (value['key'] ?? value['id'] ?? i + 1).toString(),
            text: (value['text'] ?? value['label'] ?? '').toString(),
          ));
        } else if (value != null) {
          options.add(ReviewOption(label: '${i + 1}', text: value.toString()));
        }
      }
      return options;
    }
    return const <ReviewOption>[];
  }

  ReviewCard toDomain() => ReviewCard(
        id: id,
        type: type,
        content: content,
        dueAt: dueAt,
        options: options,
        questionId: questionId,
        wordId: wordId,
        itemType: itemType,
        difficulty: difficulty,
        dueReason: dueReason,
        definition: definition,
        example: example,
        overdueDays: overdueDays,
        intervalDays: intervalDays,
        repetitions: repetitions,
        easinessFactor: easinessFactor,
      );
}

class ReviewGradeResultDto {
  const ReviewGradeResultDto({
    required this.id,
    required this.type,
    required this.quality,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
    this.dueAt,
  });

  factory ReviewGradeResultDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/reviews/{review}/grade',
  }) {
    final quality = _Parse.intOf(j['quality'] ?? j['grade']);
    if (quality == null || !ReviewQuality.isValid(quality)) {
      throw ContractViolation('A grade response has no valid quality', endpoint: endpoint);
    }
    return ReviewGradeResultDto(
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

  ReviewGradeResult toDomain() => ReviewGradeResult(
        id: id,
        type: type,
        quality: quality,
        intervalDays: intervalDays,
        repetitions: repetitions,
        easinessFactor: easinessFactor,
        dueAt: dueAt,
      );
}

class AttemptReviewDto {
  const AttemptReviewDto({
    required this.attemptId,
    required this.status,
    required this.policy,
    required this.items,
  });

  factory AttemptReviewDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/attempts/{attempt}/review',
  }) {
    final attemptId = _Parse.intOf(j['attempt_id']);
    if (attemptId == null) {
      throw ContractViolation('An attempt review has no attempt_id', endpoint: endpoint);
    }
    final policyMap = _Parse.requireMap(
      j['review_policy'] ?? j['reviewPolicy'],
      endpoint: endpoint,
      key: 'review_policy',
    );
    final items = _Parse.requireList(j['items'], endpoint: endpoint, key: 'items');
    return AttemptReviewDto(
      attemptId: attemptId,
      status: (j['status'] ?? '').toString(),
      policy: ReviewPolicy(
        answersVisible: _Parse.boolOf(policyMap['answers_visible']),
        locked: _Parse.boolOf(policyMap['locked']),
        isHighStakes: _Parse.boolOf(policyMap['is_high_stakes']),
        releaseMode: (policyMap['release_mode'] ?? '').toString(),
        released: _Parse.boolOf(policyMap['released']),
      ),
      items: items.map((row) => AttemptReviewItemDto.fromJson(row, endpoint: endpoint).toDomain()).toList(),
    );
  }

  final int attemptId;
  final String status;
  final ReviewPolicy policy;
  final List<AttemptReviewItem> items;

  AttemptReview toDomain() => AttemptReview(
        attemptId: attemptId,
        status: status,
        policy: policy,
        items: items,
      );
}

class AttemptReviewItemDto {
  const AttemptReviewItemDto({
    required this.questionId,
    this.questionText,
    this.givenAnswer,
    this.isCorrect,
    this.isSkipped = false,
    this.verdict,
    this.scoreAwarded,
    this.timeTakenSeconds,
    this.explanation,
  });

  factory AttemptReviewItemDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/attempts/{attempt}/review',
  }) {
    final questionId = _Parse.intOf(j['question_id']);
    if (questionId == null) {
      throw ContractViolation('A review item has no question_id', endpoint: endpoint);
    }
    return AttemptReviewItemDto(
      questionId: questionId,
      questionText: j['question_text'] as String?,
      givenAnswer: j['given_answer'] as String?,
      isCorrect: j['is_correct'] as bool?,
      isSkipped: _Parse.boolOf(j['is_skipped']),
      verdict: j['verdict'] as String?,
      scoreAwarded: _Parse.doubleOf(j['score_awarded']),
      timeTakenSeconds: _Parse.intOf(j['time_taken_seconds']),
      explanation: j['explanation'] as String?,
    );
  }

  final int questionId;
  final String? questionText;
  final String? givenAnswer;
  final bool? isCorrect;
  final bool isSkipped;
  final String? verdict;
  final double? scoreAwarded;
  final int? timeTakenSeconds;
  final String? explanation;

  AttemptReviewItem toDomain() => AttemptReviewItem(
        questionId: questionId,
        questionText: questionText,
        givenAnswer: givenAnswer,
        isCorrect: isCorrect,
        isSkipped: isSkipped,
        verdict: verdict,
        scoreAwarded: scoreAwarded,
        timeTakenSeconds: timeTakenSeconds,
        explanation: explanation,
      );
}

/// Source-level guard: the client must never ingest an answer key from a
/// pre-answer payload.
///
/// The server's `QuizQuestionResource` deliberately omits `correct_option_id`
/// and `explanation` from question listings, and the RTDB battle node only
/// carries `is_correct` after an answer is submitted. An ingestion point on the
/// client is what turns one careless API change into a published answer bank,
/// so the ingestion points are asserted absent here rather than trusted.
///
/// Answer keys are legitimate in the results/review path (`AttemptResult`,
/// quiz review screen) — those read a completed attempt, not a pending one.
/// See docs/mobileapp/BISAAS-SECURITY-MASTER-PLAN-2026.md §1.5 and W4.8.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('answer key ingestion', () {
    test('question list mapping does not read correct_option_id', () {
      final source = File(
        'lib/features/quiz/data/datasources/quiz_remote_data_source.dart',
      ).readAsStringSync();

      expect(
        source.contains("'correct_option_id': j['correct_option_id']"),
        isFalse,
        reason: 'Question listings must not carry an answer key. '
            'See security plan W0.5.',
      );
      expect(
        source.contains("'explanation': j['explanation']"),
        isFalse,
        reason: 'Explanations are results-stage disclosure only.',
      );
    });

    test('battle realtime payload does not read correct_option_id', () {
      final source = File(
        'lib/features/battle/data/repositories/battle_repository_impl.dart',
      ).readAsStringSync();

      expect(
        source.contains("raw['correct_option_id']"),
        isFalse,
        reason: 'Battles are server-graded and carry coin stakes; an answer key '
            'must never reach the client before the answer is submitted.',
      );
    });

    test('offline practice does not grade locally', () {
      final source = File(
        'lib/features/quiz/presentation/controllers/quiz_controller.dart',
      ).readAsStringSync();

      expect(
        source.contains('optionId == correctId'),
        isFalse,
        reason: 'Offline answers are pending, not graded. A local verdict may '
            'only be computed from a key delivered inside an encrypted '
            'offline pack (W4.8).',
      );
    });
  });
}

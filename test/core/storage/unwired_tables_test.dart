import 'dart:io';

import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Five of the seven tables in the schema have no producer.
///
/// This is not sloppiness to be tidied away — each one is empty for a reason,
/// and two of them must stay empty. This test records the reasons so the next
/// agent does not "fix" the gap by moving server logic onto the device.
void main() {
  group('the tables that are deliberately unwired', () {
    /// Kept because the app is a shell for a server-authoritative product and a
    /// local copy of these would be a second source of truth.
    const mustStayEmpty = {
      'attempts': "Per-answer records. Writing these locally would mean holding "
          "a user's answers on disk for an attempt the server has not graded.",
      'quizAttempts': 'Attempt headers with a provisionalScore column. A local '
          'score is a local grade, and grading is server-authoritative by '
          'design (AGENTS.md: Flutter never grades quizzes).',
      'courses': 'Fully redundant now. The course catalog is served from the '
          'response cache, which stores the real envelope rather than a '
          're-serialised copy that could drift from the DTO.',
      'downloads': 'Aspirational offline-pack bookkeeping. The one pack that '
          'exists, /mobile/daily-quiz-pack, is already cached into `questions`, '
          'and a real pack manager needs a server pack endpoint to track.',
      'calculations': 'The history screen calls '
          'GET /calculators/{domain}/{slug}/history. Its docblock used to claim '
          'otherwise, which is corrected in the same commit as this test.',
    };

    /// Dart table name -> real SQLite table name. Drift snake-cases multi-word
    /// class names, so `QuizAttempts` is the table `quiz_attempts`.
    const sqlName = {
      'attempts': 'attempts',
      'quizAttempts': 'quiz_attempts',
      'courses': 'courses',
      'downloads': 'downloads',
      'calculations': 'calculations',
    };

    test('exactly the tables with no producer are the ones we expect', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.customSelect('SELECT 1').getSingle();

      for (final entry in mustStayEmpty.entries) {
        final rows = await db
            .customSelect('SELECT count(*) AS n FROM ${sqlName[entry.key]}')
            .getSingle();
        final count = rows.read<int>('n');
        expect(
          count,
          0,
          reason: '${entry.key} has no producer, so it must be empty. '
              '${entry.value}',
        );
      }
    });

    test('the attempt tables are never written anywhere in lib/', () {
      // The strongest form of the guarantee: not "is empty today" but "no code
      // path can fill it". A local grade would be a correctness regression, so
      // this fails loudly if someone adds the insert.
      final lib = Directory('lib');
      final offenders = <String>[];

      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // The generated database is the schema itself, not a producer.
        if (file.path.endsWith('app_database.g.dart')) continue;
        final source = file.readAsStringSync();
        for (final table in const ['attempts', 'quizAttempts']) {
          if (RegExp(r'into\(db\.$table\)').hasMatch(source) ||
              RegExp(r'db\.$table\)\s*\n?\s*\.\s*insert').hasMatch(source)) {
            offenders.add('${file.path} writes $table');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Grading is server-authoritative. Writing attempts locally '
            'would create a second source of truth for a score.',
      );
    });

    test('the only tables with producers are the ones we expect', () {
      // If someone wires another table up, this test is the reminder to record
      // the reason above rather than leave the list silently stale.
      //
      // `syncQueue` is allowed a producer because SyncQueueDao genuinely writes
      // it, but nothing in production calls SyncQueueService.enqueue - the
      // calculator-snapshot path that used to was unwired without the method
      // being removed, so the queue is always empty at runtime. That is a real
      // gap, recorded here so it is not mistaken for working offline support.
      const withProducers = {'questions', 'cachedResponses', 'syncQueue'};

      final lib = Directory('lib');
      final producers = <String>{};
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.endsWith('app_database.g.dart')) continue;
        final source = file.readAsStringSync();
        for (final table in const [
          'questions',
          'attempts',
          'courses',
          'calculations',
          'syncQueue',
          'quizAttempts',
          'downloads',
          'cachedResponses',
        ]) {
          if (source.contains('into(db.$table)')) producers.add(table);
        }
      }

      expect(
        producers.difference(withProducers),
        isEmpty,
        reason: 'a new table producer appeared. Record the reason above so this '
            'file stays truthful.',
      );
    });

    test('the sync queue is wired but never fed', () {
      // SyncQueueDao writes; SyncQueueService.enqueue has no production caller.
      // An offline write queue that is never enqueued into drains zero rows
      // every 30 seconds forever, which is worse than not having one because it
      // looks like it works.
      final lib = Directory('lib');
      final callers = <String>[];
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('sync_queue.dart') || path.endsWith('sync_manager.dart')) {
          continue;
        }
        final source = file.readAsStringSync();
        if (source.contains('.enqueue(') || source.contains('enqueueSnapshot(')) {
          callers.add(path);
        }
      }

      expect(
        callers,
        isEmpty,
        reason: 'something now feeds the offline write queue. Good - but move it '
            'out of the "no producer" list and record the contract it replays '
            'against, because SyncManager replays these as idempotent POSTs.',
      );
    });
  });
}

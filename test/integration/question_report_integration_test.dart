/// Cross-layer proof for the question-report write.
///
/// Drives real Dio → adapter → envelope → DTO → domain → repository →
/// controller. The three things a single-layer mock cannot prove are all here:
/// the exact wire fields, one Idempotency-Key reused across a failed retry,
/// and a failure that never credits a report locally.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/features/review/domain/entities/question_report.dart';
import 'package:bisaasmobile/features/review/presentation/controllers/review_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _reportData({bool duplicate = false}) => <String, dynamic>{
  'duplicate': duplicate,
  'canonical_report_id': 91,
  'report': <String, dynamic>{
    'id': 91,
    'status': 'pending',
    'category': 'incorrect_answer',
    'duplicate_count': duplicate ? 1 : 0,
  },
};

QuestionReportSubmission _submission({
  String? correction = 'Option A is correct.',
}) => QuestionReportSubmission(
  questionId: 42,
  category: QuestionReportCategory.incorrectAnswer,
  description: 'The answer key marks B but the explanation says A.',
  suggestedCorrection: correction,
);

void main() {
  late FakeApi api;
  late ProviderContainer container;

  ProviderContainer boot() => ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dioFor(api))],
  );

  setUp(() => api = FakeApi(<String, FakeRoute>{}));

  tearDown(() => container.dispose());

  test('a report sends only the documented fields with a stable key', () async {
    api.on('POST', '/quiz/questions/42/reports', FakeRoute.ok(_reportData()));
    container = boot();

    final result = await container
        .read(questionReportControllerProvider.notifier)
        .submit(_submission());

    expect(result, isNotNull);
    expect(result!.reportId, 91);
    expect(result.duplicate, isFalse);
    expect(result.category, QuestionReportCategory.incorrectAnswer);
    final state = container.read(questionReportControllerProvider);
    expect(state.reportedQuestionIds, contains(42));
    expect(state.error, isNull);

    final index = api.indexOfRequest('POST', '/quiz/questions/42/reports');
    expect(index, isNot(-1));
    expect(api.headerOf(index, 'Idempotency-Key'), isNotNull);
    final body = api.jsonBodyOf(index);
    expect(body.keys, <String>{
      'category',
      'description',
      'suggested_correction',
    });
    expect(body['category'], 'incorrect_answer');
    expect(
      body['description'],
      'The answer key marks B but the explanation says A.',
    );
    expect(body['suggested_correction'], 'Option A is correct.');
    expect(
      body.containsKey('score'),
      isFalse,
      reason: 'the client never claims a moderation outcome',
    );
    expect(api.misses, isEmpty);
  });

  test('an omitted correction is not invented and is not sent', () async {
    api.on('POST', '/quiz/questions/42/reports', FakeRoute.ok(_reportData()));
    container = boot();

    await container
        .read(questionReportControllerProvider.notifier)
        .submit(_submission(correction: null));

    final index = api.indexOfRequest('POST', '/quiz/questions/42/reports');
    expect(api.jsonBodyOf(index).containsKey('suggested_correction'), isFalse);
  });

  test(
    'a failure keeps the key and credits no report until the retry works',
    () async {
      api.onSequence('POST', '/quiz/questions/42/reports', [
        FakeRoute.error(500, 'INTERNAL_ERROR', 'Server error'),
        FakeRoute.ok(_reportData(duplicate: true)),
      ]);
      container = boot();
      final controller = container.read(
        questionReportControllerProvider.notifier,
      );

      final first = await controller.submit(_submission());
      expect(first, isNull);
      final failed = container.read(questionReportControllerProvider);
      expect(failed.error, isNotNull);
      expect(failed.failedSubmission, isNotNull);
      expect(failed.lastResult, isNull, reason: 'no fabricated success');
      expect(
        failed.reportedQuestionIds,
        isEmpty,
        reason: 'a failed report must not mark the question as reported',
      );

      final second = await controller.retry();
      expect(second, isNotNull);
      expect(second!.duplicate, isTrue);
      final state = container.read(questionReportControllerProvider);
      expect(state.error, isNull);
      expect(state.failedSubmission, isNull);
      expect(state.reportedQuestionIds, contains(42));

      final posts = api.requests
          .where((r) => r.path.endsWith('/reports'))
          .toList();
      expect(posts, hasLength(2));
      final firstIndex = api.requests.indexOf(posts.first);
      final secondIndex = api.requests.indexOf(posts.last);
      expect(
        api.headerOf(firstIndex, 'Idempotency-Key'),
        api.headerOf(secondIndex, 'Idempotency-Key'),
        reason: 'a fresh key on retry could submit the report twice',
      );
      expect(api.jsonBodyOf(firstIndex), api.jsonBodyOf(secondIndex));
    },
  );

  test(
    'a transport failure carries the server code, not a Dio diagnostic',
    () async {
      api.on(
        'POST',
        '/quiz/questions/42/reports',
        FakeRoute.error(500, 'INTERNAL_ERROR', 'Server error'),
      );
      container = boot();

      await container
          .read(questionReportControllerProvider.notifier)
          .submit(_submission());

      expect(
        container.read(questionReportControllerProvider).error,
        isNot(contains('DioException')),
      );
      expect(api.misses, isEmpty);
    },
  );

  test('an unreadable 2xx body is drift and never becomes a success', () async {
    api.on(
      'POST',
      '/quiz/questions/42/reports',
      FakeRoute.raw(<String, dynamic>{'unexpected': true}),
    );
    container = boot();

    final result = await container
        .read(questionReportControllerProvider.notifier)
        .submit(_submission());

    expect(result, isNull);
    final state = container.read(questionReportControllerProvider);
    expect(state.lastResult, isNull);
    expect(state.reportedQuestionIds, isEmpty);
    expect(state.error, isNotEmpty);
    expect(
      state.error,
      isNot(contains('ContractViolation')),
      reason: 'a parse failure is logged, not shown as English diagnostics',
    );
  });

  test(
    'an invalid category is refused before any request leaves the device',
    () async {
      container = boot();
      final submission = QuestionReportSubmission(
        questionId: 42,
        category: 'not_a_server_category',
        description: 'The answer key marks B but the explanation says A.',
      );

      final result = await container
          .read(questionReportControllerProvider.notifier)
          .submit(submission);

      expect(result, isNull);
      expect(api.requests, isEmpty);
      expect(
        container.read(questionReportControllerProvider).reportedQuestionIds,
        isEmpty,
      );
    },
  );
}

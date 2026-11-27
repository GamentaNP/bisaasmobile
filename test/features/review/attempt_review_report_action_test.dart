import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/features/review/domain/entities/question_report.dart';
import 'package:bisaasmobile/features/review/domain/entities/review.dart';
import 'package:bisaasmobile/features/review/domain/repositories/review_repository.dart';
import 'package:bisaasmobile/features/review/presentation/controllers/review_controller.dart';
import 'package:bisaasmobile/features/review/presentation/screens/attempt_review_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

class FakeReportRepository implements ReviewRepository {
  FakeReportRepository({this.failures = 0});

  int failures;
  final List<QuestionReportSubmission> submissions = [];

  @override
  Future<QuestionReportResult> reportQuestion(
    int questionId, {
    required String category,
    required String description,
    String? suggestedCorrection,
    String? idempotencyKey,
  }) async {
    submissions.add(
      QuestionReportSubmission(
        questionId: questionId,
        category: category,
        description: description,
        suggestedCorrection: suggestedCorrection,
      ),
    );
    if (failures > 0) {
      failures--;
      throw const ApiException(
        statusCode: 500,
        code: ApiErrorCode.serviceUnavailable,
        message: 'Server error',
      );
    }
    return QuestionReportResult(
      reportId: 91,
      status: 'pending',
      category: category,
      duplicate: false,
      canonicalReportId: 91,
      duplicateCount: 0,
    );
  }

  @override
  Future<List<ReviewCard>> getDueCards() => throw UnimplementedError();

  @override
  Future<AttemptReview> getAttemptReview(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<ReviewGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    required String type,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final review = AttemptReview(
    attemptId: 7,
    status: 'completed',
    policy: const ReviewPolicy(
      answersVisible: true,
      locked: false,
      isHighStakes: false,
      releaseMode: 'immediate',
      released: true,
    ),
    items: const [
      AttemptReviewItem(
        questionId: 42,
        questionText: 'Which law explains this?',
        verdict: 'wrong',
      ),
    ],
  );

  Widget host(FakeReportRepository repo) => localizedApp(
    child: ProviderScope(
      overrides: [
        attemptReviewProvider.overrideWith(
          (ref, attemptId) => Future.value(review),
        ),
        reviewRepositoryProvider.overrideWithValue(repo),
      ],
      child: const AttemptReviewScreen(attemptId: 7),
    ),
  );

  Future<void> fillDialog(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.quizReportIncorrectAnswer).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'The answer key marks B but the explanation says A.',
    );
    await tester.pump();
  }

  testWidgets('every unlocked verdict offers a localized report action', (
    tester,
  ) async {
    await tester.pumpWidget(host(FakeReportRepository()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quizReportAction), findsOneWidget);
    await tester.tap(find.text(l10n.quizReportAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quizReportTitle), findsOneWidget);
    expect(find.text(l10n.quizReportCategory), findsOneWidget);
    expect(find.text(l10n.quizReportDescription), findsOneWidget);
    expect(find.text(l10n.quizReportSubmit), findsOneWidget);
  });

  testWidgets('short descriptions are refused locally with localized copy', (
    tester,
  ) async {
    final repo = FakeReportRepository();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.quizReportAction));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Too short');
    await tester.tap(find.text(l10n.quizReportSubmit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quizReportInvalid), findsOneWidget);
    expect(
      repo.submissions,
      isEmpty,
      reason: 'no request should leave the device',
    );
    expect(find.text(l10n.quizReportSent), findsNothing);
  });

  testWidgets(
    'a server acceptance shows success and marks only that question',
    (tester) async {
      final repo = FakeReportRepository();
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.quizReportAction));
      await tester.pumpAndSettle();
      await fillDialog(tester);

      await tester.tap(find.text(l10n.quizReportSubmit));
      await tester.pumpAndSettle();

      expect(repo.submissions, hasLength(1));
      expect(repo.submissions.single.questionId, 42);
      expect(
        repo.submissions.single.category,
        QuestionReportCategory.incorrectAnswer,
      );
      expect(find.text(l10n.quizReportSubmitted), findsOneWidget);
      expect(find.text(l10n.quizReportSent), findsOneWidget);
      expect(find.text(l10n.quizReportAction), findsNothing);
    },
  );

  testWidgets('a failure stays visible in the dialog until retry succeeds', (
    tester,
  ) async {
    final repo = FakeReportRepository(failures: 1);
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.quizReportAction));
    await tester.pumpAndSettle();
    await fillDialog(tester);

    await tester.tap(find.text(l10n.quizReportSubmit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quizReportFailed('Server error')), findsOneWidget);
    expect(
      find.text(l10n.quizReportSent),
      findsNothing,
      reason: 'a failed write is never shown as sent',
    );
    expect(find.text(l10n.retry), findsOneWidget);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(repo.submissions, hasLength(2));
    expect(find.text(l10n.quizReportSubmitted), findsOneWidget);
    expect(find.text(l10n.quizReportSent), findsOneWidget);
  });
}

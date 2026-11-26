import 'package:bisaasmobile/features/quiz/data/providers/quiz_catalog_providers.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/quiz_catalog.dart';
import 'package:bisaasmobile/features/quiz/presentation/screens/quiz_review_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget host(AttemptReview review) => localizedApp(
        child: ProviderScope(
          overrides: [
            attemptReviewProvider.overrideWith(
              (ref, attemptId) => Future.value(review),
            ),
          ],
          child: const QuizReviewScreen(attemptId: '7'),
        ),
      );

  testWidgets('renders the server explanation with a localized label',
      (tester) async {
    await tester.pumpWidget(host(AttemptReview(<AttemptReviewEntry>[
      AttemptReviewEntry(
        body: 'Which law explains this?',
        explanation: 'Newton third law makes this the right choice.',
        explanationSource: 'base',
        isCorrect: true,
      ),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('Newton third law makes this the right choice.'),
        findsOneWidget);
    expect(find.text(l10n.quizExplanation), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
  });

  testWidgets('a missing explanation renders no label and no placeholder',
      (tester) async {
    await tester.pumpWidget(host(AttemptReview(<AttemptReviewEntry>[
      AttemptReviewEntry(
        body: 'Question with a withheld key',
        isCorrect: null,
      ),
    ])));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quizExplanation), findsNothing);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
    expect(find.text('Question with a withheld key'), findsOneWidget);
  });
}

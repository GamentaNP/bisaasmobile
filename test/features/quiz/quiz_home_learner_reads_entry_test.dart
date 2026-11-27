/// The five learner-read screens ship only if a learner can get to them.
///
/// This pins the compact entry strip on the quiz home tab: each of its four
/// tiles uses `context.go` to a path that is registered in app_router.dart,
/// and every label is the localized copy rather than an invented string.
library;

import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/features/quiz/presentation/quiz_home_page.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration/support/fake_api.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  /// The path segment after `/quiz/` is exactly the one in app_router.dart's
  /// `quiz-feed`, `quiz-hall-of-fame`, `quiz-analytics` and `quiz-review-due`
  /// routes. A placeholder screen at that path proves `context.go` landed.
  final destinations = <({String label, String path})>[
    (label: l10n.feedActivityFeed, path: '/quiz/feed'),
    (label: l10n.hallOfFameTitle, path: '/quiz/hall-of-fame'),
    (label: l10n.analyticsYourProgress, path: '/quiz/analytics'),
    (label: l10n.quizReviewDue, path: '/quiz/review/due'),
  ];

  GoRouter router() => GoRouter(
    initialLocation: '/quiz/home',
    routes: [
      GoRoute(
        path: '/quiz/home',
        builder: (_, _) => const QuizHomePage(),
      ),
      for (final destination in destinations)
        GoRoute(
          path: destination.path,
          builder: (_, _) => Scaffold(
            body: Text('ARRIVED:${destination.path}'),
          ),
        ),
    ],
  );

  Future<void> pumpHome(WidgetTester tester) async {
    final api = FakeApi(<String, FakeRoute>{
      'GET /quiz/courses': FakeRoute.ok(<String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{
            'id': '1',
            'name': 'Civil',
            'description': '',
          },
        ],
      }),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dioFor(api))],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLanguages.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final destination in destinations) {
    testWidgets('${destination.path} tile opens its registered route', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text(destination.label), findsOneWidget);
      await tester.tap(find.text(destination.label));
      await tester.pumpAndSettle();

      expect(find.text('ARRIVED:${destination.path}'), findsOneWidget);
    });
  }
}

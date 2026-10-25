/// Widget tests for the onboarding flow — the three-step selection state
/// machine (exam → daily goal → experience level) and what it persists.
///
/// Pinned here:
///   * the defaults persist real option values — the experience level
///     default used to be `'Graduate'`, which matches no option in the
///     list, so page 3 rendered nothing as selected and the profile side
///     received a value it does not recognise;
///   * a full walk-through persists the tapped choices and lands on `/home`;
///   * Skip persists the defaults and lands on `/home` too.
library;

import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:bisaasmobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// GradientButton renders `label.toUpperCase()`.
String _cta(String label) => label.toUpperCase();

AppLocalizations get _l10n => lookupAppLocalizations(const Locale('en'));

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLanguages.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router() => GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME-SCREEN')),
        ),
      ],
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Preferences.init();
  });

  testWidgets('a full walk-through persists the tapped choices and lands on /home',
      (tester) async {
    final router = _router();
    await _pump(tester, router);

    // Page 1 — exam: pick GATE over the default.
    await tester.tap(find.text('GATE / Indian PSC'));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingContinue)));
    await tester.pumpAndSettle();

    // Page 2 — daily goal: pick the 60-minute sprint. The tile renders the
    // composite label "60 mins / day — Intensive Sprint".
    expect(find.textContaining('Intensive Sprint'), findsOneWidget);
    await tester.tap(find.textContaining('Intensive Sprint'));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingContinue)));
    await tester.pumpAndSettle();

    // Page 3 — experience level.
    expect(find.text('Practicing Engineer'), findsOneWidget);
    await tester.tap(find.text('Practicing Engineer'));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingStartLearning)));
    await tester.pumpAndSettle();

    expect(find.text('HOME-SCREEN'), findsOneWidget);
    expect(Preferences.instance.selectedExam, 'GATE / Indian PSC');
    expect(Preferences.instance.dailyGoalMinutes, 60);
    expect(Preferences.instance.experienceLevel, 'Practicing Engineer');
    expect(Preferences.instance.onboardingDone, isTrue);
  });

  testWidgets('Skip persists the defaults — all of them real option values — '
      'and lands on /home', (tester) async {
    final router = _router();
    await _pump(tester, router);

    await tester.tap(find.text(_l10n.commonSkip));
    await tester.pumpAndSettle();

    expect(find.text('HOME-SCREEN'), findsOneWidget);
    expect(Preferences.instance.selectedExam, 'Loksewa / Civil PSC');
    expect(Preferences.instance.dailyGoalMinutes, 30);
    // The regression: this used to persist 'Graduate', a value no step
    // offers, so page 3 rendered nothing as selected.
    expect(Preferences.instance.experienceLevel, 'Engineering Student');
    expect(Preferences.instance.onboardingDone, isTrue);
  });
}

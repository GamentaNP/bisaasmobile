/// Widget tests for the onboarding flow — the three-step selection state
/// machine (study field → daily goal → education level) and what it persists.
///
/// Pinned here:
///   * every option comes from the injected `onboardingOptionsProvider`, never
///     from an invented on-device catalogue;
///   * the ids/minutes saved are the server's, not display copy;
///   * the server's English intensity labels are never rendered — only their
///     localized `value` labels are;
///   * Skip persists the first server option of each step;
///   * a failed fetch renders `ErrorView` with a retry instead of an empty
///     list of choices.
library;

import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:bisaasmobile/features/onboarding/data/providers/onboarding_options_providers.dart';
import 'package:bisaasmobile/features/onboarding/domain/entities/onboarding_options.dart';
import 'package:bisaasmobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:bisaasmobile/shared/widgets/error_view.dart';
import 'package:bisaasmobile/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// GradientButton renders `label.toUpperCase()`.
String _cta(String label) => label.toUpperCase();

AppLocalizations get _l10n => lookupAppLocalizations(const Locale('en'));

/// Deliberately different from the old invented options: the assertions below
/// prove the server values, not the old display copy, reach Preferences.
OnboardingOptions _fakeOptions() => const OnboardingOptions(
      educationLevels: [
        EducationLevelOption(id: 101, name: 'SEE'),
        EducationLevelOption(id: 102, name: 'IAG'),
        EducationLevelOption(id: 103, name: 'MBBS'),
      ],
      domains: [
        DomainOption(id: 11, name: 'Engineering', slug: 'engineering'),
        DomainOption(id: 12, name: 'Medical', slug: 'medical'),
      ],
      courses: [
        CourseOption(id: 201, name: 'Civil', slug: 'civil', domainId: 11),
      ],
      goalIntensities: [
        GoalIntensityOption(value: 'casual', label: 'Casual', defaultMinutes: 15),
        GoalIntensityOption(value: 'serious', label: 'Serious', defaultMinutes: 45),
        GoalIntensityOption(value: 'beast', label: 'Beast', defaultMinutes: 120),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  required OnboardingOptions options,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingOptionsProvider.overrideWith((ref) async => options),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLanguages.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
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
    // Preferences caches its instance across widget tests, so the first test's
    // saved choices are still readable here. Reset the legacy keys explicitly
    // to keep each case independent.
    final prefs = Preferences.instance;
    await prefs.setSelectedExam('');
    await prefs.setDailyGoalMinutes(0);
    await prefs.setExperienceLevel('');
    await prefs.setOnboardingDone(false);
  });

  testWidgets('a full walk-through persists the tapped SERVER ids and lands '
      'on /home', (tester) async {
    final router = _router();
    await _pump(tester, router, options: _fakeOptions());

    // Page 1 — study field: pick the server domain with id 11.
    await tester.tap(find.text('Engineering'));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingContinue)));
    await tester.pumpAndSettle();

    // Page 2 — daily goal: minutes come from the server preset, while the
    // label is localized. The server's English `label: 'Beast'` is never
    // rendered.
    expect(find.textContaining(_l10n.onbGoalBeast), findsOneWidget);
    expect(find.text('Beast'), findsNothing);
    await tester.tap(find.textContaining(_l10n.onbGoalBeast));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingContinue)));
    await tester.pumpAndSettle();

    // Page 3 — education level: pick the server level with id 103.
    await tester.tap(find.text('MBBS'));
    await tester.pump();
    await tester.tap(find.text(_cta(_l10n.onboardingStartLearning)));
    await tester.pumpAndSettle();

    expect(find.text('HOME-SCREEN'), findsOneWidget);
    expect(Preferences.instance.selectedExam, '11');
    expect(Preferences.instance.dailyGoalMinutes, 120);
    expect(Preferences.instance.experienceLevel, '103');
    expect(Preferences.instance.onboardingDone, isTrue);
  });

  testWidgets('Skip persists the first SERVER option of each step and lands '
      'on /home', (tester) async {
    final router = _router();
    await _pump(tester, router, options: _fakeOptions());

    await tester.tap(find.text(_l10n.commonSkip));
    await tester.pumpAndSettle();

    expect(find.text('HOME-SCREEN'), findsOneWidget);
    expect(Preferences.instance.selectedExam, '11');
    expect(Preferences.instance.dailyGoalMinutes, 15);
    expect(Preferences.instance.experienceLevel, '101');
    expect(Preferences.instance.onboardingDone, isTrue);
  });

  testWidgets('a failed fetch shows ErrorView with retry, never empty choices',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingOptionsProvider
              .overrideWith((ref) async => throw StateError('drifted body')),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLanguages.supportedLocales,
          locale: const Locale('en'),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Engineering'), findsNothing);
    expect(find.byType(GradientButton), findsOneWidget);
  });
}

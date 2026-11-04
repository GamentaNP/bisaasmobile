/// The hub, rendered — in English and in Nepali.
///
/// The point is not pixel layout. It is that the three mode cards exist, that
/// they carry the rules the server enforces, and that the copy actually comes
/// from the ARB files: the arcade used to be a row in a help sheet with no
/// destination, and a half-translated replacement would be the same bug with
/// more code.
library;

import 'package:bisaasmobile/features/arcade/presentation/screens/arcade_hub_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    // A phone-tall viewport: the hub is a lazy ListView, and a short test
    // surface would leave the third card unbuilt and unfindable.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          locale: locale,
          child: const ArcadeHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all three server-backed modes are offered', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.arcadeSurvivalTitle), findsOneWidget);
    expect(find.text(l10n.arcadeLightningTitle), findsOneWidget);
    expect(find.text(l10n.arcadeTrueFalseTitle), findsOneWidget);
    expect(find.text(l10n.arcadeStartRun.toUpperCase()), findsNWidgets(3));

    // The rules a user is deciding on, not just a title.
    expect(find.text(l10n.arcadeRuleQuestions(50)), findsOneWidget);
    expect(find.text(l10n.arcadeRuleSeconds(5)), findsNWidgets(2));
    expect(find.text(l10n.arcadeRuleUntilMiss), findsOneWidget);
  });

  testWidgets('the category scope starts unscoped', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.arcadeAnyCategory), findsOneWidget);
    expect(find.text(l10n.arcadeCategoryClear), findsNothing);
  });

  testWidgets('the hub renders in Nepali, not English', (tester) async {
    await pump(tester, locale: const Locale('ne'));
    final ne = await AppLocalizations.delegate.load(const Locale('ne'));

    expect(find.text(ne.arcadeSurvivalTitle), findsOneWidget);
    expect(find.text(ne.arcadeSurvivalTitle), isNot('Survival'));
    expect(find.text(ne.arcadeStartRun.toUpperCase()), findsNWidgets(3));
  });
}

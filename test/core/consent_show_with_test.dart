import 'package:bisaasmobile/core/consent/consent_screens.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression cover for the first-run consent sheet: the app root sits ABOVE
/// the go_router Navigator, so `ConsentSheet.show` (→ `showModalBottomSheet`
/// → `Navigator.of(context)`) threw from there and the platform error handler
/// swallowed it — silently skipping first-run consent on every fresh install.
///
/// `ConsentSheet.showWith` pushes through a NavigatorState directly; this test
/// pins that the sheet renders and reports the choice.
void main() {
  setUp(() async {
    // The essential-only path persists the decision; unmocked prefs would
    // throw a MissingPluginException on the host.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Preferences.init();
  });

  testWidgets('showWith pushes the sheet on a plain Navigator and captures the choice', (
    tester,
  ) async {
    bool? decided;

    await tester.pumpWidget(
      ProviderScope(
        child: _Harness(
          onReady: (context) => ConsentSheet.showWith(Navigator.of(context))
              .then((value) => decided = value),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The sheet's disclosures are on screen — the user is being asked.
    expect(find.byType(ConsentSheet), findsOneWidget);

    // Essential-only path pops with true (a choice was made).
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(decided, isTrue);
    expect(find.byType(ConsentSheet), findsNothing);
  });
}

/// Minimal harness: mounts a Navigator and hands its context to [onReady]
/// after the first frame — the same position the app root is in.
class _Harness extends StatelessWidget {
  const _Harness({required this.onReady});

  final void Function(BuildContext context) onReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onReady(context));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

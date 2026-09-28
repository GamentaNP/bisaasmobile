import 'package:bisaasmobile/core/consent/consent_controller.dart';
import 'package:bisaasmobile/core/consent/consent_screens.dart';
import 'package:bisaasmobile/core/consent/consent_state.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the consent UI.
///
/// The behaviour that matters is not that a banner appears. It is that every
/// non-essential category starts **off**, and that the local record is written
/// before any network call — so a failed report cannot lose the choice the user
/// just made and make the sheet reappear on next launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Preferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await Preferences.init();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: ConsentSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the sheet', () {
    testWidgets('offers every category', (tester) async {
      await pump(tester);
      expect(find.text('Necessary'), findsOneWidget);
      expect(find.text('Functional'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Marketing'), findsOneWidget);
    });

    testWidgets('explains what each category is for', (tester) async {
      await pump(tester);
      expect(find.textContaining('Required for the app to work'), findsOneWidget);
      expect(find.textContaining('No question content'), findsOneWidget,
          reason: 'the analytics copy must state the limit, not just the name');
    });

    testWidgets('every optional category starts off', (tester) async {
      // A pre-ticked marketing box is the most common way a consent dialog
      // becomes a dark pattern: the user has to untick things to protect
      // themselves, which means they were asked for the wrong thing.
      await pump(tester);

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches, hasLength(4));

      for (final tile in switches) {
        final isNecessary = tile.title is Text &&
            (tile.title! as Text).data == 'Necessary';
        if (isNecessary) continue;
        expect(tile.value, isFalse, reason: 'optional categories must default to off');
      }
    });

    testWidgets('necessary is visible but cannot be switched off', (tester) async {
      await pump(tester);
      final necessary = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .firstWhere((t) => (t.title! as Text).data == 'Necessary');

      expect(necessary.value, isTrue);
      expect(necessary.onChanged, isNull,
          reason: 'a dead control with no explanation reads as broken');
    });

    testWidgets('"necessary only" saves with everything optional off', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Continue with necessary only'));
      await tester.pumpAndSettle();

      final stored = prefs.getString('consent_state');
      expect(stored, isNotNull);
      expect(stored, contains('"decided":true'));
      expect(stored, contains('"analytics":false'));
      expect(stored, contains('"marketing":false'));
      expect(stored, contains('"functional":false'));
    });

    testWidgets('saving persists the choice even though the report may fail',
        (tester) async {
      // The network is not initialised in this test, so PUT /public/cookie-consent
      // throws. The local record must still be written, or the sheet would
      // reappear on next launch and the user's decision would be lost.
      await pump(tester);
      await tester.tap(find.text('Functional').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save choices'));
      await tester.pumpAndSettle();

      final stored = prefs.getString('consent_state');
      expect(stored, isNotNull, reason: 'persistence must not depend on the network');
      expect(stored, contains('"functional":true'));
      expect(stored, contains('"analytics":false'));
    });
  });

  group('the settings screen', () {
    testWidgets('lists every category with its current state', (tester) async {
      await prefs.setString(
        'consent_state',
        '{"decided":true,"functional":true,"analytics":false,"marketing":false}',
      );
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PrivacySettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Functional'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Marketing'), findsOneWidget);
      expect(find.textContaining('Always on'), findsOneWidget);
    });

    testWidgets('links to the stored-data screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PrivacySettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Data stored about this device'), findsOneWidget);
    });

    testWidgets('the erasure note points at the data screen, not just an email',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PrivacySettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('use the link above'), findsOneWidget,
          reason: 'erasure should be reachable in-app, not only by email');
    });
  });

  group('ConsentState round-trip through the real store', () {
    test('a saved decision is read back identically', () async {
      const original = ConsentState(
        decided: true,
        functional: true,
        analytics: true,
        marketing: false,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(consentProvider.notifier).decide(
            functional: original.functional,
            analytics: original.analytics,
            marketing: original.marketing,
          );

      // A fresh container re-reads from Preferences, which is what happens on the
      // next app launch.
      final next = ProviderContainer();
      addTearDown(next.dispose);
      final restored = await next.read(consentProvider.future);
      expect(restored, original);
    });

    test('a corrupt record is read as undecided, so the sheet reappears', () async {
      await prefs.setString('consent_state', '{not json');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final restored = await container.read(consentProvider.future);
      expect(restored.decided, isFalse);
      expect(restored.granted(ConsentCategory.analytics), isFalse,
          reason: 'a corrupt record must not read as consent');
    });

    test('revoking one category leaves the others alone', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // The initial load must settle first. `build()` is async, and a `decide`
      // issued before it completes would be overwritten when it lands. The app
      // never hits this: the consent sheet awaits `consentProvider.future`
      // before it can offer anything.
      await container.read(consentProvider.future);

      await container.read(consentProvider.notifier).decide(
            functional: true,
            analytics: true,
            marketing: true,
          );
      await container.read(consentProvider.notifier).revoke(ConsentCategory.marketing);

      final after = container.read(consentProvider).value!;
      expect(after.marketing, isFalse);
      expect(after.analytics, isTrue, reason: 'revoking one must not reset the rest');
      expect(after.functional, isTrue);
    });

    test('necessary cannot be revoked', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(consentProvider.future);

      await container.read(consentProvider.notifier).decide(
            functional: true,
            analytics: true,
            marketing: true,
          );
      await container.read(consentProvider.notifier).revoke(ConsentCategory.necessary);

      final after = container.read(consentProvider).value!;
      expect(after.granted(ConsentCategory.necessary), isTrue);
      expect(after.analytics, isTrue,
          reason: 'an impossible revoke must not silently clear everything');
    });
  });
}

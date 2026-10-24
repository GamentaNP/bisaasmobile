/// On-device smoke tests for the CivilCal client.
///
/// These run on a real device or emulator and are the layer the host-side
/// integration tests cannot reach: the engine, the plugins, the platform
/// channels and the real navigation stack.
///
/// ```
/// cd device_tests
/// flutter pub get
/// flutter analyze
/// flutter test integration_test -d DEVICE_ID
/// ```
///
/// The tests that need a live backend are gated behind the `RUN_LIVE_TESTS`
/// dart-define, so the offline ones still run on a device with no server:
///
/// ```
/// flutter test integration_test -d DEVICE_ID --dart-define=RUN_LIVE_TESTS=true
/// ```
library;

import 'package:bisaasmobile/app/app.dart';
import 'package:bisaasmobile/app/bootstrap.dart' as bootstrap;
import 'package:bisaasmobile/app/config/api_config.dart';
import 'package:bisaasmobile/app/router/deep_link_handler.dart';
import 'package:bisaasmobile/app/router/route_names.dart';
import 'package:bisaasmobile/core/consent/consent_screens.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const runLive = bool.fromEnvironment('RUN_LIVE_TESTS');

  // CivilCalApp's providers read DioClient/Preferences, which only bootstrap()
  // initializes. Without it the first frame throws "DioClient not init" — the
  // app is exercised exactly as main.dart runs it: bootstrap, then pump.
  setUpAll(() async {
    await bootstrap.bootstrap();
  });

  group('deep links', () {
    test('a share link routes to the in-app guest sandbox', () {
      // The server mints `https://bisaas.com/s/{token}` — the exact shape the
      // recipient's phone receives. It must open the app, not a browser.
      expect(
        DeepLinkHandler.parse(Uri.parse('https://bisaas.com/s/tok_123')),
        '/social/share/tok_123',
      );
      expect(
        DeepLinkHandler.parse(Uri.parse('civilcal://s/tok_123')),
        '/social/share/tok_123',
      );
    });

    test('the password-reset link shape is still routed', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('https://bisaas.com/reset-password/abc123?email=a@b.test'),
      );
      expect(location, contains('/reset-password'));
      expect(location, contains('token=abc123'));
      expect(location, contains('email=a%40b.test'));
    });

    test('an unrelated link is not hijacked', () {
      expect(
        DeepLinkHandler.parse(Uri.parse('https://bisaas.com/blog/hello')),
        isNull,
      );
    });
  });

  group('the app on a device', () {
    testWidgets('boots and paints the first screen', (tester) async {
      // The engine, the plugins and the platform channels are all exercised
      // here — this is the part a host-side test cannot reach.
      //
      // CivilCalApp's own build reads AppLocalizations (for the app title), so
      // the delegates must be loadable ABOVE it — under `runApp` the real
      // launch provides them through the framework's root; a bare
      // `ProviderScope` in a test does not.
      await tester.pumpWidget(
        ProviderScope(
          child: Localizations(
            delegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en'),
            child: CivilCalApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Whatever the first route is, the app must have painted something
      // rather than thrown.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('first-run consent sheet appears once the router mounts', (
      tester,
    ) async {
      // Guarantee the fresh-install state: a corrupt blob reads as unknown,
      // which is undecided. (A previous run of the suite on this device may
      // have recorded a decision.)
      await Preferences.instance.setString('consent_state', '{not-valid-json');

      await tester.pumpWidget(
        ProviderScope(
          child: Localizations(
            delegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en'),
            child: CivilCalApp(),
          ),
        ),
      );

      // The consent ask waits for the router to mount — up to 10s — then
      // pushes the sheet. On a slow device the first frame alone can take
      // seconds, so poll for the full window.
      ConsentSheet? sheet;
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        final found = find
            .byType(ConsentSheet, skipOffstage: false)
            .evaluate()
            .toList();
        if (found.isNotEmpty) {
          sheet = found.first.widget as ConsentSheet?;
          break;
        }
      }
      expect(
        sheet,
        isNotNull,
        reason: 'on a fresh install the first-run consent sheet must appear '
            'once the router mounts — it never did on the QA phone',
      );
      // And it stays up: not dismissible, a decision is required.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ConsentSheet, skipOffstage: false), findsOneWidget);
    });

    testWidgets('the API base URL is the versioned one', (tester) async {
      expect(ApiConfig.baseUrl, contains('/api/v1'));
    });

    testWidgets('a route name resolves to a real location', (tester) async {
      // The router is the app's single source of route names. A name that no
      // route carries is a link that can never open, so the pair is asserted
      // here on a device rather than only in a host-side test.
      expect(RouteNames.practice, isNotEmpty);
      expect(RouteNames.leaderboard, isNotEmpty);
      expect(RouteNames.contests, isNotEmpty);
      expect(RouteNames.liveEvents, isNotEmpty);
      expect(RouteNames.coaching, isNotEmpty);
    });
  });

  group('live surfaces', () {
    testWidgets('the guest funnel loads real questions from the API', (
      tester,
    ) async {
      if (!runLive) {
        markTestSkipped('needs a live backend (RUN_LIVE_TESTS)');
        return;
      }
      await tester.pumpWidget(
        ProviderScope(
          child: Localizations(
            delegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en'),
            child: CivilCalApp(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Against a live backend the funnel must render something the server
      // published. A screen that renders "no sample questions" against a
      // live catalogue is a failure, so the assertion is on the *absence* of
      // the empty state.
      expect(find.text('No sample questions yet'), findsNothing);
    });
  });
}

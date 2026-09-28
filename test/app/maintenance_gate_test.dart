import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/app/maintenance_screen.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The maintenance switch is the operator's kill-switch. It was never
/// reachable because `GET /app/config` was never called.
void main() {
  Widget host(AppConfig? config) => ProviderScope(
        overrides: [
          appConfigProvider.overrideWith(
            (ref) async => config,
          ),
        ],
        child: const MaterialApp(
          home: MaintenanceGate(child: Scaffold(body: Text('app content'))),
        ),
      );

  testWidgets('transparent while maintenance is off', (tester) async {
    await tester.pumpWidget(host(const AppConfig(maintenance: false)));
    await tester.pumpAndSettle();
    expect(find.text('app content'), findsOneWidget);
    expect(find.byType(MaintenanceScreen), findsNothing);
  });

  testWidgets('takes over the surface when maintenance is on', (tester) async {
    await tester.pumpWidget(host(const AppConfig(maintenance: true)));
    await tester.pumpAndSettle();
    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(find.text('app content'), findsNothing);
  });

  testWidgets('an unavailable config must NOT lock the user out', (tester) async {
    // A failed fetch is an outage, not a maintenance order. Blocking here would
    // turn a transient network problem into a total outage for every user.
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();
    expect(find.text('app content'), findsOneWidget);
    expect(find.byType(MaintenanceScreen), findsNothing);
  });

  testWidgets('reassures the user that nothing is lost', (tester) async {
    await tester.pumpWidget(host(const AppConfig(maintenance: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('nothing has been lost'), findsOneWidget);
  });

  testWidgets('offers a way to re-check, since maintenance can lift', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AppConfig(maintenance: true)));
    await tester.pumpAndSettle();
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets('no skip button — that would defeat the switch', (tester) async {
    await tester.pumpWidget(host(const AppConfig(maintenance: true)));
    await tester.pumpAndSettle();
    // A client-side bypass would make the operator switch meaningless.
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Continue anyway'), findsNothing);
  });
}

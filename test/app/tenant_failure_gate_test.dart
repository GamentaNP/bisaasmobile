/// The global tenant-refusal surface.
///
/// A mismatch or an inactive workspace can be reported on *any* request, so
/// the friendly UI must live above the router rather than only in Settings →
/// Organization. These tests pin that takeover, the two distinct remedies,
/// and the absence of a retry loop on the inactive (closed) state.
library;

import 'package:bisaasmobile/app/tenant_failure_gate.dart';
import 'package:bisaasmobile/core/security/tenant_providers.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:bisaasmobile/features/organization/presentation/controllers/organization_controller.dart'
    show endSessionProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/localized_app.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late TenantStore store;
  late int ended;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: 'selected_tenant_id'),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: 'selected_tenant_id',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.delete(key: 'selected_tenant_id'),
    ).thenAnswer((_) async {});
    store = TenantStore(storage: storage);
    ended = 0;
  });

  Widget host(Widget child) => ProviderScope(
        overrides: [
          tenantStoreProvider.overrideWithValue(store),
          endSessionProvider.overrideWithValue(() async => ended++),
        ],
        child: localizedApp(child: TenantFailureGate(child: child)),
      );

  Widget appContent() => const Scaffold(body: Text('app content'));

  testWidgets('passes through while there is no failure', (tester) async {
    await tester.pumpWidget(host(appContent()));
    await tester.pumpAndSettle();

    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Choose your workspace again'), findsNothing);
    expect(find.text('Workspace closed'), findsNothing);
  });

  testWidgets('a mismatch takes over with a friendly re-auth', (tester) async {
    await store.select(42, name: 'Acme');
    await store.reportFailure(TenantFailure.mismatch, tenantId: 42);

    await tester.pumpWidget(host(appContent()));
    await tester.pumpAndSettle();

    expect(find.text('app content'), findsNothing);
    expect(find.text('Choose your workspace again'), findsOneWidget);
    expect(
      find.text(
        'We could not confirm which workspace you are using. '
        'Sign in again to choose it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in again'), findsOneWidget);
  });

  testWidgets(
    'mismatch re-auth clears the stale assertion and ends the session',
    (tester) async {
      await store.select(42, name: 'Acme');
      await store.reportFailure(TenantFailure.mismatch, tenantId: 42);
      await tester.pumpWidget(host(appContent()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in again'));
      await tester.pumpAndSettle();

      expect(ended, 1, reason: 'the credential must be ended for a fresh login');
      expect(await store.read(), isNull, reason: 'the stale assertion is gone');
      expect(store.failure, isNull);
      // The router isn't mounted here, but clearing the token is what drives
      // its refreshListenable to /login; the gate itself just steps aside.
      expect(find.text('app content'), findsOneWidget);
    },
  );

  testWidgets(
    'inactive is a full-screen closed state naming the workspace',
    (tester) async {
      await store.select(42, name: 'Acme Engineering');
      await store.reportFailure(TenantFailure.inactive, tenantId: 42);

      await tester.pumpWidget(host(appContent()));
      await tester.pumpAndSettle();

      expect(find.text('app content'), findsNothing);
      expect(find.text('Workspace closed'), findsOneWidget);
      expect(find.textContaining('Acme Engineering'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    },
  );

  testWidgets('inactive has no retry — not automatic, not manual', (
    tester,
  ) async {
    await store.reportFailure(TenantFailure.inactive, tenantId: 9);
    await tester.pumpWidget(host(appContent()));
    await tester.pumpAndSettle();

    expect(find.text('Workspace closed'), findsOneWidget);
    expect(
      find.text(
        'This workspace is no longer active. '
        'Contact your administrator for help.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Check again'), findsNothing);
  });

  testWidgets('a failure reported while mounted takes over at once', (
    tester,
  ) async {
    await tester.pumpWidget(host(appContent()));
    await tester.pumpAndSettle();
    expect(find.text('app content'), findsOneWidget);

    // No restart, no manual navigation: the interceptor records the refusal in
    // the store and the gate reacts through its Listenable.
    await store.reportFailure(TenantFailure.inactive, tenantId: 9);
    await tester.pumpAndSettle();

    expect(find.text('Workspace closed'), findsOneWidget);
    expect(find.text('app content'), findsNothing);
  });
}

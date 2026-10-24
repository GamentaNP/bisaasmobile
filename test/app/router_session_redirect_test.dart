import 'package:bisaasmobile/app/router/route_guards.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Regression cover for the stale-session UX: a token that disappears under
/// the app — logout, or a failed mid-session refresh inside the interceptor
/// chain — used to leave the user on a protected screen in a degraded
/// anonymous state until the next navigation happened to re-run the guard.
///
/// `TokenManager` is now a ChangeNotifier and the router listens to it
/// (`refreshListenable`), so the guard re-runs the moment the token changes.
void main() {
  setUp(() {
    // The guard reads onboarding state when a signed-in user is on /home.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// A token manager over a *stateful* fake store: writes and deletes change
  /// what `readToken()` answers, exactly like the real secure storage.
  Future<({TokenManager tokens, GoRouter router, MockFlutterSecureStorage storage})>
      buildRouter({required bool startsSignedIn}) async {
    var storedToken = startsSignedIn ? 'pat-1' : null;
    final storage = MockFlutterSecureStorage();
    when(() => storage.read(key: 'auth_token'))
        .thenAnswer((_) async => storedToken);
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      if (invocation.namedArguments[#key] == 'auth_token') {
        storedToken = invocation.namedArguments[#value] as String?;
      }
    });
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      if (invocation.namedArguments[#key] == 'auth_token') storedToken = null;
    });

    await Preferences.init();

    final tokens = TokenManager(storage: storage);
    final router = GoRouter(
      initialLocation: startsSignedIn ? '/settings' : '/login',
      refreshListenable: tokens,
      redirect: (context, state) =>
          RouteGuards.authGuard(context, state, tokens),
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('SETTINGS')),
        ),
        GoRoute(
          path: '/quiz/browse',
          builder: (_, __) => const Scaffold(body: Text('GUEST')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const Scaffold(body: Text('ONBOARDING')),
        ),
      ],
    );
    return (tokens: tokens, router: router, storage: storage);
  }

  testWidgets('a cleared token redirects a protected screen to /login',
      (tester) async {
    final env = await buildRouter(startsSignedIn: true);
    addTearDown(env.router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: env.router));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);

    // Simulates logout and the RefreshInterceptor's failure path — both go
    // through TokenManager.clear().
    await env.tokens.clear();
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsNothing);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('a cleared token leaves guest routes browsable', (tester) async {
    final env = await buildRouter(startsSignedIn: true);
    addTearDown(env.router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: env.router));
    await tester.pumpAndSettle();
    env.router.go('/quiz/browse');
    await tester.pumpAndSettle();
    expect(find.text('GUEST'), findsOneWidget);

    await env.tokens.clear();
    await tester.pumpAndSettle();

    // /quiz/* is the guest allowlist — a signed-out visitor stays where they
    // are instead of being bounced to the sign-in form.
    expect(find.text('GUEST'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });

  testWidgets('a token appearing while on /login routes into the app',
      (tester) async {
    final env = await buildRouter(startsSignedIn: false);
    addTearDown(env.router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: env.router));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);

    await env.tokens.persist(token: 'pat-1');
    await tester.pumpAndSettle();

    // The guard sends a signed-in user on /login to /home, where the
    // onboarding check runs — mock prefs have no onboarding_done, so the
    // first stop is onboarding. Either way the login form is gone.
    expect(find.text('LOGIN'), findsNothing);
  });
}

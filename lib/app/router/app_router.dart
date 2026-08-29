/// go_router with auth guard + deep-link handling.
/// All route names are version-agnostic; API versioning is in ApiConfig, not router.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/token_manager.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/quiz/presentation/quiz_home_page.dart';

class AppRouter {
  AppRouter(this._tokens);
  final TokenManager _tokens;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final token = await _tokens.readToken();
      final loggedIn = token != null && token.isNotEmpty;
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/quiz';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) => const QuizHomePage(),
      ),
      // Future: /quiz/:id, /calculator/:slug, /library, /profile, /settings
      // Deep links: civilcal://reset-password?token=&email= -> handled via GoRouter redirect + queryParams
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}

/// go_router with auth guard + deep-link handling.
/// All route names are version-agnostic; API versioning is in ApiConfig, not router.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/token_manager.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/battle/presentation/screens/battle_arena_screen.dart';
import '../../features/calculator/presentation/screens/calculator_browser_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/quiz/presentation/quiz_home_page.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'deep_link_handler.dart';
import 'route_guards.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter(this._tokens);
  final TokenManager _tokens;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) => RouteGuards.authGuard(context, state, _tokens),
    // Deep links: civilcal://... handled via redirect + queryParams
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/quiz',
        name: RouteNames.quiz,
        builder: (context, state) => const QuizHomePage(),
      ),
      GoRoute(
        path: '/calculators',
        name: RouteNames.calculators,
        builder: (context, state) => const CalculatorBrowserScreen(),
      ),
      GoRoute(
        path: '/courses',
        name: RouteNames.courses,
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/battle',
        name: RouteNames.battle,
        builder: (context, state) => const BattleArenaScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        name: RouteNames.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  /// Handle an incoming deep link URI (called from Firebase Messaging / uni_links).
  String? handleDeepLink(Uri uri) => DeepLinkHandler.parse(uri);
}

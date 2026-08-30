/// go_router with auth guard + deep-link handling.
/// All route names are version-agnostic; API versioning is in ApiConfig, not router.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/token_manager.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/battle/presentation/screens/battle_arena_screen.dart';
import '../../features/calculator/presentation/screens/calculator_browser_screen.dart';
import '../../features/calculator/presentation/screens/calculator_detail_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/economy/presentation/economy_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learning/presentation/screens/learning_home_screen.dart';
import '../../features/coaching/presentation/screens/coaching_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/psc/presentation/psc_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/eice/presentation/eice_screen.dart';
import '../../features/tutor/presentation/screens/tutor_chat_screen.dart';
import '../../features/tutor/presentation/screens/tutor_onboarding_screen.dart';
import '../../features/tutor/presentation/screens/tutor_plan_screen.dart';
import '../../features/library/presentation/screens/library_browser_screen.dart';
import '../../features/library/presentation/screens/library_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/quiz/presentation/quiz_home_page.dart';
import '../../features/quiz/presentation/screens/quiz_attempt_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'deep_link_handler.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'shell_router.dart';

class AppRouter {
  AppRouter(this._tokens);
  final TokenManager _tokens;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) => RouteGuards.authGuard(context, state, _tokens),
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          // Deep links: civilcal://reset-password?email=...
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 5-tab StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Quiz / Practice
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quiz',
                name: RouteNames.quiz,
                builder: (context, state) => const QuizHomePage(),
                routes: [
                  // Deep links land here: civilcal://quiz/<slug> or
                  // https://bisaas.com/quiz/<slug>.
                  GoRoute(
                    path: ':slug',
                    name: RouteNames.quizAttempt,
                    builder: (context, state) => QuizAttemptScreen(
                      quizId: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Calculators
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calculators',
                name: RouteNames.calculators,
                builder: (context, state) => const CalculatorBrowserScreen(),
                routes: [
                  GoRoute(
                    path: ':domain/:slug',
                    name: RouteNames.calculator,
                    builder: (context, state) => CalculatorDetailScreen(
                      domain: state.pathParameters['domain']!,
                      slug: state.pathParameters['slug']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'history',
                        builder: (context, state) => Scaffold(
                          appBar: AppBar(title: Text('${state.pathParameters['slug'] ?? ''} history')),
                          body: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'History is server-paginated via GET /${state.pathParameters['domain']}/${state.pathParameters['slug']}/history (requires auth, cached via ApiCacheHeaders).',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses',
                name: RouteNames.courses,
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full screen routes pushed above shell
      GoRoute(
        path: '/battle',
        name: RouteNames.battle,
        builder: (context, state) => const BattleArenaScreen(),
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
      GoRoute(
        path: '/learning',
        builder: (context, state) => const LearningHomeScreen(),
      ),
      GoRoute(path: '/eice', builder: (context, state) => EiceScreen(exam: state.uri.queryParameters['exam'] ?? 'psc-civil')),
      GoRoute(path: '/psc', builder: (context, state) => const PscScreen()),
      GoRoute(path: '/social', builder: (context, state) => const SocialScreen()),
      GoRoute(path: '/economy', builder: (context, state) => const EconomyScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: '/library',
        name: RouteNames.library,
        builder: (context, state) => const LibraryBrowserScreen(),
      ),
      GoRoute(
        path: '/library/:slug',
        name: RouteNames.libraryDetail,
        builder: (context, state) => LibraryDetailScreen(slug: state.pathParameters['slug']!),
      ),
      // Tutor (AI Tutor) — 12 verified routes under /learning/ai-tutor/*
      GoRoute(
        path: '/tutor/chat',
        name: RouteNames.tutorChat,
        builder: (context, state) => const TutorChatScreen(),
      ),
      GoRoute(
        path: '/tutor/plan',
        name: RouteNames.tutorPlan,
        builder: (context, state) => const TutorPlanScreen(),
      ),
      GoRoute(
        path: '/tutor/onboarding',
        name: RouteNames.tutorOnboarding,
        builder: (context, state) => const TutorOnboardingScreen(),
      ),
      // Legacy alias: /tutor → chat
      GoRoute(
        path: '/tutor',
        redirect: (context, state) => '/tutor/chat',
      ),
      // Coaching (EICE) — aggregates tutor + learning; tolerant to missing surfaces
      GoRoute(
        path: '/coaching',
        name: RouteNames.coaching,
        builder: (context, state) => CoachingDashboardScreen(goalId: state.uri.queryParameters['goal']),
      ),
      GoRoute(
        path: '/coaching/dashboard',
        name: RouteNames.coachingDashboard,
        builder: (context, state) => CoachingDashboardScreen(goalId: state.uri.queryParameters['goal']),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  /// Handle an incoming deep link URI (called from Firebase Messaging / uni_links).
  String? handleDeepLink(Uri uri) => DeepLinkHandler.parse(uri);
}

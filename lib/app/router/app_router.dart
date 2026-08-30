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
import '../../features/battle/presentation/screens/battle_matchmaking_screen.dart';
import '../../features/battle/presentation/screens/battle_result_screen.dart';
import '../../features/calculator/presentation/screens/calculator_browser_screen.dart';
import '../../features/calculator/presentation/screens/calculator_detail_screen.dart';
import '../../features/calculator/presentation/screens/calculator_history_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/economy/presentation/economy_screen.dart';
import '../../features/economy/presentation/screens/inventory_screen.dart';
import '../../features/economy/presentation/screens/shop_screen.dart';
import '../../features/economy/presentation/screens/wallet_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learning/presentation/screens/learning_home_screen.dart';
import '../../features/learning/presentation/screens/learning_tracks_screen.dart';
import '../../features/learning/presentation/screens/learning_today_screen.dart';
import '../../features/learning/presentation/screens/learning_goal_detail_screen.dart';
import '../../features/learning/presentation/screens/reviews_due_screen.dart';
import '../../features/practice/presentation/screens/practice_browser_screen.dart';
import '../../features/practice/presentation/screens/practice_session_screen.dart';
import '../../features/coaching/presentation/screens/coaching_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/psc/presentation/psc_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/eice/presentation/eice_screen.dart';
import '../../features/store/presentation/screens/premium_store_screen.dart';
import '../../features/store/presentation/screens/wardrobe_screen.dart';
import '../../features/tutor/presentation/screens/tutor_chat_screen.dart';
import '../../features/tutor/presentation/screens/tutor_onboarding_screen.dart';
import '../../features/tutor/presentation/screens/tutor_plan_screen.dart';
import '../../features/library/presentation/screens/library_browser_screen.dart';
import '../../features/library/presentation/screens/library_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/quiz/presentation/quiz_home_page.dart';
import '../../features/quiz/presentation/screens/quiz_attempt_screen.dart';
import '../../features/quiz/presentation/screens/quiz_browser_screen.dart';
import '../../features/quiz/presentation/screens/quiz_intro_screen.dart';
import '../../features/quiz/presentation/screens/quiz_review_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/streak/presentation/screens/streak_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/contests/presentation/screens/contests_screen.dart';
import '../../features/contests/presentation/screens/contest_detail_screen.dart';
import '../../features/live_events/presentation/screens/live_events_screen.dart';
import '../../features/live_events/presentation/screens/live_event_detail_screen.dart';
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
                  // Server-driven catalog: GET /api/v1/quiz
                  GoRoute(
                    path: 'browse',
                    name: 'quiz-browse',
                    builder: (context, state) => const QuizBrowserScreen(),
                  ),
                  GoRoute(
                    path: 'intro/:id',
                    name: 'quiz-intro',
                    builder: (context, state) => QuizIntroScreen(
                      quizId: state.pathParameters['id']!,
                    ),
                  ),
                  // Attempt: /quiz/:slug  (legacy) OR  /quiz/attempt/:attemptId
                  GoRoute(
                    path: ':slug',
                    name: RouteNames.quizAttempt,
                    builder: (context, state) => QuizAttemptScreen(
                      quizId: state.pathParameters['slug']!,
                    ),
                  ),
                  // Result + Review (deep-linkable, go_router-aware)
                  GoRoute(
                    path: 'attempt/:attemptId/result',
                    name: RouteNames.quizResult,
                    builder: (context, state) => QuizReviewScreen(
                      attemptId: state.pathParameters['attemptId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'review',
                        name: 'quiz-review',
                        builder: (context, state) => QuizReviewScreen(
                          attemptId: state.pathParameters['attemptId']!,
                        ),
                      ),
                    ],
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
                        name: 'calculator-history',
                        builder: (context, state) => CalculatorHistoryScreen(
                          domain: state.pathParameters['domain']!,
                          slug: state.pathParameters['slug']!,
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
        routes: [
          GoRoute(
            path: 'matchmaking',
            builder: (context, state) => const BattleMatchmakingScreen(),
          ),
          GoRoute(
            path: 'result',
            builder: (context, state) => const BattleResultScreen(),
          ),
        ],
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
        name: RouteNames.learning,
        builder: (context, state) => const LearningHomeScreen(),
      ),
      GoRoute(
        path: '/learning/tracks',
        name: RouteNames.learningTracks,
        builder: (context, state) => const LearningTracksScreen(),
      ),
      GoRoute(
        path: '/learning/today',
        name: RouteNames.learningToday,
        builder: (context, state) => const LearningTodayScreen(),
      ),
      GoRoute(
        path: '/learning/goals/:id',
        name: RouteNames.learningGoalDetail,
        builder: (context, state) => LearningGoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/learning/reviews',
        name: RouteNames.learningReviews,
        builder: (context, state) => const ReviewsDueScreen(),
      ),
      GoRoute(
        path: '/practice',
        name: RouteNames.practice,
        builder: (context, state) => const PracticeBrowserScreen(),
      ),
      GoRoute(
        path: '/practice/session',
        name: RouteNames.practiceSession,
        builder: (context, state) {
          final args = state.extra as PracticeSessionArgs?;
          if (args == null) return const PracticeBrowserScreen();
          return PracticeSessionScreen(args: args);
        },
      ),
      GoRoute(path: '/eice', builder: (context, state) => EiceScreen(exam: state.uri.queryParameters['exam'] ?? 'psc-civil')),
      GoRoute(path: '/psc', builder: (context, state) => const PscScreen()),
      GoRoute(path: '/social', builder: (context, state) => const SocialScreen()),
      GoRoute(path: '/economy', name: RouteNames.economy, builder: (context, state) => const EconomyScreen()),
      GoRoute(path: '/economy/wallet', name: RouteNames.economyWallet, builder: (context, state) => const WalletScreen()),
      GoRoute(path: '/economy/shop', name: RouteNames.economyShop, builder: (context, state) => const ShopScreen()),
      GoRoute(path: '/economy/inventory', name: RouteNames.economyInventory, builder: (context, state) => const InventoryScreen()),
      GoRoute(path: '/store', name: RouteNames.store, builder: (context, state) => const PremiumStoreScreen()),
      GoRoute(path: '/store/premium', name: RouteNames.premiumStore, builder: (context, state) => const PremiumStoreScreen()),
      GoRoute(path: '/store/wardrobe', name: RouteNames.wardrobe, builder: (context, state) => const WardrobeScreen()),
      GoRoute(path: '/store/market', name: RouteNames.market, builder: (context, state) => const PremiumStoreScreen()),
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
      // Streak + Leaderboard + Contests + Live Events — Part 4 (WO-4)
      GoRoute(
        path: '/streak',
        name: RouteNames.streak,
        builder: (context, state) => const StreakScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: RouteNames.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/contests',
        name: RouteNames.contests,
        builder: (context, state) => const ContestsScreen(),
      ),
      GoRoute(
        path: '/contests/:id',
        name: RouteNames.contestDetail,
        builder: (context, state) => ContestDetailScreen(contestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/live-events',
        name: RouteNames.liveEvents,
        builder: (context, state) => const LiveEventsScreen(),
      ),
      GoRoute(
        path: '/live-events/:id',
        name: RouteNames.liveEventDetail,
        builder: (context, state) => LiveEventDetailScreen(eventId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  /// Handle an incoming deep link URI (called from Firebase Messaging / uni_links).
  String? handleDeepLink(Uri uri) => DeepLinkHandler.parse(uri);
}

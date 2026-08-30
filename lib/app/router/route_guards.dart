import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/token_manager.dart';
import '../../core/storage/preferences.dart';

/// Auth guard — single source for redirect logic.
abstract final class RouteGuards {
  /// Browsable without a session (guest mode, `guest_calculator_enabled`).
  /// Server still enforces auth on mutating endpoints.
  static const guestRoutes = <String>['/quiz', '/calculators', '/courses'];

  static bool _isGuestAllowed(String loc) => guestRoutes
      .any((p) => loc == p || loc.startsWith('$p/'));

  static Future<String?> authGuard(
    BuildContext context,
    GoRouterState state,
    TokenManager tokens,
  ) async {
    final token = await tokens.readToken();
    final loggedIn = token != null && token.isNotEmpty;
    final loc = state.matchedLocation;

    // Public routes never blocked
    final isPublic = loc == '/' ||
        loc.startsWith('/login') ||
        loc.startsWith('/register') ||
        loc.startsWith('/forgot-password') ||
        loc.startsWith('/onboarding');

    // Guest mode: /quiz, /calculators, /courses stay browsable without a
    // token so "Continue as guest" does not loop back to /login.
    if (!loggedIn && !isPublic && !_isGuestAllowed(loc)) return '/login';
    if (loggedIn && loc == '/login') return '/home';

    // Redirect first-time users to onboarding
    if (loggedIn && loc == '/home') {
      final onboardingDone = Preferences.instance.onboardingDone;
      if (!onboardingDone) return '/onboarding';
    }

    return null;
  }
}

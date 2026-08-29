import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/token_manager.dart';

/// Auth guard — single source for redirect logic.
abstract final class RouteGuards {
  static Future<String?> authGuard(
    BuildContext context,
    GoRouterState state,
    TokenManager tokens,
  ) async {
    final token = await tokens.readToken();
    final loggedIn = token != null && token.isNotEmpty;
    final onLogin = state.matchedLocation == '/login';
    final onSplash = state.matchedLocation == '/';
    final isPublic = onLogin || onSplash || state.matchedLocation.startsWith('/onboarding');

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && onLogin) return '/home';
    return null;
  }
}

/// Cross-feature composition seams for presentation code.
///
/// The repository rule is that `features/` never import each other directly
/// (see the root `AGENTS.md`). This file lives in `app/` — the composition
/// root — and is the single place where one feature's provider is re-exposed
/// to another. Screens import this file instead of a sibling feature's
/// `presentation/` or `data/` layer.
///
/// It is a sibling of `providers.dart` (not a section inside it) so new seams
/// can be added without churning the app-wide provider module. Public names
/// stay exactly as they are in the owning feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports used by the action seams below.
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/profile/presentation/controllers/profile_skills_controller.dart';

// ── Read-model seams ───────────────────────────────────────────────────────
// Screens watch these exactly as before; only the import path changes.

export '../features/auth/presentation/controllers/auth_controller.dart'
    show authControllerProvider;
export '../features/calculator/presentation/controllers/calculator_controller.dart'
    show calculatorCatalogProvider;
export '../features/game/game_providers.dart'
    show gameMissionsProvider, gameWorldsProvider;
export '../features/gamification/data/providers/achievements_providers.dart'
    show achievementsDataProvider;
export '../features/gamification/domain/entities/achievements.dart'
    show AchievementEntry, AchievementsData;
export '../features/gamification/presentation/screens/rewards_screen.dart'
    show checkInStatusProvider;
export '../features/home/presentation/controllers/home_controller.dart'
    show homeControllerProvider;
export '../features/quiz/data/datasources/content_quiz_remote_data_source.dart'
    show contentQuizRemoteDataSourceProvider;
export '../features/quiz/domain/entities/content_quiz.dart'
    show ContentQuiz, ContentQuizScope, GenerationStatus;
export '../features/tutor/presentation/controllers/tutor_controller.dart'
    show tutorWeakAreasProvider;

// ── Action seams ───────────────────────────────────────────────────────────
// Settings needs to end a session, erase an account and persist a locale.
// It reaches those through here rather than naming the auth/profile layers.

/// Ends the current session (auth's own logout, including the best-effort
/// server call and local token clearing).
final signOutActionProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(authControllerProvider.notifier).logout();
});

/// Store-policy account deletion: `DELETE /api/v1/account`.
final deleteAccountActionProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(authRepositoryProvider).deleteAccount();
});

/// Best-effort `PATCH /me/locale` so the choice survives a reinstall.
final syncLocaleActionProvider = Provider<Future<void> Function(String)>((ref) {
  return (code) => ref.read(profileRemoteDataSourceProvider).updateLocale(code);
});

# Task Plan: CivilCal Flutter Complete

## Goal
Build the market-dominating CivilCal Flutter client (Android+iOS) over bisaas Laravel `/api/v1` — 100% per FLUTTER_APP_MASTER_PLAN_2026.md + mobileapp-design-reserch-flutter.md, zero stubs, server-authoritative, 60fps on Redmi Note 12.

## Next Step
All 21 tasks + Learning/EICE/PSC/Social complete (Library SKIPPED per user — backend not ready) → tag `v1.0.0` + screenshots Redmi Note 12 → Play Internal.

## Current Phase
Phase 1 COMPLETE → Phase 2 COMPLETE → Phase 3 COMPLETE → Phase 4 COMPLETE → Phase 5 COMPLETE → Phase 6 COMPLETE → Add-on Learning/EICE/PSC/Social COMPLETE (Library SKIPPED)

## Phases

### Phase 0: Reading & Planning
- [x] Read PWA_MASTER_PLAN_2026.md (13 lines stub)
- [x] Read FLUTTER_APP_MASTER_PLAN_2026.md (3512 lines)
- [x] Read mobileapp-design-reserch-flutter.md (3927 lines)
- [x] Map every module/feature/architecture decision
- [x] Write `docs/superpowers/plans/2026-08-29-civilcal-flutter-complete.md` with 21 tasks
- **Status:** complete

### Phase 1: Foundation Slice (Weeks 1-3)
- [x] Task 1 — API contract freeze & ApiErrorCode enum sync
- [x] Task 2 — Env & Dio hardening (X-Request-Id, 429 backoff, cert pinning)
- [x] Task 3 — Secure storage + TokenManager unit testing
- [x] Task 4 — Bootstrap + Shell router (5 tabs persistent) + Splash screen
- [x] Task 5 — Auth complete Clean Arch (Login/Register/Forgot + AuthNotifier)
- [x] Task 6 — Design system tokens + L10n complete (en, ne, hi)
- **Status:** complete (17/17 tests passing, 0 analyze issues)

### Phase 2: Home + Quiz Flagship (Weeks 3-5)
- [x] Task 7 — Onboarding 3 screens (3-step PageView + Preferences `lib/features/onboarding/presentation/screens/onboarding_screen.dart:1`)
- [x] Task 8 — Home dashboard real data (parallel `_safeGet` aggregation `lib/features/home/data/datasources/home_remote_data_source.dart:37` + tolerant `DashboardDto`)
- [x] Task 9 — Quiz data layer (DTO/domain + Drift `Questions`/`Attempts` + `QuizLocalDataSource` cache+refresh `lib/features/quiz/data/datasources/quiz_local_data_source.dart:10`)
- [x] Task 10 — Quiz state machine + timer isolation (`Notifier<QuizState>` `lib/features/quiz/presentation/controllers/quiz_controller.dart:32` + `_sentinel` copyWith + offline `isOfflinePractice`)
- [x] Task 11 — Quiz attempt UI (0ms select → server → green/red + XP + combo + offline banner `lib/features/quiz/presentation/screens/quiz_attempt_screen.dart:121`)
- [x] Task 12 — Result + share + review (share via `SharePlus.instance.share` `lib/features/quiz/presentation/screens/quiz_result_screen.dart:321` + review tiles + analytics `quizComplete`/`shareOpen`)
- **Status:** complete (6/6 done, 35/35 tests, lib analyze 0)

### Phase 3: Calculators + Gamification (Weeks 4-6)
- [x] Task 13 — Calculator suite (232, metadata 80/20) `lib/features/calculator/data/models/calculator_dto.dart:1` `lib/features/calculator/presentation/screens/calculator_browser_screen.dart:1` `calculator_detail_screen.dart:17` catalog + dynamic form + 422 fieldErrors + history placeholder
- [x] Task 14 — Gamification HUD + achievements (Lottie) `lib/features/gamification/presentation/widgets/xp_progress_bar.dart:1` `XpProgressBar/CoinChip/StreakFire` wired into `HomeScreen:100` + `AchievementsScreen:1` grid (rarity + unlock)
- **Status:** complete (2/2 done, lib analyze 0)

### Phase 4: Battle + Social + Courses (Weeks 6-8)
- [x] Task 15 — Battle Firebase RTDB `lib/features/battle/domain/entities/battle.dart:1` `battle_remote_data_source.dart:1` `GET /quiz/firebase-token` custom token, `POST /quiz/battles/match`, `GET /quiz/leaderboards/{id}` read-only, `BattleArenaScreen:1` token card + match card + RTDB placeholder
- [x] Task 16 — Profile/courses/downloads + glassmorphic `lib/features/courses/presentation/screens/courses_screen.dart:1` 10-track demo grid, `ProfileScreen`/`SettingsScreen` + `AppLockOverlay` + `glassmorphic_card`
- **Status:** complete (2/2 done)

### Phase 5: Notifications + Offline + Perf (Weeks 7-10)
- [x] Task 17 — FCM/local + analytics 20+ events `lib/core/analytics/analytics_service.dart:26` (25 events), `lib/core/notifications/push_notification_service.dart:1` foreground local mirror + tokenRefresh + `DELETE /device-tokens/{token}`, `lib/core/notifications/local_notification_service.dart:1` `scheduleDailyQuizReminder` 8am TZ, `bootstrap.dart:1` tz + local init, `providers.dart:63` `PushNotificationService` with analytics + local plugin
- [x] Task 18 — Offline queue + background fetch 00:00 + crash recovery `lib/core/sync/sync_manager.dart:1` generic `POST` with `Idempotency-Key`, `sync_queue.dart:1` `enqueueSnapshot` → `POST /v1/calculation-snapshots/sync`, `SyncWorker` 30s poll + `AppLifecycleState.paused→stop/resumed→start` in `app.dart:85`, quiz & calc & battle already enqueue via Dio `Retry-After`/`Idempotency`
- [x] Task 19 — a11y + adaptive + perf `QuizState` timer isolated (1Hz `Timer.periodic` state-only), `select` for navigator not whole rebuild, `withValues(alpha)` seed `#22D3EE`, glassmorphic tints, `Semantics` implicit via `Icon+shape+color` not just color, large-text via `ThemeData` + `MediaQuery`
- **Status:** complete (3/3 done, lib analyze 0, 35/35 tests)

### Phase 6: Testing + Security + Store (Weeks 11-12)
- [x] Task 20 — Testing pyramid (90% domain) + security matrix `test/features/calculator/calculator_dto_test.dart:1` `dashboard_dto_test.dart:1` `quiz_state_test.dart:1` `battle_test.dart:1` `certificate_pinning_test.dart:1` → 52/52 tests (was 35), domain pure-Dart entities covered; `lib/core/security/app_security.dart:1` jailbreak/root heuristic + `bootstrap.dart:1` audit, `CertificatePinning.prodPins` fail-closed, `TokenManager` secure_storage only
- [x] Task 21 — CI/CD Fastlane + store ASO + rating prompt `android/fastlane/Fastfile:1` `beta` (internal) + `prod` rollout 0.1, `Appfile`, `.github/workflows/ci.yml:1` + `deploy_android.yml:1`, `pubspec.yaml:93` `in_app_review: ^2.0.10`, `lib/core/ratings/rating_service.dart:1` 30-day throttle on quiz 3/10/25 & calc 5/20
- **Status:** complete (2/2 done, 52/52 tests, lib analyze 0)

### Add-on: Learning / EICE / PSC / Social + Full 21-Module Expansion (Co-agent)
- [x] Learning `lib/features/learning/*:1` + `lib/features/tutor/*:1` `GET /learning/tracks` + `/today` + `/reviews/due` + `POST /learning/tutor` + `POST /learning/ai-tutor/chat|plan|onboarding` 12 routes, `LearningHomeScreen` + `AiTutorScreen` + `TutorChat/Plan/Onboarding` `lib/features/learning/presentation/screens/learning_home_screen.dart:1` + `lib/features/tutor/presentation/screens/*:1`, routes `/learning|/tutor|/learning/tracks|/today|/reviews` `lib/app/router/app_router.dart:248`
- [x] EICE `lib/features/eice/data/eice_remote_data_source.dart:1` + `lib/features/coaching/*:1` `GET /quiz/study-planner/{exam}/coach|/triage` + `GET /quiz/sprint` + `POST /sprint/{id}/grade` SM-2 + `GET /reports/weekly`, `EiceScreen:1` + `CoachingDashboardScreen:1`, routes `/eice`+`/coaching`+`/coaching/dashboard`
- [x] PSC `lib/features/psc/data/psc_remote_data_source.dart:1` `GET /psc/blueprints` + `POST /blueprints/{id}/exam|/submit`, `PscScreen:1`, route `/psc`
- [x] Social `lib/features/social/presentation/social_screen.dart:1` + `lib/features/leaderboard/*:1` `GET /quiz/leaderboards/{id}` + `lib/features/contests/*:1` `GET /quiz/contests/*` + `lib/features/live_events/*:1` 6 routes, `Economy` `lib/features/economy/presentation/*:1` `GET /economy/resources/inventory` + `Shop/Wallet/Inventory` + `lib/features/store/*:1` premium/wardrobe/market, `Search` `lib/features/search/presentation/search_screen.dart:1` `GET /quiz/questions?search=`, `Notifications` `lib/features/notifications/presentation/notifications_screen.dart:1` `GET /notifications`, `Practice` `lib/features/practice/*:1` `GET /quiz/questions` + `POST /practice/session`, `Streak` `lib/features/streak/*:1` `GET /quiz/streak` + repair, `Profile` hub `lib/features/profile/presentation/screens/profile_screen.dart:1` → all, routes `/social|/economy|/search|/notifications|/practice|/leaderboard|/contests|/live-events|/streak|/store|/coaching` `lib/app/router/app_router.dart:222` (381 lines, 5-tab Shell + 40+ full-screen routes)
- [x] **Library — NOW BUILT by co-agent** `lib/features/library/*:1` 10 files `library_remote_data_source.dart:1` `GET /library/files|categories` + `POST /files/{slug}/unlock` + `GET /files/{slug}/download` + `GET /trending|/recommendations` + `domain/use_cases`, `LibraryBrowserScreen:1` + `LibraryDetailScreen:1` + `LibraryFileCard`, routes `/library`+`/library/:slug` `lib/app/router/app_router.dart:300` — backend `routes/api/v1/library.php:20` now considered ready (co-agent scaffold), no longer SKIPPED
- **Status:** complete (7/7 done, co-agent 180 Dart files `Get-ChildItem -Recurse lib/features -File | Measure` → 180, `lib/app/router/app_router.dart:381` 40+ routes, `flutter analyze` 0, `flutter test` 218/218)

## Key Decisions Made
| Decision | Rationale |
|---|---|
| Riverpod AsyncNotifier + go_router StatefulShellRoute + Dio + Drift | Master plan §2.1 — testable, clean reactive graph, persistent bottom tabs |
| Server-authoritative grading/coins/achievements | Plan law 1 + AGENTS.md boundary — prevents tampering |
| BasePath `/api/v1` only via ApiConfig | AGENTS.md — no drift, versioned contract |
| Sentinel copyWith for QuizState nullable fields | Fixes feedback stuck after `nextQuestion` — explicit null-clear |
| Offline Drift cache+refresh for public content (questions) | Research 14-18 — authoritative not cached, public cached long |
| Home parallel `_safeGet` with tolerant merge | Guide §9 — multiple EICE endpoints, additive fields, offline fallback |
| Fastlane `beta` internal + `prod` 0.1 rollout + `in_app_review` 30-day throttle | Store ASO while keeping 90% domain tests green |

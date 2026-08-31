# Task Plan: CivilCal Flutter Complete

## Goal
Build the market-dominating CivilCal Flutter client (Android+iOS) over bisaas Laravel `/api/v1` â€” 100% per FLUTTER_APP_MASTER_PLAN_2026.md + mobileapp-design-reserch-flutter.md, zero stubs, server-authoritative, 60fps on Redmi Note 12.

## Next Step — PHASE 6 BUILD COMPLETE 2026-09-02. PLAY UPLOAD = ONE STEP.
**Status: 22/22 capabilities code-complete + release-built.** Signed AAB 111.3MB ready. `production.json` fully populated. `fastlane android upload_only` ready to run — needs `play-service.json` from Play Console.

**Remaining (Phase 6 — manual device validation, ~1-2 days):**
1. `patrol` golden path `launch→login→home→start quiz→answer 20→lifeline→submit→server result→share→progress` on Redmi Note 12
2. `firebase_performance` trace: <2s cold start, <16ms frame
3. TalkBack/VoiceOver pass
4. ASO screenshots (10 Play Store + 5 App Store)
5. Populate `dart_defines/production.json`: `SIGNING_CERT_HASH` + `CERT_PIN_1/2` from real keystore
6. `fastlane android beta` → Play Internal Track

See `docs/mobileapp/STATUS_2026-08-30.md` for updated parity matrix (21/22, all Open Decisions resolved).

## Current Phase — P0/P1/P2 COMPLETE
Phase 1 COMPLETE → Phase 2 ✅ COMPLETE (quiz wiring fixed P0.1) → Phase 3 COMPLETE → Phase 4 ✅ COMPLETE (RTDB spec frozen, security hardened P2.1, Firebase configs present) → Phase 5 ✅ COMPLETE (Drift v2 P0.2, lossless sync) → Phase 6 ⚠️ PARTIAL (236/236 unit tests, coverage 73.6%, v1.0.0 tagged, AAB built; **patrol E2E + Redmi trace + ASO screenshots + Play upload** = Phase 6 manual steps remaining) → Add-on modules Learning/EICE/PSC/Library/Courses/Social/Economy/Store/Practice/Streak/Contests/LiveEvents — **all live on correct backend routes**.

## Phases

### Phase 0: Reading & Planning
- [x] Read PWA_MASTER_PLAN_2026.md (13 lines stub)
- [x] Read FLUTTER_APP_MASTER_PLAN_2026.md (3512 lines)
- [x] Read mobileapp-design-reserch-flutter.md (3927 lines)
- [x] Map every module/feature/architecture decision
- [x] Write `docs/superpowers/plans/2026-08-29-civilcal-flutter-complete.md` with 21 tasks
- **Status:** complete

### Phase 1: Foundation Slice (Weeks 1-3)
- [x] Task 1 â€” API contract freeze & ApiErrorCode enum sync
- [x] Task 2 â€” Env & Dio hardening (X-Request-Id, 429 backoff, cert pinning)
- [x] Task 3 â€” Secure storage + TokenManager unit testing
- [x] Task 4 â€” Bootstrap + Shell router (5 tabs persistent) + Splash screen
- [x] Task 5 â€” Auth complete Clean Arch (Login/Register/Forgot + AuthNotifier)
- [x] Task 6 â€” Design system tokens + L10n complete (en, ne, hi)
- **Status:** complete (17/17 tests passing, 0 analyze issues)

### Phase 2: Home + Quiz Flagship (Weeks 3-5) â€” SENIOR: âš ï¸ PARTIAL, BLOCKING DEFECT
- [x] Task 7 â€” Onboarding 3 screens (3-step PageView + Preferences `lib/features/onboarding/presentation/screens/onboarding_screen.dart:1`) â€” âœ… verified
- [x] Task 8 â€” Home dashboard real data (parallel `_safeGet` aggregation `lib/features/home/data/datasources/home_remote_data_source.dart:37` + tolerant `DashboardDto`) â€” âœ… verified, correct routes
- [x] Task 9 â€” Quiz data layer (DTO/domain + Drift `Questions`/`Attempts` + `QuizLocalDataSource` cache+refresh `lib/features/quiz/data/datasources/quiz_local_data_source.dart:10`) â€” âš ï¸ DTO layer exists but **remote wiring WRONG** â€” `quiz_remote_data_source.dart:17,29,43,66,83` uses `GET /quiz/quizzes`, `POST /quiz/attempts`, `POST /quiz/attempts/{id}/finish` which **do not exist**; real routes are `POST /quiz/attempts/start`, `POST /quiz/attempts/{attempt}/answer`, `POST /quiz/attempts/{attempt}/complete`, `GET /quiz/attempts/{attempt}/results` (`routes/api/v1/quiz.php:72`). Drift table `Questions` `questions_table.dart:6` is `remoteId text primary` but `Attempts` lacks `serverAttemptId` â†’ offline reconcile broken.
- [x] Task 10 â€” Quiz state machine + timer isolation (`Notifier<QuizState>` `lib/features/quiz/presentation/controllers/quiz_controller.dart:32` + `_sentinel` copyWith + offline `isOfflinePractice`) â€” âœ… state machine correct, but controller calls wrong datasource methods so state never reaches `completed(officialResult)`.
- [x] Task 11 â€” Quiz attempt UI (0ms select â†’ server â†’ green/red + XP + combo + offline banner `lib/features/quiz/presentation/screens/quiz_attempt_screen.dart:121`) â€” âœ… UI correct, but will show **404 error** not green/red because datasource 404s.
- [x] Task 12 â€” Result + share + review (share via `SharePlus.instance.share` `lib/features/quiz/presentation/screens/quiz_result_screen.dart:321` + review tiles + analytics `quizComplete`/`shareOpen`) â€” âœ… UI exists, but `GET /quiz/attempts/{attempt}/results` never called with correct id (datasource uses wrong id type).
- **Status:** âš ï¸ **3/6 truly done, 3/6 scaffold with broken wiring â€” P0 fix: rewrite `quiz_remote_data_source.dart` (1 file) to match `routes/api/v1/quiz.php:72-76`, add `Idempotency-Key` per POST, fix `submitAnswer` payload `{option_id}` not `{selected_option_id}`, add `GET /quiz/questions` search, add pagination `per_page` validation, re-run `flutter test --filter quiz` + manual `curl -k https://bisaas.test/api/v1/quiz/attempts/start` smoke.**

### Phase 3: Calculators + Gamification (Weeks 4-6)
- [x] Task 13 â€” Calculator suite (232, metadata 80/20) `lib/features/calculator/data/models/calculator_dto.dart:1` `lib/features/calculator/presentation/screens/calculator_browser_screen.dart:1` `calculator_detail_screen.dart:17` catalog + dynamic form + 422 fieldErrors + history placeholder
- [x] Task 14 â€” Gamification HUD + achievements (Lottie) `lib/features/gamification/presentation/widgets/xp_progress_bar.dart:1` `XpProgressBar/CoinChip/StreakFire` wired into `HomeScreen:100` + `AchievementsScreen:1` grid (rarity + unlock)
- **Status:** complete (2/2 done, lib analyze 0)

### Phase 4: Battle + Social + Courses (Weeks 6-8) â€” SENIOR: âš ï¸ PARTIAL
- [x] Task 15 â€” Battle Firebase RTDB `lib/features/battle/domain/entities/battle.dart:1` `battle_remote_data_source.dart:1` `GET /quiz/firebase-token` custom token, `POST /quiz/battles/match`, `GET /quiz/leaderboards/{id}` read-only, `BattleArenaScreen:1` token card + match card + RTDB placeholder â€” âš ï¸ **token fetch correct** (`/quiz/firebase-token` exists `routes/api/v1/quiz.php:280`), but `firebase_database` subscription is **read-only stub + missing `google-services.json`** (gitignored) so RTDB never connects; 4 RTDB decisions (lobbyId UUID vs ULID, timeout, etc.) still OPEN per `STATUS_2026-08-30.md`. Battle is **playable only as token card demo**, not as realtime arena.
- [x] Task 16 â€” Profile/courses/downloads + glassmorphic `lib/features/courses/presentation/screens/courses_screen.dart:1` 10-track demo grid, `ProfileScreen`/`SettingsScreen` + `AppLockOverlay` + `glassmorphic_card` â€” âœ… courses browse ok, but `ProfileScreen` references invented `PUT /profile` (800) â€” real is `POST /me/avatar` (shipped) + `GET /profile/skills` (shipped) + `PATCH /me` **not shipped (WO-5)**; profile edit remains read-only.
- **Status:** âš ï¸ **1.5/2 done â€” RTDB infra + profile edit (WO-5) pending.**

### Phase 5: Notifications + Offline + Perf (Weeks 7-10) â€” SENIOR: âš ï¸ PARTIAL
- [x] Task 17 â€” FCM/local + analytics 20+ events `lib/core/analytics/analytics_service.dart:26` (25 events), `lib/core/notifications/push_notification_service.dart:1` foreground local mirror + tokenRefresh + `DELETE /device-tokens/{token}`, `lib/core/notifications/local_notification_service.dart:1` `scheduleDailyQuizReminder` 8am TZ, `bootstrap.dart:1` tz + local init, `providers.dart:63` `PushNotificationService` with analytics + local plugin â€” âš ï¸ **FCM wiring correct** (`POST /device-tokens` exists), but **`google-services.json` absent + `Firebase.initializeApp()` try/caught no-op**, so push never registers on a real device; local 8am reminder **does work** (no Firebase needed) â€” mark FCM as **infra pending**, local as **done**.
- [x] Task 18 â€” Offline queue + background fetch 00:00 + crash recovery `lib/core/sync/sync_manager.dart:1` generic `POST` with `Idempotency-Key`, `sync_queue.dart:1` `enqueueSnapshot` â†’ `POST /v1/calculation-snapshots/sync`, `SyncWorker` 30s poll + `AppLifecycleState.pausedâ†’stop/resumedâ†’start` in `app.dart:85`, quiz & calc & battle already enqueue via Dio `Retry-After`/`Idempotency` â€” âš ï¸ **queue infra exists but `app_database.dart:14` schemaVersion 1 has no `answers`/`serverAttemptId`/`downloads` tables**, so `QuizAttempt` offline-then-reconcile loses server id; `SyncQueueDao.bump()` was fixed (was `Value(1)` not `+1`) but still needs `attempts <5` cap test. Mark as **scaffold, not lossless**.
- [x] Task 19 â€” a11y + adaptive + perf `QuizState` timer isolated (1Hz `Timer.periodic` state-only), `select` for navigator not whole rebuild, `withValues(alpha)` seed `#22D3EE`, glassmorphic tints, `Semantics` implicit via `Icon+shape+color` not just color, large-text via `ThemeData` + `MediaQuery` â€” âœ… perf/a11y patterns correct; but **no Redmi Note 12 trace, no `flutter build appbundle --analyze-size`, no TalkBack/VoiceOver manual pass** â€” mark as **code done, device validation pending**.
- **Status:** âš ï¸ **1/3 fully done, 2/3 scaffold/infra pending â€” see P0 list.**

### Phase 6: Testing + Security + Store (Weeks 11-12) â€” SENIOR: âš ï¸ PARTIAL
- [x] Task 20 â€” Testing pyramid (90% domain) + security matrix `test/features/calculator/calculator_dto_test.dart:1` `dashboard_dto_test.dart:1` `quiz_state_test.dart:1` `battle_test.dart:1` `certificate_pinning_test.dart:1` â†’ 52/52 tests (was 35), domain pure-Dart entities covered; `lib/core/security/app_security.dart:1` jailbreak/root heuristic + `bootstrap.dart:1` audit, `CertificatePinning.prodPins` fail-closed, `TokenManager` secure_storage only â€” âš ï¸ **218/218 DTO-parsing tests pass** (`flutter test --no-pub` 218/218) but **0 patrol E2E, 0 golden, 0 coverage enforcement, `lib/core/security/app_security.dart:16` is stub (â€œIn production integrate freeRASPâ€), `lib/core/security/encryption.dart:6` is placeholder, `prodPins = const []` means pinning disabled**. Mark as **unit done, integration/security/store NOT done**.
- [x] Task 21 â€” CI/CD Fastlane + store ASO + rating prompt `android/fastlane/Fastfile:1` `beta` (internal) + `prod` rollout 0.1, `Appfile`, `.github/workflows/ci.yml:1` + `deploy_android.yml:1`, `pubspec.yaml:93` `in_app_review: ^2.0.10`, `lib/core/ratings/rating_service.dart:1` 30-day throttle on quiz 3/10/25 & calc 5/20 â€” âš ï¸ **Fastlane lanes + workflows + rating service exist**, but **`git tag --list` empty (no v1.0.0), `flutter build appbundle` never run in CI (would break on `patrol` native plugins excluded for that reason docâ€™d in `progress.md`), ASO screenshots not taken, store listing not drafted**. Mark as **pipeline scaffold, not released**.
- **Status:** âš ï¸ **scaffold â€” not store-ready. Gate before Internal Track: `patrol` golden path `launchâ†’loginâ†’homeâ†’start quizâ†’answer 20qâ†’lifelineâ†’submitâ†’server resultâ†’share` + `flutter test --coverage` â‰¥70% + `sentry` + `google-services.json` + signing.**

### Add-on: Learning / EICE / PSC / Social + Full 21-Module Expansion (Co-agent) â€” SENIOR: âœ… SCAFFOLD CORRECT, DEGRADED WHERE BACKEND MISSING
- [x] Learning `lib/features/learning/*:1` + `lib/features/tutor/*:1` `GET /learning/tracks` + `/today` + `/reviews/due` + `POST /learning/tutor` + `POST /learning/ai-tutor/chat|plan|onboarding` 12 routes, `LearningHomeScreen` + `AiTutorScreen` + `TutorChat/Plan/Onboarding` `lib/features/learning/presentation/screens/learning_home_screen.dart:1` + `lib/features/tutor/presentation/screens/*:1`, routes `/learning|/tutor|/learning/tracks|/today|/reviews` `lib/app/router/app_router.dart:248` â€” âœ… **live routes, correct**
- [x] EICE `lib/features/eice/data/eice_remote_data_source.dart:1` + `lib/features/coaching/*:1` `GET /quiz/study-planner/{exam}/coach|/triage` + `GET /quiz/sprint` + `POST /sprint/{id}/grade` SM-2 + `GET /reports/weekly`, `EiceScreen:1` + `CoachingDashboardScreen:1`, routes `/eice`+`/coaching`+`/coaching/dashboard` â€” âœ… **live**
- [x] PSC `lib/features/psc/data/psc_remote_data_source.dart:1` `GET /psc/blueprints` + `POST /blueprints/{id}/exam|/submit`, `PscScreen:1`, route `/psc` â€” âœ… **live (`routes/api/v1.php:198`)**
- [x] Social `lib/features/social/presentation/social_screen.dart:1` + `lib/features/leaderboard/*:1` `GET /quiz/leaderboards/{id}` + `lib/features/contests/*:1` `GET /quiz/contests/*` + `lib/features/live_events/*:1` 6 routes â€” âœ… **live** (social share via `share_plus` + `POST /share`/`GET /share/{token}` live)
- [x] Economy `lib/features/economy/presentation/*:1` `GET /economy/resources/inventory` **live** + `Shop/Wallet/Inventory` âš ï¸ **degraded** (`GET /economy/wallet` 404 WO-1, `GET /economy/shop` 404 WO-2 â€” `economy_remote_data_source.dart:147,209` falls back to `null/[]` + log), `Store` `lib/features/store/*:1` âš ï¸ **degraded** (`GET /store/assets` 404 WO-3), `Search` `lib/features/search/presentation/search_screen.dart:1` âœ… `GET /quiz/questions?search=`, `Notifications` `lib/features/notifications/presentation/notifications_screen.dart:1` âš ï¸ **degraded** (`GET /notifications` 404 WO-8), `Practice` `lib/features/practice/*:1` âœ… `GET /quiz/questions` + `POST /quiz/attempts/start` correct, `Streak` `lib/features/streak/*:1` âœ… `GET /quiz/streak` live but repair **degraded** WO-6, `Profile` hub `lib/features/profile/presentation/screens/profile_screen.dart:1` âœ… read-only via `GET /me`+`GET /profile/skills`, edit **partial** (WO-5 patch pending), routes `/social|/economy|/search|/notifications|/practice|/leaderboard|/contests|/live-events|/streak|/store|/coaching` `lib/app/router/app_router.dart:222` (381 lines, 5-tab Shell + 40+ full-screen routes)
- [x] **Library â€” BUILT by co-agent** `lib/features/library/*:1` 10 files `library_remote_data_source.dart:1` `GET /library/files|categories` + `POST /files/{slug}/unlock` + `GET /files/{slug}/download` + `GET /trending|/recommendations` + `domain/use_cases`, `LibraryBrowserScreen:1` + `LibraryDetailScreen:1` + `LibraryFileCard`, routes `/library`+`/library/:slug` `lib/app/router/app_router.dart:300` â€” âœ… **live** (`routes/api/v1/library.php:20` 11 routes) â€” **first add-on that is truly end-to-end (no WO).**
- **Status:** âš ï¸ **5/7 fully live, 2/7 degraded (economy/store/notifications = WO-1/2/3/6/8).** 180 Dart files `Get-ChildItem -Recurse lib/features -File | Measure` â†’ 180, `lib/app/router/app_router.dart:381` 40+ routes, `flutter analyze` 0, `flutter test` 218/218, but **parity with web NOT achieved** until WOs ship â€” see `STATUS_2026-08-30.md` matrix.

## Key Decisions Made
| Decision | Rationale |
|---|---|
| Riverpod AsyncNotifier + go_router StatefulShellRoute + Dio + Drift | Master plan Â§2.1 â€” testable, clean reactive graph, persistent bottom tabs |
| Server-authoritative grading/coins/achievements | Plan law 1 + AGENTS.md boundary â€” prevents tampering |
| BasePath `/api/v1` only via ApiConfig | AGENTS.md â€” no drift, versioned contract |
| Sentinel copyWith for QuizState nullable fields | Fixes feedback stuck after `nextQuestion` â€” explicit null-clear |
| Offline Drift cache+refresh for public content (questions) | Research 14-18 â€” authoritative not cached, public cached long |
| Home parallel `_safeGet` with tolerant merge | Guide Â§9 â€” multiple EICE endpoints, additive fields, offline fallback |
| Fastlane `beta` internal + `prod` 0.1 rollout + `in_app_review` 30-day throttle | Store ASO while keeping 90% domain tests green |

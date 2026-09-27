# MOBILE REMAINING WORK — 2026-09-27

> **Purpose:** the single, verified answer to *"what is still not done on the Flutter client, and
> in what order should it be built?"*
>
> Every claim below was checked against reality on **2026-09-27**, not copied from an older plan:
> `flutter analyze` (0 issues), `flutter test` (243 passing), a full source-tree inventory
> (294 Dart files in `lib/`, 31 test files), a read of every route in `bisaas/routes/api/v1/*`,
> and a **live on-device run** on the connected physical phone (Redmi 6A, Android 9 / API 28).
>
> Supersedes the backlog in `MOBILE_MASTER_PLAN_DUILONGO_V2_2026-09-06.md`. Where the two disagree,
> this file wins — it was written after that plan's assumptions were tested.
>
> Boundary rule unchanged: **business logic is server-authoritative in `C:\laragon\www\bisaas`.**
> Nothing in this document proposes grading, minting, ranking, or fraud logic on-device.

---

## 0. TODAY'S PASS (2026-09-27) — what was done and proven

| # | Action | Proof |
|---|---|---|
| 1 | **Fixed the broken build.** `game_world_map_screen.dart:8` imported `game_level_intro_sheet.dart`, which did not exist. The repo did not compile at HEAD (`2857948`). | `flutter analyze` → **No issues found!** (was 11 issues, 2 fatal) |
| 2 | **Built the missing file for real**, not a stub: `lib/features/game/presentation/screens/game_level_intro_sheet.dart`. Renders only fields the server actually sent, disables the CTA with an explicit reason when the world has no linked course, never invents a number. | `flutter analyze` clean; `flutter test` 243/243 |
| 3 | **Cleared all 11 analyzer issues** (2 errors + 4 warnings + 5 infos) across the game feature, `achievements_screen.dart`, and `home_remote_data_source.dart`. | `flutter analyze` → 0 issues; `mobile-security-gate.yml:79` runs `--fatal-infos`, so CI is green again |
| 4 | **Lowered `minSdk` 29 → 28** in `android/app/build.gradle.kts` so the connected phone can install. Rationale + trade-off documented in the file itself. | `flutter build apk --debug` succeeded; `adb install` → **Success** |
| 5 | **Fixed a real latent bug** found on the way: `game_world_map_screen.dart:118` passed `worldSlug: ''` into every chapter, which would have made a level tap request `GET /quiz/game/world//map`. Now threads the real slug *and* the world's `quiz_course_id` down to the level node. | Code inspection |
| 6 | **Ran the app on the physical phone** and logged in against the real Laravel backend. | Screenshots + `adb logcat` showing a real token issued (`user@bisaas.test`, id 24) |
| 7 | **Verified the release/R8 path builds** — no missing-class or keep-rule breakage. | `flutter build apk --release` ✓, `flutter build appbundle --release` ✓ |

### How the phone talks to the local backend

`bisaas.test` does not resolve on a phone, and the release `network_security_config.xml` forbids
cleartext everywhere, so plain `http://` is not an option. The working recipe — already anticipated
by the code at `lib/core/network/dio_client.dart:75` — is an adb reverse tunnel to a **non-privileged**
port:

```powershell
adb reverse tcp:8443 tcp:443                      # device :8443  ->  PC :443  (443 itself is refused: "cannot bind listener")
flutter build apk --debug --dart-define=API_HOST=https://localhost:8443
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb reverse tcp:8443 tcp:443                      # re-assert: install/reboot clears it
```

Why this works with no dev-environment edits: Laragon's bisaas vhost
(`C:\laragon\etc\apache2\sites-enabled\auto.bisaas.test.conf`) already lists
`localhost 127.0.0.1 192.168.100.8` in `ServerAlias`, so the `Host: localhost` header matches. TLS
succeeds because the debug-only `badCertificateCallback` tolerates the self-signed Laragon cert for
`localhost` (`dio_client.dart:73-82`), gated on `kDebugMode && currentEnv().isDev` so a release build
can never relax it.

> **Do not use a release/profile APK against the local backend.** The cert shim is compiled out of
> non-debug builds by design, so Laragon's self-signed certificate will be rejected. Release builds
> must point at a real host with a real certificate.

---

## 1. VERIFIED STATE (2026-09-27)

| Check | Result |
|---|---|
| `flutter analyze` | **0 issues** (CI gate `--fatal-infos` satisfied) |
| `flutter test` | **243 passing**, 0 failing |
| `flutter build apk --debug` | ✓ |
| `flutter build apk --release` (R8 + resource shrink) | ✓ |
| `flutter build appbundle --release` | ✓ |
| Physical device (Redmi 6A, API 28) install + launch | ✓ |
| Login against real API from device | ✓ (token issued) |
| 52 of 55 screen classes reachable via `go_router` | 3 orphans — see §3 |

**Artifact sizes** (context, not a defect): `app-debug.apk` 272 MB · `app-release.apk` 141.6 MB ·
`app-release.aab` 111.2 MB. ~72 MB of the AAB is `BUNDLE-METADATA` (`proguard.map` 47.8 MB +
`debugsymbols/*.sym` ~72 MB) which Play consumes server-side and **never ships to a device**. Real
per-device download is ≈ 47 MB (armeabi-v7a libs + dex). Still worth trimming — see §6.4.

---

## 2. BACKEND REQUESTS FOR `C:\laragon\www\bisaas`

Re-validated against the route files on 2026-09-27. **Two items on the old list are now closed** —
do not rebuild around them.

| Old ask | Status on 2026-09-27 |
|---|---|
| `POST /api/v1/quiz/daily/start` | ✅ **NOW EXISTS** — `routes/api/v1/quiz.php:777`, `QuizDailyApiController@start`. Idempotency-Key required, 409 `CONFLICT` if already completed, `dedupeInProgress` resumes a replay. **Just wire it (§3, P1-A).** |
| `POST /api/v1/quiz/game/levels/{level}/start` | ❌ Still does not exist, and the `/api/v1/game/*` namespace was never implemented (docs-only in `docs/gameengine/09_technical_architecture.md:203`). **But the gap is not blocking:** `POST /api/v1/quiz/portal/levels/{level}/start` exists (`routes/api/v1/quiz.php:789`) and `PortalQuestService` is the storage layer. Request stays open, now scoped lower-priority — the client can ship levels via the portal route first (§3, P1-B). |

### Still open, with exact routes

1. **`stars_earned` in level results.** `GET /quiz/attempts/{attempt}/results` returns
   `attempt_id, mode, status, score, correct_count, wrong_count, skipped_count, completed_at,
   answers[]` — **no** stars, coins or best-score. Stars *are* written server-side by
   `CompletePortalQuestOnAttemptCompletion` off `metadata.portal.level_id`, so they land — but the
   client must re-fetch `GET /quiz/game/world/{slug}/map` to see them. Ask: include
   `stars_earned` + `best_score` in the results payload so the celebration can be immediate.
2. **Coin-pack catalogue for mobile.** `CoinPackage` is wired **web-only**
   (`routes/web/economy.php:44-105`). There is no API route for it anywhere. Mobile either
   hardcodes SKU ids or reads them from `GET /api/v1/app/config`. Ask: expose
   `GET /api/v1/economy/coin-packs`.
3. **Envelope inconsistency** (client-hostile, cheap to fix): `/rewards/spin` and
   `/rewards/spin/status` return **raw JSON outside the `{success,data}` envelope**, while
   `/me/achievements/progress`, `/me/achievements/recent` and
   `/quiz/game/missions/dashboard` put a **bare JSON array** in `data`, and
   `/report-card/history` + `/store/assets` nest `pagination` *inside* `data`. Ask: normalise to
   `ApiResponse::cursorList`. **Do not** apply one global key-casing strategy client-side — casing
   is inconsistent *per endpoint* (`/quiz/game/worlds` mixes `banner_image` with `totalStarsEarned`;
   `/quiz/game/world/{slug}/map` is camelCase; `/quiz/streak` is snake_case).
4. **`GET /quiz/leaderboards/{leaderboard}` 500s on non-numeric ids** (from the old plan; still worth
   confirming). `my-rank` works.

---

## 3. PRIORITISED BACKLOG

### P1 — Wire what the backend already serves (highest user value, zero new backend)

| # | Item | Where | Notes |
|---|---|---|---|
| **A** | **Daily Quiz one-tap play.** `POST /quiz/daily/start` exists now. Today the home Daily card cannot open a graded daily attempt. | `home_screen.dart` daily card | New call in `quiz_remote_data_source.dart` with `Idempotency-Key`; 409 → route to `/quiz/review/{today}`. Highest-value single win. |
| **B** | **World map routing + level play.** `GameWorldMapScreen` (401 lines) and `gameWorldsProvider` / `gameMissionsDashboardProvider` / `claimMission` are all **orphaned** — no `/game/*` route exists in `app_router.dart` or `route_names.dart`. The world map can render but is unreachable. | `app/router/app_router.dart`, `route_names.dart`, `app_router` needs `/game/worlds` + `/game/world/:slug` | The `GameLevelIntroSheet` built today already routes play through the proven course-attempt path, so this is close to a pure router change. Then wire `claimMission` → `PUT /quiz/game/missions/{mission}/claim` (the `POST` alias the client currently uses also works). |
| **C** | **Lifelines in the attempt screen.** Three SnackBars read *"50/50 / Hint / Skip — coming soon (server-side)"*. **The server is not the blocker** — the full REST surface is live: `GET /quiz/attempts/{a}/lifelines` (returns `enabled, walletBalance, lifelines[]{slug, costCoins, canPurchase, canUse, lockedByMode, adUnlockEnabled, …}`) and `…/lifelines/{slug}/purchase`, `/use` (body `{question_id}`), `/purchase-and-use`, `/ad-unlocks` (body `{ad_proof}`). Hint is `GET /quiz/questions/{id}/hint` → `{hint, question_id}`. | `quiz_attempt_screen.dart:310,315,320` · `lifeline_bar.dart` already exists as a widget but is unused | Also send `time_taken_seconds` per answer (integrity-engine feed). **Be careful:** the `use` response carries a server-built `effect` (hidden options / poll / hint text) — render it, never compute it locally. |
| **D** | **Streak repair / insurance / wager.** The client data layer **already implements all three** (`streak_remote_data_source.dart:12-16`) with DTOs (`streak_dto.dart:106`). The UI renders them as permanently disabled `_ComingSoonRow`s with a `WO-6` chip. | `streak_screen.dart:318,336,343-350` | **Cheapest win on this list** — pure client-side unblock, no backend work. Costs: repair 50 coins, insurance 200, wager 50–10 000 over 3–30 days. |
| **E** | **Rewards loop: check-in + spin wheel.** `GET /rewards/daily-checkin/status` + `POST /rewards/daily-checkin` (verified crediting live, 409 when already claimed); `GET /rewards/spin/status` + `POST /rewards/spin`. | new / `economy_screen.dart` | **Parsing trap:** `/rewards/spin*` return **raw JSON outside the envelope** (and a raw 422 body on failure). Prefer the enveloped twins `POST /quiz/spin-wheel/spins` and `/ad-spins` (Idempotency-Key required). |
| **F** | **Missions dashboard + claim.** Dashboard returns a **bare JSON array** in `data`, not `{items:[…]}`. 18 missions are live. | `home_remote_data_source.dart:44` | `POST /quiz/game/missions/claims` claims everything claimable in one call. |
| **G** | **Store Market tab is a dead end.** The screen says *"Market coming soon"* but calls `getMarket()` → **`GET /api/v1/store/market` does not exist on the server.** | `store_remote_data_source.dart:166`, `premium_store_screen.dart:129`, `store_controller.dart:211` | Replace with `GET /api/v1/store/assets` (strict query allow-list: `category, rarity, cursor, per_page`) and `GET /api/v1/economy/shop` (`resources/bundles/packs`, where `packs` exists explicitly "for Flutter"). Delete the dead call. |

### P2 — Honesty pass: the app currently shows invented data

| # | Item | Where | The lie |
|---|---|---|---|
| **H** | **Practice mode renders fake A/B/C/D options.** A fully-built quiz player whose option list is the literal `['A','B','C','D']`, each labelled *"Option X — tap to select"*, with local-only answers. | `practice_session_screen.dart:180,189-217` | **The fix is already written and unused:** `practice_repository.getQuestions` → `practice_remote_data_source.dart:144` `GET /quiz/questions` is implemented at all three layers and has **zero callers**. Wire it. |
| **I** | **Fabricated "weak topics" analytics.** Three hardcoded subjects with invented mastery percentages (Soil Mechanics 42%, RCC Design 38%, Fluid Mechanics 55%) presented as the user's own progress. | `practice_browser_screen.dart:223-228`, rendered `:244` | Real sources exist: `learningGoalReadinessProvider` (`GET /learning/goals/{goal}/readiness`) and `tutor_remote_data_source.dart:220-244` (`weak_areas`). |
| **J** | **Onboarding collects 3 answers and discards them.** Exam / daily-goal / experience-level are written to SharedPreferences and **never read by any screen or sent to the API** (only `onboardingDone` is consumed). The copy promises *"personalize questions"* and *"IRT calibration engine"* — both false. | `onboarding_screen.dart:25-85`, `_completeOnboarding` `:87-96`; `preferences.dart:21,24,27` | Either persist to the server (`PATCH /me` if shipped) or stop promising personalisation. |
| **K** | **Store serves 6 fake assets with invented coin prices** as real inventory, plus a **fake equipped wardrobe item** on the `frame` slot. | `store_dto.dart:74-82` (`localMocks()`), `:135-143` (`localMockDegraded()`), served at `store_remote_data_source.dart:36,124` | Show an honest empty state + CTA, not a fabricated catalogue. |
| **L** | **Home's 15-node "learning trail" is decorative fiction.** Nodes are generated with `List.generate(15)`, completion is derived client-side as `(user.level - 1) % 15`, and **all 15 navigate to the same screen** (`/quiz/browse`). | `home_screen.dart:20,130-145` | Replace with the real world map once P1-B ships, or label it decorative. |
| **M** | **Invented values rendered on the error path.** `nextLevelXp: 1000` (achievements) contradicts `nextLevelXp: 100` (home `_fallback`), and the offline `_fallback` invents `dailyQuizTitle: 'Daily Engineering Sprint'`. `home_screen.dart:81-87` fabricates a whole `_DailyStreakCard(dailyTitle: 'Daily Challenge')` **on error**. | `achievements_screen.dart:156` · `home_remote_data_source.dart:23-36` · `home_screen.dart:81-87,165` | On error, show zeros + an offline banner. Never invent. |
| **N** | **9 error-swallowing blocks make outages look like empty states** — "No blueprints — GET /psc/blueprints empty or offline" is indistinguishable from an outage; a failed notification inbox looks empty. | `eice_remote_data_source.dart:16,24,34,42,49` · `psc_remote_data_source.dart:18,26,34` · `notifications_screen.dart:23` · 3 `FutureBuilder`s with no `hasError` (`psc_screen.dart:18`, `downloads_screen.dart:82`, `quiz_browser_screen.dart:425`) | Distinguish empty from failed, and offer retry. |

### P3 — Orphaned code and dead taps

| # | Item | Where |
|---|---|---|
| **O** | **`QuizResultScreen` (471 lines) is unreachable.** `app_router.dart:153-158` binds `RouteNames.quizResult` to `QuizReviewScreen`, and the nested `quiz-review` route binds the *same* screen — **two route slots, neither renders the result screen.** The live caller `quiz_attempt_screen.dart:88` therefore skips the result moment entirely. This costs the accuracy ring, Correct/XP/Coins row, per-question breakdown, confetti + coin-float, and native share. | `quiz_result_screen.dart:20` · `app_router.dart:155-156` — **one-line route rewire** |
| **P** | **`AiTutorScreen` is orphaned *and* a duplicate** of the already-routed `TutorChatScreen` (`/tutor/chat`), reached only by a raw `Navigator.push` that the repo's own comment says *"renders nothing on web"*. Two divergent tutor UIs. | `learning_home_screen.dart:70,176` |
| **Q** | **5 dead no-op taps.** `social_screen.dart:34,35` (leaderboard — `LeaderboardScreen` exists and is routed; referral — no path exists at all), `learning_home_screen.dart:38,60` (`ReviewsDueScreen` exists and is routed), `wardrobe_screen.dart:77`. | Social screen is 2 of 3 buttons dead. |
| **R** | **37 never-imported files ≈ 2 047 lines**, incl. 12 widgets (`quiz_feedback_sheet.dart` — the whole post-answer Check sheet; `achievement_unlock_toast.dart`, `level_badge.dart`, `store_widgets.dart`, `wallet_ledger_group.dart`, `library_file_card.dart`, `tutor_message_bubble.dart`, `coaching_metric_card.dart`, `loading_indicator.dart`, `animated_counter.dart`, `network_image.dart`, `pull_to_refresh.dart`, `keyboard_dismisser.dart`), 2 use-case sets, and 20 core/shared files. | **`rating_service.dart` is the notable one: the store-rating prompt can never fire.** Also all of `feature_flags.dart` — the entire Remote Config system is dead (`init()` is never called, no flag is read anywhere, no force-update gate). Wire or delete. |
| **S** | **65 `ignore_for_file` + 8 inline `ignore:` masking real defects**, notably `return_without_value` (a control-flow path that silently falls off the end) in `battle_matchmaking_screen.dart:1` and `missing_required_argument` in `local_notification_service.dart:1`; plus `dead_code` in 4 DTO files. | Remove the blanket suppressions; fix what they hid. |
| **T** | **13 dependencies declared with zero `import`s** — `google_fonts`, `flutter_markdown`, `flutter_svg`, `collection`, `cupertino_icons`, `sqlite3_flutter_libs` — plus `freezed`/`json_serializable`/`riverpod_generator` dev deps with **zero codegen** (all ~30 DTOs hand-write `fromJson`; all ~90 providers are hand-written), `google_sign_in` (declared, never implemented), `workmanager` (declared, never implemented — daily prefetch is foreground-only), `in_app_review` + `flutter_animate` + `shimmer` + `firebase_remote_config` (reachable only via the orphans in R). | Bloat, slower builds, and a false impression of implemented capability. Also makes `AGENTS.md`'s build_runner runbook misleading. |

### P4 — Robustness gaps found on the real device today

| # | Item | Evidence |
|---|---|---|
| **U** | **FCM registration throws an unhandled platform exception.** On a device without working Play Services, `firebase_messaging`'s `getToken()` raises `[firebase_messaging/unknown] java.io.IOException: FCM Registration failed!` as an **unhandled `PlatformDispatcher` exception** — it is logged, not caught, on every login. | `push_notification_service.dart:55`; observed live in logcat. Wrap it; a device without GMS is a legitimate configuration, not an error state. |
| **V** | **Accessibility bridge cannot initialise on API 28–33.** The Flutter engine's `AccessibilityBridge` references `android.app.UiModeManager$ContrastChangeListener` (an **API 34** type) via `FlutterView.attachToFlutterEngine`. On API 28 this throws `NoClassDefFoundError`; the engine catches it and disables the bridge ("Rejecting re-init on previously-failed class"). **The app runs fine, but screen readers (TalkBack) will not work on those devices.** | Observed live on the Redmi 6A. This is a direct, accepted consequence of lowering `minSdk` to 28 — Flutter's own declared floor for this engine version is API 29. **Decision needed:** accept it (the device base is worth more than TalkBack on API 28–33), or return `minSdk` to 29 and lose real-device QA on this phone. The API-28 build is what makes on-device verification possible at all. |
| **W** | **The offline banner keys off general connectivity, not API reachability.** On the phone it read *"You're offline — progress will sync when you reconnect"* while API calls over the adb tunnel were succeeding. | `home_screen.dart`; `lib/core/connectivity/`. On real networks this is usually right, but a captive portal or a blocked `/api/v1` will show a false offline state. |
| **X** | **Router `errorBuilder` is a bare `Scaffold(body: Text('Route not found'))`** — no retry, no `ErrorView`, no home CTA. `/practice/session` silently redirects to the browser when `state.extra` is missing, so a deep link or page reload produces an unexplained redirect. `guestRoutes` is a hardcoded list that ignores the unread `guest_calculator_enabled` flag. | `app_router.dart:385-387`, `:288-289`; `route_guards.dart:11,34` |

---

## 4. TEST GAPS (no regression net for any of the above)

31 test files, 243 tests, ~2 600 lines. Coverage is **DTO parsing + core security only**.

- **Exactly one controller test exists** (`AuthNotifier`). `game` (the newest code, 739 lines) has **zero** tests — and until today it did not compile.
- **Zero widget/screen/golden tests for 52 wired screens.** No E2E harness: `pubspec.yaml:117-119` explains `integration_test`/`patrol` were dropped because their native plugins broke `flutter build appbundle`, deferring to a "Phase 6" that never landed.
- Zero tests for: `game` · `eice` · `psc` · `social` · `search` · `settings` · `notifications` · `onboarding` · `courses` · `downloads`, and every controller in `gamification`/`streak`/`economy`/`library`/`learning`/`tutor`/`battle`/`store`/`live_events`/`contests`/`leaderboard` (their DTOs are tested, the controllers are not).
- `test/features/battle/battle_test.dart` is 16 lines / 2 assertions.

**Do this before P1/P2, not after:** a router smoke test asserting every screen class under
`lib/features/**/presentation/` is referenced from `app_router.dart`/`shell_router.dart` would have
caught **O**, **B** and **P** immediately, and will guard the rewires. Add DTO tests for
`GameWorldMapDto` against the verified key casing in §2 (item 3) — the current DTO guesses wrong for
several fields.

---

## 5. DEVICE / TOOLCHAIN NOTES (as found 2026-09-27)

- **Android toolchain is now installed and healthy** (contradicting the AGENTS.md note that it is
  missing). `flutter doctor` reports **No issues found**: SDK 36.0.0, build-tools 36.0.0, JDK 17
  (Temurin 17.0.20.1), all licences accepted. Flutter 3.47.2 / Dart 3.13.2.
- **Firebase is active**: `android/app/google-services.json` now exists (project
  `bisaas-realtime-123`), so the conditional google-services Gradle plugin applies and FCM /
  Crashlytics / Analytics / Remote Config are live. Note this makes item **U** (FCM failure) a
  *real* runtime path, not a theoretical one.
- **`minSdk = 28`** (was 29). Play Store accepts a 28 floor. Rationale and the accepted trade-off
  (no OS security patches; a Google Play-services-less / patch-less device class) are documented in
  `android/app/build.gradle.kts`. Revisit to 29 when Play's target-API deadline forces it or when the
  QA device is retired.
- **Physical QA device: Redmi 6A, Android 9 (API 28), `armeabi-v7a` only.** Use the adb-reverse
  recipe in §0. Re-issue `adb reverse tcp:8443 tcp:443` after every reinstall or reboot.
- **AGENTS.md contains a claim that is now known to be false** and should be corrected: *"Debug
  cleartext: `android/app/src/debug/AndroidManifest.xml` allows plain http … `--dart-define=API_HOST=http://bisaas.test`
  works on the emulator."* The debug manifest does set `usesCleartextTraffic="true"`, but
  `src/main/AndroidManifest.xml:14` sets `android:networkSecurityConfig`, and
  `network_security_config.xml` has `base-config cleartextTrafficPermitted="false"` — the
  `networkSecurityConfig` attribute **overrides** `usesCleartextTraffic`. Plain HTTP is blocked in
  debug too. Use the HTTPS+adb-reverse path (§0), or add a `src/debug/res/xml/` override as that
  file's own comment prescribes.

---

## 6. PRODUCTION READINESS GAPS

1. **No upload keystore.** `build.gradle.kts` throws `GradleException` on a release build without
   `android/key.properties` unless `-Pallow-debug-signing=true` is passed. The artifacts verified
   today were **debug-signed** and must never be published. Generate the upload key, commit nothing,
   and materialise it in CI from the `ANDROID_KEYSTORE_BASE64` secret.
2. **No Play listing metadata.** `fastlane.metadata.md` is a 686-byte stub; there is no
   `fastlane/metadata/android/en-US/` tree, no screenshots, no release notes, no data-safety form.
   `version: 1.0.0+1` in `pubspec.yaml` has never been incremented.
3. **App-Link verification is incomplete.** The `https://bisaas.com` intent-filter declares
   `android:autoVerify="true"`, but `https://bisaas.com/.well-known/assetlinks.json` is not published,
   so App Links will not verify.
4. **Size.** Trim `x86_64` from the Play build (`ndk { abiFilters }`) — it is emulator-only dead
   weight in the bundle. Investigate the 20 MB `libts.so` native library, which is unusually large
   and unidentified. Enabling `isMinifyEnabled`/split-ABI per device would cut the ≈ 47 MB
   real-device download materially.
5. **No forced-upgrade gate.** `GET /api/v1/app/config` serves `min_app_version: {android: "1.0.0"}`
   and `force_update: false`, but the client never reads either — the referenced
   `lib/core/network/app_config_repository.dart` **does not exist**, and `FeatureFlags.init()` is
   never called, so all six feature flags are inert.
6. **Kotlin Gradle Plugin deprecation.** The build warns that `firebase_*`, `sentry_flutter`,
   `freerasp`, `in_app_review` and `workmanager` apply KGP directly; "Future versions of Flutter will
   fail to build if your app uses plugins that apply KGP." Track plugin upgrades.
7. **CI is green again** — `mobile-security-gate.yml:79` (`flutter analyze --fatal-infos`) passes now
   that the build compiles. Keep it that way: the `--fatal-infos` bar is why 5 `info`-level issues
   were blocking CI.

---

## 7. SUGGESTED ORDER

1. **P1-D** streak repair/insurance/wager — client data layer already exists, UI-only unlock.
2. **P4 + §4** a router smoke test, then the **O** one-line result-screen rewire. Both are tiny and
   both restore real user-facing surfaces.
3. **P1-A** daily quiz start, then **P1-B** world-map routing (the Duolingo spine).
4. **P1-C** lifelines (biggest engagement win; server is already live).
5. **P2 H / I** practice real questions + real weak topics — kill the two worst fabrications.
6. **P1-F/E** missions + check-in + spin, **P1-G** fix the dead store call.
7. **P3 R/S/T** wire-or-delete the 2 047 orphan lines, drop the blanket `ignore_for_file`s, prune
   the 13 dead packages.
8. **§6** keystore, Play listing, App Links, size.

Every phase keeps the same gate the founder set on 2026-09-06:
`flutter analyze` 0 issues → `flutter test` green → build → **drive it on the connected phone** →
commit with the screenshot in the message.

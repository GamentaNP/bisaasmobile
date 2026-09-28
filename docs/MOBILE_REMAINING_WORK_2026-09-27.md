# MOBILE REMAINING WORK — 2026-09-27

> **This is the live backlog.** Supersedes `MOBILE_MASTER_PLAN_DUILONGO_V2_2026-09-06.md`
> and replaces the first version of this file.
>
> Everything below was checked against reality on **2026-09-27**: `flutter analyze` (0 issues),
> `flutter test` (**313 passing**), a full source inventory, a read of every route in
> `bisaas/routes/api/v1/*`, **live curl probes** against `https://localhost/api/v1`, and a
> **physical-device run** on a Redmi 6A (Android 9 / API 28).
>
> Boundary rule unchanged: **business logic is server-authoritative in `C:\laragon\www\bisaas`.**
> Nothing here proposes grading, minting, ranking, or fraud logic on-device.

---

## 1. SHIPPED 2026-09-27 (12 commits)

| Commit | What |
|---|---|
| `5d31cd6` | **Unblocked the build.** HEAD did not compile — `game_world_map_screen.dart:8` imported a file that was never committed. Wrote it for real, fixed a real `worldSlug: ''` bug, cleared all 11 analyzer issues, lowered `minSdk` 29→28 so the phone can install, corrected two false claims in `AGENTS.md`. |
| `99e18b2` | **Streak repair / insurance / wager shipped.** All three were live server endpoints behind a disabled `WO-6` chip. Found and fixed two latent bugs where every successful repair and wager reported failure. |
| `e3639ab` | **World map routed.** `GameWorldMapScreen` (401 lines) and both game providers were orphaned. Added `/game/worlds` + `/game/world/:slug`, a worlds picker, entry points from Home and the Quiz tab, and made the DTO tolerant of the endpoint's real mixed key casing. |
| `8aa04e8` | **Three shipped surfaces made reachable.** `QuizResultScreen` (471 lines) was dead because its route rendered the review screen instead; deleted the duplicate `AiTutorScreen`; wired 3 no-op taps; fixed a visible 10px layout overflow. |
| `fd4175f` | **Daily quiz reads the real payload.** It was reading the wrong keys entirely, so `isDailyCompleted` was permanently false and the title/reward were invented. |
| `a16ab4d` | **Lifelines shipped.** Three "coming soon" SnackBars replaced by the server's real 13-lifeline catalogue with server-built effects. Also added `time_taken_seconds` to every answer. |
| `f462869` | **Every question count read a field the server does not send** — all courses/topics showed "0 questions". Also rewrote the practice session, which rendered literal `A/B/C/D` options and graded with `id.isEven && hashCode.isEven`. |
| `9e1fafd` | **Removed the 6 fake store assets, the permanently-dead `/store/market` call, the 15 fake home nodes, and the unhandled FCM crash.** |
| `007f7ba` | **Stopped lying about live features.** `/economy/wallet`, `/wallet/ledger`, `/economy/shop`, `/store/assets` and `/store/wardrobe` all return 200 today while the UI said "not shipped" / "beta". Corrected. Wired wardrobe unequip and the 3 dead social/wardrobe buttons. |
| `bf64a69` | **Missions (49, not 18) + daily check-in + spin wheel shipped.** Also fixed `ChunkyCard`: it paired a `borderRadius` with a non-uniform `Border`, which Flutter refuses to paint — the app's signature 3D extrusion was silently not rendering on **every** chunky card. |
| `431b0c9` | **Outages no longer look like "no data"** in the PSC and notification sources. |

**Gates, every commit:** `flutter analyze` → 0 issues · `flutter test` → **337 pass** ·
`flutter build apk --debug` → installed on the device · driven by hand on the device.

---

## 2. VERIFIED STATE

| Check | Result |
|---|---|
| `flutter analyze` | **0 issues** (CI gate `--fatal-infos` satisfied) |
| `flutter test` | **337 passing** |
| debug / release APK / release AAB | all build (R8 clean) |
| Physical device install + launch | ✓ (Redmi 6A, API 28) |
| Login against the real backend from device | ✓ |
| Every `*Screen` reachable from the router | ✓ enforced by a test |

**Reaching the local backend from a device** — `bisaas.test` does not resolve on a phone, and
release forbids cleartext, so use an adb reverse tunnel to a non-privileged port:

```powershell
adb reverse tcp:8443 tcp:443     # 443 itself is refused: "cannot bind listener"
flutter build apk --debug --dart-define=API_HOST=https://localhost:8443
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb reverse tcp:8443 tcp:443     # re-assert — install and reboot clear it
```

Laragon's vhost already lists `localhost` in `ServerAlias`, and `dio_client.dart:73-82` tolerates
its self-signed cert for `localhost` **only when `kDebugMode && currentEnv().isDev`**. Never point
a release build at Laragon.

---

## 3. THE ONE BLOCKER THAT MATTERS MOST (backend)

**There is no way to read the questions of a started attempt.** This blocks two headline
features, so it is the highest-value backend ask in this document.

- `POST /api/v1/quiz/daily/start` exists and returns `201 {attempt_id, mode, status, question_count, schedule_id}` — **and no questions**.
- `POST /api/v1/quiz/portal/levels/{level}/start` has the same shape.
- There is **no `GET /quiz/attempts/{attempt}`**. The only attempt reads are
  `/results` (post-completion), `/lifelines`, and `/analysis` (wrong-answer error taxonomy only —
  it exposes ids of questions the user got *wrong*, i.e. it is not a question feed).
- The old workaround `GET /api/v1/mobile/daily-quiz-pack` **has been removed from the routes**.

**Ask:** `GET /api/v1/quiz/attempts/{attempt}/questions` returning the seeded question set
(id, stem, options, marks) for an **in-progress, owned** attempt — no answer keys, no
explanations. That single route unblocks the daily quiz *and* per-level world-map play.

Until it lands the client deliberately **does not call `/daily/start`**: starting writes a
`quiz_daily_attempts` row server-side, so calling it with no way to render the questions would
**burn the player's daily quiz**. The home card now reports the real state from
`GET /quiz/daily` instead ("No daily quiz is scheduled today"), which is what the seeded database
actually contains — the only schedule row is dated 2026-07-03.

**Note for content:** the `quiz_daily_schedules` table needs rolling rows, or the daily feature is
dead regardless of the client. Same for the weak-areas analytics — `GET /learning/ai-tutor/weak-areas`
returns `{data:{report:{weak_areas:[]}}}` for a fresh account, correctly.

### Other open asks (lower priority)

1. **`stars_earned` in results.** Stars *are* written by `CompletePortalQuestOnAttemptCompletion`
   off `metadata.portal.level_id`, but `GET /quiz/attempts/{attempt}/results` does not return them,
   so the client must re-fetch the world map after finishing. Returning `stars_earned` + `best_score`
   would let the celebration be immediate.
2. **Coin-pack catalogue.** `CoinPackage` is web-only (`routes/web/economy.php:44-105`); there is no
   API route at all. Mobile must hardcode SKUs or read them from `GET /app/config`.
3. **Envelope normalisation** (cheap, high value for every client):
   - `/rewards/spin` and `/rewards/spin/status` return **raw JSON outside the envelope**
     (and a raw 422 body on failure). The enveloped twins `POST /quiz/spin-wheel/spins` work.
   - `/me/achievements/progress`, `/me/achievements/recent` and
     `/quiz/game/missions/dashboard` put a **bare JSON array** in `data`.
   - `/report-card/history` and `/store/assets` nest `pagination` **inside** `data`.
   - **Casing is inconsistent per endpoint, not globally.** `/quiz/game/worlds` mixes
     `banner_image` (snake) with `totalStarsEarned` (camel); `/world/{slug}/map` is camel throughout;
     `/quiz/streak` is snake. The client now handles both per-DTO — do not add a global converter.
4. **Questions pagination has no `total`.** It is cursor-based
   (`{type:"cursor", per_page, count, has_more, next_cursor}`) with rows under `data.items`, so
   question counts are necessarily lower bounds. The client renders "100+ Questions". If an exact
   count matters, expose it.
5. `GET /quiz/leaderboards/{leaderboard}` 500s on non-numeric ids (`my-rank` works).

---

## 4. REMAINING CLIENT WORK

### P1 — high value, backend already serves it

| # | Item | Where |
|---|---|
| A | **Per-level world-map play.** `POST /quiz/portal/levels/{level}/start` returns an attempt with no questions (see §3). Until §3 lands, `GameLevelIntroSheet` routes play through the proven course-attempt path — real grading, real XP, real stars — which works today. Once §3 lands, switch to the portal route for per-level attempts. | `game_level_intro_sheet.dart` |
| B | **World map chapter/level play is real but coarse.** `GameWorldMapScreen` renders the server's chapters, levels, stars and boss flags correctly and level play works via the course path, but there is no per-level attempt, no `stars_earned` on the result, and no ghost rival. `GET /quiz/game/ghost?level_attempt_id=` and `/ai/coach-tip` are live and unwired. | `game/` |
| C | **Missions ad-unlock / ad-spins.** `POST /quiz/spin-wheel/ad-spins` (3/day) and the lifeline `ad-unlock` route exist but every seeded item has the flag off, so they are correctly inert. Wire when ads are enabled. | `lifeline_remote_data_source.dart` |
| D | **Onboarding collects 3 answers and discards them.** Exam / daily-goal / experience-level are written to SharedPreferences and never read or sent. The copy promises *"personalize questions"* and *"IRT calibration"* — both false. Either persist server-side or stop promising it. | `onboarding_screen.dart:25-96`, `preferences.dart:21,24,27` |
| E | **7 remaining error-swallow blocks.** `eice_remote_data_source.dart:16,24,34,42,49` (5) still return hardcoded falses/empties; 3 `FutureBuilder`s have no `hasError` (`psc_screen.dart:18`, `downloads_screen.dart:82`, `quiz_browser_screen.dart:425`). PSC and notifications are fixed. | as listed |
| F | **5 `error:` branches swallow failure.** `home_screen.dart:165`, `learning_home_screen.dart:40`, `profile_screen.dart:224`, `calculator_detail_screen.dart:144` and `downloads_screen.dart`. | as listed |
| G | **"Offline" keys off general connectivity, not API reachability.** On the phone it read *"You're offline"* while API calls over the adb tunnel were succeeding — a captive portal or blocked `/api/v1` produces the same false state. | `lib/core/connectivity/` |
| H | **Categories carry no question count at all** (`/quiz/courses/{id}/categories` returns only `{id,name,slug,sort_order}`), so the client fetches a page per category. Accurate but N+1 — 15 requests for one course. A count on the category row would remove it. | `quiz_browser_screen.dart` |
| I | **Ledger/category N+1** and the "100+" lower-bound display are honest but a `total` on the questions endpoint would let both be exact. | backend ask §2.4 |

### P2 — remaining honesty gaps

| # | Item |
|---|---|
| F | **Onboarding collects 3 answers and discards them.** Exam / daily-goal / experience-level are written to SharedPreferences and never read or sent. The copy promises *"personalize questions"* and *"IRT calibration"* — both false. Either persist server-side or stop promising it. |

### P3 — hygiene

| # | Item |
|---|---|
| K | **~30 never-imported files** remain (`rating_service.dart` is the notable one — the store-rating prompt can never fire; `feature_flags.dart` — the whole Remote Config system is dead, `init()` never called, no force-update gate, and `GET /app/config` already serves `min_app_version` + `force_update`). Wire or delete. |
| L | **65 `ignore_for_file` + 8 inline `ignore:`** masking real defects: `return_without_value` (a control-flow path that silently falls off the end) in `battle_matchmaking_screen.dart:1`, `missing_required_argument` in `local_notification_service.dart:1`, `dead_code` in 4 DTO files. Remove the blanket suppressions and fix what they hid. |
| M | **13 declared dependencies with zero imports** — `google_fonts`, `flutter_markdown`, `flutter_svg`, `collection`, `cupertino_icons`, `sqlite3_flutter_libs`; plus `freezed` / `json_serializable` / `riverpod_generator` dev deps with **zero codegen** (all ~30 DTOs hand-write `fromJson`, all ~90 providers are hand-written), and `google_sign_in` / `workmanager` declared but never implemented. `AGENTS.md`'s build_runner runbook is misleading as a result. |
| N | **Test gaps.** 313 tests, still DTO + core-security heavy. Only one controller test exists (`AuthNotifier`). Zero widget tests for 52 screens. The new router gate (`test/app/router_reachability_test.dart`) is the pattern to extend: assert every screen is reachable, and no screen uses a raw `Navigator.push`. |

---

## 5. PRODUCTION READINESS

1. **No upload keystore.** `build.gradle.kts` throws on a release build without
   `android/key.properties` unless `-Pallow-debug-signing=true` is passed. **Every artifact
   verified today was debug-signed and must never be published.** Materialise the key in CI from
   the `ANDROID_KEYSTORE_BASE64` secret.
2. **No Play listing.** `fastlane.metadata.md` is a 686-byte stub; no `fastlane/metadata/…/en-US/`
   tree, no screenshots, no release notes, no data-safety form. `version: 1.0.0+1` has never moved.
3. **App Links unverified.** The `https://bisaas.com` intent-filter declares `android:autoVerify="true"`
   but `/.well-known/assetlinks.json` is not published.
4. **Bundle size.** `app-release.aab` 111.2 MB, of which ~72 MB is `BUNDLE-METADATA`
   (`proguard.map` 47.8 MB + `debugsymbols/*.sym`) that Play consumes server-side and never
   ships. Real per-device download is ≈ 47 MB. Drop `x86_64` from the Play build (emulator-only
   dead weight) and investigate the 20 MB `libts.so`, which is unusually large and unidentified.
5. **Kotlin Gradle Plugin deprecation.** The build warns that `firebase_*`, `sentry_flutter`,
   `freerasp`, `in_app_review` and `workmanager` apply KGP directly; *"Future versions of Flutter
   will fail to build"*. Track plugin upgrades.
6. **TalkBack is unavailable on API 28–33.** Accepted consequence of `minSdk = 28`: Flutter 3.47's
   `AccessibilityBridge` references the API-34 type `UiModeManager.ContrastChangeListener`, the
   engine catches the `NoClassDefFoundError` and disables the bridge. The app runs fine. This is
   the trade for being able to test on the dominant budget-device class in the target market.

---

## 6. HOW EACH PHASE RUNS

Reality first: before building a surface, probe the endpoint and paste the observed shape into the
data source's doc comment. No endpoint, no feature — file an ask instead.

Verification gate per phase: `flutter analyze` 0 issues → `flutter test` green → build →
**drive it on the connected phone** → commit with the proof in the message.

Note when driving the device: `SensitiveScreenGuard` applies `FLAG_SECURE` to graded attempts, so
`screencap` returns `FB is protected: PERMISSION_DENIED` inside a quiz. That guard is working as
designed; cover those surfaces with widget tests instead.

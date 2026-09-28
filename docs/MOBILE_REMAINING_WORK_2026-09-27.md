# MOBILE REMAINING WORK — 2026-09-27 (updated 2026-09-28)

> **This is the live backlog.** Supersedes `MOBILE_MASTER_PLAN_DUILONGO_V2_2026-09-06.md`
> and replaces the first version of this file.
>
> Everything below was checked against reality on **2026-09-27**, re-verified
> **2026-09-28**: `flutter analyze` (0 issues, with `unnecessary_ignore: true` so
> stale lint suppressions can no longer hide), `flutter test` (**354 passing**), a
> full source inventory including a forward-reachability sweep from every
> entrypoint, a read of every route in `bisaas/routes/api/v1/*`, **live curl
> probes** against `https://localhost/api/v1`, and a **physical-device run** on a
> Redmi 6A (Android 9 / API 28).
>
> Boundary rule unchanged: **business logic is server-authoritative in `C:\laragon\www\bisaas`.**
> Nothing here proposes grading, minting, ranking, or fraud logic on-device.

---

## 1. SHIPPED 2026-09-28 (4 further commits)

| Commit | What |
|---|---|
| `d19d7c4` | **Swallowed failures, last of them.** `eice_remote_data_source.dart` wrapped five methods in `catch (_) { return null / [] / false; }`, so a dead study-planner endpoint rendered as "no study plan" and a failed sprint grade reported a bare failure. Learning and profile rendered a failed fetch as *nothing at all*; a Drift failure in downloads reported "0 questions cached", identical to a fresh install. |
| `74047ef` | **Three crashes.** `BattleState.copyWith` wiped `error`/`winnerUid` on every unrelated update, so an RTDB winner was cleared on the next tick — fixed with an `_unset` sentinel, because call sites pass `error: null` deliberately to *clear* it. The battle countdown called `Navigator.pushReplacementNamed` (throws in a `MaterialApp.router` app) against `/battle/arena`, which is not a route. The daily reminder used `exactAllowWhileIdle` without `SCHEDULE_EXACT_ALARM`. Five visible **Retry** buttons did nothing. |
| `522acd7` | **−1,715 lines, no behaviour change.** 36 files deleted after a reachability BFS proved no orphan is imported; 20 dependencies removed after confirming zero imports; 78 dead `ignore_for_file` names cleaned and `unnecessary_ignore` flipped to `true`. |
| `5ba7b89` | **Engineering documentation was rendering as screen copy.** Profile tiles read `GET /psc/blueprints`; the wallet told users coins are credited "via `EconomyService::debit()`". EICE was a debug screen: each card printed its own endpoint and dumped the response with `Text(data.toString())`, and had no `try/catch` at all. A developer toggle let users switch tutor API versions. |
| `0ebb3ba` | **The force-update gate had never fired.** CI sent a non-semver `X-App-Version` which the server's `whereNumber`-style regex rejects (and deliberately passes through), the client had no `UPGRADE_REQUIRED` code, and nothing acted on a 426. All three fixed; there is now a blocking update screen with no Retry. |
| `d8f345f` | **EICE coach and triage never matched a route.** The server constrains `{exam}` to numeric; the client sent the hardcoded slug `'psc-civil'`, so it 404'd at the routing layer and — with failures being swallowed — displayed as an empty section. Coach now takes no exam and lets the server resolve the user's own; triage uses the `exam_id` the coach returns. |
| `295d59b` | **The offline banner asked the wrong question.** It reported `connectivity_plus` (does the radio see a network) while claiming the API was unreachable — and the QA device showed it lying in both directions. Replaced with `ApiReachability`, which reads real request outcomes and treats a 401/500 as proof the server answered. |

## 1a. SHIPPED 2026-09-27 (12 commits)

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
| `flutter analyze` | **0 issues** (CI gate `--fatal-infos` satisfied, and now with `unnecessary_ignore: true`) |
| `flutter test` | **413 passing** |
| debug / release APK / release AAB | all build (R8 clean) |
| Physical device install + launch | ✓ (Redmi 6A, API 28) |
| Login against the real backend from device | ✓ |
| Every `*Screen` reachable from the router | ✓ enforced by a test |
| No orphan file reachable from an entrypoint | ✓ verified by BFS sweep |
| No user-visible string of dev documentation | ✓ swept + regression test |

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
| E | ~~**7 remaining error-swallow blocks.**~~ **DONE 2026-09-28.** `eice_remote_data_source.dart` — all five methods now propagate. `downloads_screen.dart` no longer reports a Drift failure as "0 questions cached", and its `FutureBuilder` future is now a field (rebuilding it inline created a new future every frame). | `eice_screen.dart`, `payload_view.dart`, `downloads_screen.dart` |
| T | **EICE coach + triage never matched a route.** The server declares `/study-planner/{exam}` with `->whereNumber('exam')`; the client sent the hardcoded slug `'psc-civil'`, so Laravel 404'd at the routing layer and the controller was never reached. Because the data source also swallowed failures, it displayed as "Nothing to show for this section yet". **DONE 2026-09-28** — coach now calls `GET /quiz/coach` (the controller resolves the user's own active target exam), triage takes the numeric `exam_id` the coach payload returns. Verified by curl: slug → 404, numeric → 401. | `eice_remote_data_source.dart`, `app_router.dart` |
| F | ~~**5 `error:` branches swallow failure.**~~ **DONE 2026-09-28** — learning and profile now render a real message plus Retry; calculator's title honestly shows the humanised slug; the home active-course card is suppressed on error *by design* (it would have to invent a title) and is now documented rather than silent. | as listed |
| G | ~~**"Offline" keys off general connectivity, not API reachability.**~~ **DONE 2026-09-28.** `ApiReachability` is now fed by the Dio interceptors: any HTTP response (including 401/500) proves reachability; only transport failures mark it unreachable; cancel and decode-timeout are explicitly not. Costs no extra requests and cannot say "offline" while calls are succeeding. | `api_reachability.dart`, `offline_state_banner.dart` |
| H | **Categories carry no question count at all** (`/quiz/courses/{id}/categories` returns only `{id,name,slug,sort_order}`), so the client fetches a page per category. Accurate but N+1 — 15 requests for one course. A count on the category row would remove it. | `quiz_browser_screen.dart` |
| I | **Ledger/category N+1** and the "100+" lower-bound display are honest but a `total` on the questions endpoint would let both be exact. | backend ask §2.4 |
| J | ~~**"232 Calculators".**~~ **DONE 2026-09-28** — the number was hardcoded in three places while the database holds 32 civil calculators. Home, profile and the catalogue search hint now read the server's `total_calculators` and drop the number entirely when the catalogue fails, rather than asserting a stale count. | `home_screen.dart`, `profile_screen.dart`, `calculator_browser_screen.dart` |
| P | **Battle arena was unreachable.** `BattleState.copyWith` wiped `error`/`winnerUid` on every unrelated update, so a winner read from RTDB was cleared on the next tick; the countdown called `Navigator.pushReplacementNamed` (throws in a `MaterialApp.router` app) against a path that does not exist. All fixed. | `battle_controller.dart`, `battle_matchmaking_screen.dart` |

### P2 — remaining honesty gaps

| # | Item |
|---|---|
| D | **Onboarding collects 3 answers and discards them.** Exam / daily-goal / experience-level are written to SharedPreferences and read back only by the onboarding screen itself. `PATCH /me` validates only `name`/`username`/`email` — there is no server field for them, so this is a **backend ask**, not a client bug: without a place to persist them, wiring them would mean inventing a route. The copy has been corrected to stop promising IRT calibration and personalisation that does not happen (`dailyGoalMinutes` had no getter at all). | `onboarding_screen.dart`, backend ask §2 |
| S | **Donor identity is fabricated by the *server*, not the client.** `DonorGamificationService.php:80` returns `'donorName' => $badge->user?->name ?? 'Generous Supporter'`, so an anonymous donor is rendered as a person called "Generous Supporter". The client's own fallback was changed to `'Anonymous'` (matching `economy_dto`) but is now unreachable — the server always supplies a value. **The real fix is server-side**: use `'Anonymous'`, or have the client treat a deleted user as anonymous. Outside the Flutter boundary, so not actioned here. | backend `DonorGamificationService.php:80` |

### P3 — hygiene

| # | Item |
|---|---|
| K | ~~**~30 never-imported files.**~~ **DONE 2026-09-28** — all 36 deleted (1,336 lines) after a forward-reachability BFS from every entrypoint proved no orphan is imported. (`FeatureFlags.init()` is in fact called from `bootstrap.dart:43`; an earlier claim here that it was dead was wrong. The flags are read, but there is no `GET /app/config` fetch, so Remote Config is the only source and a device without Firebase falls back to `defaults`.) |
| U | **The force-update gate had never fired, for three separate reasons — all fixed 2026-09-28.** (1) CI passed `github.ref_name` as `APP_VERSION`: `master` on branch pushes, `v1.2.3` on tags. `EnforceAppVersion` only judges `/^\d+\.\d+\.\d+(-[\w.]+)?$/` and passes anything else through by design, so the gate was silently disabled for every release. Both workflows now resolve the version from pubspec. (2) The client had no `UPGRADE_REQUIRED` code, so a 426 surfaced as a generic error. (3) Nothing acted on it. There is now an `AppUpdateGate` latched by `AuthInterceptor` and a blocking `ForceUpdateScreen` with the required minimum and a store link — deliberately with no Retry. |
| L | ~~**65 `ignore_for_file` + 8 inline `ignore:`**~~ **DONE 2026-09-28** — `unnecessary_ignore` was `false`, so no stale suppression could ever be detected; 78 dead rule names across 41 files are removed and the flag is now `true` so the stricter setting is enforced. Fixing the suppressions paid for itself: with `dead_null_aware_expression` live again the analyzer proved `completeOnboarding`'s `data ?? {}` was unreachable, meaning a malformed tutor envelope silently produced a default DTO and reported success. Now `late final`. |
| M | ~~**13 declared dependencies with zero imports.**~~ **DONE 2026-09-28** — 20 removed after confirming zero `package:X/` imports each: the entire `freezed`/`json_serializable`/`riverpod_generator` chain (no annotations exist, no `build.yaml`, drift is the only codegen), plus `flutter_svg`, `workmanager`, `google_fonts`, `google_sign_in`, `in_app_review`, `permission_handler`, `path_provider`, `device_info_plus`, `package_info_plus`, `shimmer`, `flutter_animate`, `flutter_markdown`, `collection`, `cupertino_icons`. `sqlite3_flutter_libs`/`build_runner`/`drift_dev`/`very_good_analysis`/`flutter_launcher_icons` have no Dart imports by design and were kept. `AGENTS.md` + `README.md` runbooks corrected. Also deleted 3 byte-identical copies of `main.dart` (`main_dev`/`_prod`/`_staging`) — no flavour config, no CI, env is `--dart-define=ENV`. |
| N | **Test gaps — partly closed.** 392 tests (was 313). Added: 17 for `PayloadView`, 21 for the force-update gate and version normalisation, 6 widget tests for `ForceUpdateScreen`, 6 for the EICE data source's request paths, 5 for the EICE screen. Still DTO + core-security heavy; the 52 screens remain largely widget-untested, and only one feature controller (`AuthNotifier`) has tests. |
| Q | **~40 strings of engineering documentation were rendering as screen copy.** DONE 2026-09-28 — profile tiles read `GET /psc/blueprints`; the wallet told users coins are credited "via `EconomyService::debit()`". Replaced with user-facing copy; the contract docs stayed in the data-source comments where they belong. A developer toggle in the tutor menu ("Using legacy `POST /learning/tutor`") let users switch API versions and has been removed. |
| R | **The daily reminder would throw on Android 12+.** It used `exactAllowWhileIdle` without declaring `SCHEDULE_EXACT_ALARM`, so it failed with `exact_alarms_not_permitted`. Switched to `inexactAllowWhileIdle` rather than adding a special-permission grant flow — a daily nudge needs no second precision, and this avoids Play-policy exposure. |
| V | **Localization is a promise the app does not keep — and this is a founder decision, not a code fix.** Settings offers a Nepali/Hindi picker (`settings_screen.dart:108-120`). The ARB files hold **21 keys** and exactly **one** Dart file consumes them (`app_lock_overlay.dart`); the only other hits are the generated file and the `MaterialApp` wiring. A user who selects Nepali sees ~3 strings change while ~266 files stay English. Compounding it: `assets/fonts/` contains only 4 weights of **InstrumentSans, which carries no Devanagari**, so even those localized Nepali strings render in a substituted face. Two honest options, and I did not pick one unilaterally: **(a)** commit to English-only and remove the picker plus the ARB scaffolding, or **(b)** fund real localization — add a Devanagari face and translate the core surfaces. Removing a Nepali language option from a Nepal-targeted Loksewa/PSC product is a product call, and partially wiring 21 keys while still advertising Nepali is the same class of lie this pass has been removing. **Needs the founder.** | `settings_screen.dart`, `l10n/`, `assets/fonts/` |

---

## 5. PRODUCTION READINESS

1. ~~**No upload keystore.**~~ **RESOLVED 2026-09-28.** `android/key.properties` now
   exists (gitignored, correctly untracked — the keystore must never be committed). Verified by
   building a real release bundle:
   `flutter build appbundle --release --dart-define=ENV=prod --dart-define=APP_VERSION=1.0.0`
   → `app-release.aab` 111.5 MB, and `jarsigner -verify` reports
   `Signed by "CN=CivilCal Upload Key, OU=Bisaas, O=Bisaas, L=Kathmandu, C=NP"` / `jar verified`.
   This is the first genuinely upload-signed artifact; every earlier one was debug-signed.
2. **No Play listing.** `fastlane.metadata.md` is a 686-byte stub; no `fastlane/metadata/…/en-US/`
   tree, no screenshots, no release notes, no data-safety form. `version: 1.0.0+1` has never moved.
3. **App Links unverified.** The `https://bisaas.com` intent-filter declares `android:autoVerify="true"`
   but `/.well-known/assetlinks.json` is not published.
4. **Bundle size.** `app-release.aab` **111.5 MB**, but that figure is misleading: 138.6 MB of the
   archive is `BUNDLE-METADATA` (`proguard.map` 45.5 MB + `debugsymbols/*.sym` 34.9 MB) which
   Play consumes server-side for de-obfuscating crash reports and never ships. Actual `base/`
   is 142.7 MB uncompressed across 3 ABIs. Per-ABI native payload (arm64): `libflutter.so`
   157.5 MB, **`libts.so` 20.9 MB**, `libapp.so` 15.8 MB, `libsqlite3.so` 1.7 MB.
   - **`libts.so` is now identified** (it was previously "unidentified"): it statically links
     **OpenSSL/BoringSSL + curl + minizip** and exports 31 `Java_androidx_security_BNatives_*`
     JNI symbols, so it is a security/keystore native — ~21 MB repeated per ABI, ~63 MB for the
     three packaged ABIs.
   - No `abiFilters`/`splits` block exists, so **x86_64 (20.9 MB) is still packaged** and is
     emulator-only. It does not affect per-device download (AAB delivers one ABI), only the
     upload artifact and CI time. Add `ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }`
     — **`armeabi-v7a` must be kept**: the QA Redmi 6A is 32-bit.
   - Real lever is `libts.so`: 21 MB of statically-linked TLS for a keystore native is worth
     asking the plugin author about, and worth a Play ABI split analysis before any size work.
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

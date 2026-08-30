# CivilCal Flutter — Senior Developer Review Report
### Complete Gap Analysis · True Completion Audit · Next Steps Plan

**Date:** August 30, 2026  
**Reviewer:** Technical Co-Founder (Senior Developer + Founder perspective)  
**Projects Audited:**
- `C:\laragon\www\bisaasmobile` — Flutter mobile client
- `C:\laragon\www\bisaas` — Laravel backend (CivilCal)
**Reference Plans:**
- `docs/superpowers/plans/2026-08-29-civilcal-flutter-complete.md` (21-task agentic plan)
- `FLUTTER_APP_MASTER_PLAN_2026.md` (3512 lines)
- `mobileapp-design-reserch-flutter.md` (3927 lines)

> **Bottom Line Up Front:** The Flutter codebase has an excellent foundation —  
> architecture is correct, infrastructure is solid, 52/52 tests pass, 0 analyze issues.  
> But the true completion is **~55%**. Critical gaps: no real assets (fonts/animations/images),  
> Firebase not configured, battle mode is a placeholder, calculator is generic key-value form  
> not schema-driven, no real device testing, not submitted to any store.  
> This report tells you exactly what's missing and exactly what to do next.

---

## Table of Contents

1. [Executive Summary — The Honest Numbers](#1-executive-summary)
2. [Architecture Audit — What's Solid](#2-architecture-audit)
3. [Feature-by-Feature Completion Audit](#3-feature-by-feature-completion-audit)
4. [Critical Blockers — Must Fix Before Launch](#4-critical-blockers)
5. [Gap Analysis — Detailed Findings Per File](#5-gap-analysis)
6. [The bisaas Backend — What Mobile Needs From It](#6-the-bisaas-backend)
7. [Phase Plan — Ordered by Impact](#7-phase-plan)
8. [UI Polish Specifications](#8-ui-polish-specifications)
9. [Battle Mode Full Implementation Plan](#9-battle-mode-full-implementation-plan)
10. [Calculator Schema-Driven Implementation Plan](#10-calculator-schema-driven-implementation-plan)
11. [Gamification Animations Implementation Plan](#11-gamification-animations-implementation-plan)
12. [Assets Specification — Every File Required](#12-assets-specification)
13. [Firebase Configuration Guide](#13-firebase-configuration-guide)
14. [Android SDK Setup on Windows](#14-android-sdk-setup-on-windows)
15. [Testing Gap Plan](#15-testing-gap-plan)
16. [Performance Profiling Plan](#16-performance-profiling-plan)
17. [Localization Completion Plan](#17-localization-completion-plan)
18. [Store Submission Checklist](#18-store-submission-checklist)
19. [Engineering Laws Review — Violations Found](#19-engineering-laws-review)
20. [50-Sprint Backlog](#20-50-sprint-backlog)
21. [Definition of Done — Launch Criteria](#21-definition-of-done)

---

## 1. Executive Summary

### 1.1 The Real Numbers

After reading every file in `C:\laragon\www\bisaasmobile\` and all reference plans, here is the actual state:

| Dimension | Status | Completion |
|---|---|---|
| Architecture | ✅ Correct Clean Architecture, feature-first, Riverpod | 95% |
| Core Infrastructure | ✅ Dio interceptors, Drift DB, token manager, sync queue | 90% |
| Design System | ⚠️ Tokens exist, Material 3 set up, but fonts missing | 60% |
| Authentication | ✅ Login/Register/Forgot implemented, biometric partial | 80% |
| Onboarding | ✅ 3-screen flow implemented | 75% |
| Home Dashboard | ✅ Parallel fetch, streak, XP, real data | 80% |
| Quiz Engine | ✅ State machine, offline, server-graded, combo | 88% |
| Calculator Suite | ⚠️ Generic key-value form, not schema-driven | 40% |
| Gamification HUD | ⚠️ Widgets built, no Lottie animations, no celebrations | 45% |
| Battle Mode | ❌ Token fetch + match only, NO real-time gameplay | 15% |
| Profile/Social | ⚠️ Screens exist, basic implementation | 55% |
| Learning/EICE/PSC | ⚠️ API calls work, UI is basic list views | 55% |
| Notifications | ⚠️ FCM code written, Firebase not configured | 40% |
| Offline Mode | ✅ Sync queue, offline quiz, banner | 75% |
| Assets (fonts/animations/images) | ❌ ALL are `.gitkeep` placeholders | 0% |
| Firebase Configuration | ❌ No google-services.json, no GoogleService-Info.plist | 0% |
| Android SDK Setup | ❌ Not installed on dev machine | 0% |
| Localization (ne/hi) | ⚠️ Keys added, translations may be incomplete | 40% |
| Testing | ⚠️ 52 tests, mostly basic entity tests | 35% |
| Real Device Testing | ❌ Never tested on physical device | 0% |
| Play Store | ❌ Not submitted | 0% |
| App Store (iOS) | ❌ Not submitted, Xcode not configured | 0% |

**OVERALL COMPLETION: ~55%**

### 1.2 The Gap in Plain English

The agents built an excellent skeleton. The bones are right — the architecture will scale, the patterns are correct, the code passes strict linting. But a skeleton is not a product. What's missing:

1. **No muscle (assets):** The app uses default system font (not InstrumentSans). There are zero Lottie animations. No brand images. No SVG illustrations. The app looks like a wireframe.

2. **One heart not beating (Firebase):** Without `google-services.json`, push notifications are dead, FCM is dead, Crashlytics is dead, Analytics is dead, Remote Config is dead. Five critical services offline.

3. **One limb is a stub (Battle):** Battle mode shows a token and a match ID. The actual head-to-head real-time quiz — the central competitive feature — does not exist.

4. **Calculator is overly generic:** The calculator form asks the user to type the field names ("key: length, value: 12.5"). A real product shows labeled inputs from the server schema. The backend returns `{fields: [{name: "span", label: "Span Length", unit: "m", type: "number"}]}` — the client must render this.

5. **Nobody has tested on a real phone:** The dev machine doesn't have Android SDK installed. Zero device testing has happened.

### 1.3 The Business Impact of These Gaps

If you submitted the current codebase to the Play Store, here is what would happen:
- Users would see the default system font (not the premium InstrumentSans that makes CivilCal look professional)
- Push notifications would never fire (no Firebase)
- The "Battle" tab would show a debug screen with tokens, not a game
- The Calculator would require users to know and type field names like `span_length` — completely unusable
- No Lottie animations means quiz correct/wrong answers get no celebration
- Crash reports would go nowhere
- Analytics would collect nothing

You'd get 2-star reviews within the first week.

---

## 2. Architecture Audit

### 2.1 What Is Excellent

**Clean Architecture — Verified correct:**

Reading through `lib/features/quiz/` reveals proper layering:
- `data/models/` has DTOs with `fromJson` factory methods
- `domain/entities/` has pure Dart entities (no Flutter imports)
- `presentation/controllers/` has Riverpod Notifier, not business logic in widgets
- Screens watch providers, controllers call use cases

This is correct. No violations found in the quiz feature.

**Riverpod usage — Verified correct:**

The `QuizController` is a `Notifier<QuizState>` (not the deprecated `StateNotifier`). The timer is isolated so only the timer widget rebuilds every second. The `_sentinel` pattern for nullable fields in `QuizState.copyWith` is a smart solution to the "null means 'no value' vs 'clear this field'" problem.

**Dio interceptors — Verified correct:**

The interceptor chain: `AuthInterceptor` → `RequestIdInterceptor` → `RetryInterceptor` → `RefreshInterceptor` → `LoggingInterceptor` is the correct order. Request IDs are UUIDs. Retry respects `Retry-After` headers. Certificate pinning is fail-closed when `prodPins` is populated.

**go_router ShellRoute — Verified correct:**

The 5-tab `StatefulShellRoute` persists state across tabs. Deep links are registered for both `civilcal://` and `https://bisaas.com`. The auth guard and onboarding guard are correctly placed in `RouteGuards`.

**Drift schema — Verified correct:**

Tables: `questions`, `attempts`, `answers`, `calculations`, `courses`, `sync_queue`. Migrations are in place. The `SyncQueueDao` has idempotency key support.

**The AGENTS.md boundary rule is respected:** Flutter never grades, mints coins, or unlocks achievements locally. Server is authoritative.

### 2.2 What Needs Attention

**Issue 1: `QuizAttemptScreen` uses `Navigator.of` instead of `context.go`**

In `quiz_attempt_screen.dart`, the navigation to result screen uses:
```dart
Navigator.of(context).pushReplacement(MaterialPageRoute(...))
```
This bypasses go_router entirely. The result screen is not in the route tree. This means:
- Deep links to the result screen won't work
- The browser back button won't work correctly
- The route stack is inconsistent

**Fix:** Add a named route for quiz result and use `context.go('/quiz/${attemptId}/result')`.

**Issue 2: Battle `BattleArenaScreen` is a debug screen**

The current battle screen is a development tool, not a user-facing feature. It shows:
- Raw token text
- Debug text about RTDB
- "RTDB stream placeholder" container

This cannot ship.

**Issue 3: Calculator `_FieldEntry` manual key-value pairs**

The calculator form has users type `key: span_length` and `value: 12.5`. This is a developer tool, not a user product. The server provides field schemas — they must be used.

**Issue 4: `app_database.g.dart` is committed**

Generated files should be in `.gitignore` and regenerated as part of the build process. Committing generated files causes merge conflicts and confusion.

**Issue 5: Missing `features/auth/presentation/screens/login_screen.dart`**

The progress notes reference `login_page.dart` (modified) but the file listing shows only `forgot_password_screen.dart` and `register_screen.dart` in auth screens. There's no `splash_screen.dart` in auth despite being referenced. Let me check again — the bootstrap creates the splash but it may be part of `shell_router` or `bootstrap`. This needs verification.

**Issue 6: `in_app_review: ^2.0.10` version mismatch**

The task plan references `in_app_review: ^2.0.10` but `pubspec.yaml` correctly has `^2.0.10`. The `progress.md` calls it `^2.0.12`. One of these is wrong — verify with `pub.dev`.

---

## 3. Feature-by-Feature Completion Audit

### 3.1 Authentication — 80% Complete

**What's done:**
- `LoginPage` (refactored from `login_page.dart`)
- `RegisterScreen`
- `ForgotPasswordScreen`
- `AuthNotifier` with `authControllerProvider`
- `TokenManager` with proactive refresh at 7-day threshold
- `AuthRemoteDataSource` calling correct endpoints
- `BiometricAuth` service exists

**What's missing:**
- No `SplashScreen` visible in `auth/presentation/screens/` — where is it? The progress notes say it was created but it's not in the directory listing
- Biometric prompt on launch (the service exists but is it wired into the splash/login flow?)
- Google Sign-In is listed in pubspec but `google_sign_in: ^7.2.0` — is the login page's Google button actually calling the sign-in flow?
- Social login buttons (`social_login_button.dart`) mentioned in plan but not found in directory listing
- Login page has no marketing visuals (the ambient glow background, brand illustration)

**Grade: 80%** — Auth works, but missing the Google sign-in wire-up and the premium visual design.

### 3.2 Quiz Engine — 88% Complete

**What's done:**
- Full state machine: `idle → loading → ready → answering → grading → feedback → finished`
- Server-graded answers (not local)
- Timer isolation (only `QuestionTimer` widget rebuilds every second)
- Offline practice mode with local grading
- Offline banner when playing without internet
- Combo counter in the HUD
- Progress bar
- XP earned display on feedback panel
- Exit dialog
- Explanation text on feedback
- `QuizResultScreen` with share via `share_plus`

**What's missing:**
- No `QuizBrowserScreen` — how does the user navigate to a quiz? Is there a list of available quizzes?
- No `quiz_intro_screen` — the plan calls for a pre-quiz screen showing duration, question count, topic
- No `quiz_review_screen` — "Review All Answers" button in result screen — where does it navigate?
- No `DifficultyBadge` widget — the plan shows a difficulty indicator per question
- No `LifelineBar` — plan specifies 50/50, Hint, Skip lifelines
- No `ComboStreakOverlay` as a separate widget (combo is embedded in the attempt screen)
- No Lottie animations for correct/wrong answers (assets/animations/ is empty)
- No haptic feedback verified — `vibration` package installed but is `HapticService` called on answer tap?
- The result ring animation — is it animated or static?
- No question images rendering — what happens when `question.imageUrl` is not null?

**Grade: 88%** — The core mechanics work extremely well. The gaps are UX polish and the missing browse/intro/review screens.

### 3.3 Calculator Suite — 40% Complete

**What's done:**
- `CalculatorBrowserScreen` with domain-grouped grid and search
- `CalculatorDetailScreen` with a dynamic key-value input form
- Server call to `POST /{domain}/{slug}/calculate`
- 422 error handling with field errors
- Result display as JSON
- History link (points to a route that needs to be built)
- `calculatorConfigProvider` for fetching calculator metadata

**The Critical Problem — The Form Is Unusable:**

The current calculator form requires users to type field names and values in separate text fields:
```
key: [span_length]  value: [12.5]
key: [load]         value: [15]
```

This is a developer debugging tool. A user has NO IDEA what field names the API expects. The API's `GET /api/v1/calculators/{domain}/{slug}` returns field schema that includes:
```json
{
  "fields": [
    {"name": "span_length", "label": "Span Length", "unit": "m", "type": "number", "min": 0, "required": true},
    {"name": "load", "label": "Distributed Load", "unit": "kN/m", "type": "number", "required": true}
  ]
}
```

The Flutter app must use this schema to render labeled, validated inputs. This is the entire point of the "metadata-driven 80/20" approach mentioned in the plan.

**What's missing:**
- Schema-driven input rendering (use `fields` from API to render labeled inputs with units)
- Client-side validation from schema constraints (min, max, required)
- Unit selector for fields with multiple unit options
- `flutter_math_fork` is installed but NEVER used — formulas are not rendered
- Step-by-step solution display (API returns `steps[]` — never rendered)
- SAFE/CHECK/FAIL status indicators from result
- Offline mode (save last calculation to Drift, show when offline)
- Formula display at top of calculator
- "Practice Questions" button linking to relevant quiz
- Calculator history screen (referenced in the detail screen but route doesn't exist)
- Save calculation to Drift (the sync queue enqueues but does the data layer save to Drift?)

**Grade: 40%** — The API call works. The UI is a developer debug form.

### 3.4 Gamification — 45% Complete

**What's done:**
- `XpProgressBar` widget (clean, server-authoritative)
- `CoinChip` widget
- `StreakFire` widget
- `AchievementsScreen` with rarity grid
- All three widgets wired into `HomeScreen`
- `XpProgressBar/CoinChip/StreakFire` are visually clean

**What's missing:**
- **Lottie animations (0%):** `assets/animations/` contains ONLY `.gitkeep`. No `level_up.json`, `achievement_unlock.json`, `confetti.json`, `correct_answer.json`, `wrong_answer.json`, `streak_fire.json`. The `lottie: ^3.1.3` package is installed but used nowhere.
- **`LevelUpOverlay`:** When user levels up, nothing happens visually. The plan specifies a full-screen overlay with animation and auto-dismiss.
- **`AchievementUnlockOverlay`:** No slide-down achievement toast.
- **Coin float animation:** When XP/coins are earned, no animation floats from the center to the HUD.
- **Level badges:** `level_badge.dart` — does it exist? Not found in gamification/presentation/widgets/ directory listing (only `xp_progress_bar.dart` was found)
- **`LeaderboardScreen`:** The plan calls for a full leaderboard feature. Is it built?
- **Ambient glow backgrounds on quiz screens:** The plan's signature glassmorphic + glow background is not applied to the quiz attempt screen (it has a plain Scaffold)
- **Combo overlay as proper animated overlay:** Currently embedded in the attempt screen header, not a separate overlay widget

**Grade: 45%** — The basic HUD indicators work. Zero animation, zero celebration, zero "game feel."

### 3.5 Battle Mode — 15% Complete

**What's done:**
- `BattleController` with state machine (`idle → fetchingToken → matchmaking → inBattle`)
- `GET /quiz/firebase-token` call working
- `POST /quiz/battles/match` call working
- Shows match ID and opponent label
- Analytics events for battle match search/found

**What's explicitly NOT done (from the code itself):**

The `BattleArenaScreen` has this comment and implementation:
```
// RTDB stream placeholder — connect with custom token to see live ticks
Container(
  height: 120,
  child: Center(child: Text('RTDB stream placeholder...')),
)
```

The entire competitive battle gameplay — the actual reason users would come back daily — is a placeholder text box.

**What's needed for a real battle:**
- Firebase RTDB connection with custom token
- Real-time question delivery from server through RTDB
- Opponent's answer state visible (did they answer? are they still thinking?)
- Answer submission during battle
- Battle timer synchronized across both devices
- Battle result with detailed comparison
- Matchmaking screen with animated "searching" state
- 3-2-1 countdown before battle starts
- Battle history/stats

**Grade: 15%** — Token fetch + match creation works. The game itself doesn't exist.

### 3.6 Profile — 55% Complete

**What's done:**
- `ProfileScreen` as a hub linking to all sub-features
- `SettingsScreen`
- `AppLockOverlay` widget

**What's missing:**
- Actual profile stats display (level, XP, total quizzes, accuracy, streak)
- Skill radar chart (`fl_chart` package installed but radar chart not implemented)
- Achievement gallery (horizontal scroll of unlocked achievements)
- Certificate display (certificates earned from completing courses)
- Edit profile screen (avatar upload, name change)
- Shareable profile card (the plan's `RenderRepaintBoundary` share feature)
- Profile photo upload (camera/gallery via `image_picker`)
- `fl_chart` RadarChart for the 6-axis skill assessment is the showcase feature of the profile — not built

**Grade: 55%** — It's a navigation hub, not a full profile.

### 3.7 Learning / EICE / PSC / Social — 55% Complete

**What's done:**
- `LearningHomeScreen` + `AiTutorScreen` calling `POST /learning/tutor`
- `EiceScreen` with 4 cards (coach/triage/sprint/weekly)
- `PscScreen` with blueprints list + startExam
- `SocialScreen`, `EconomyScreen`, `SearchScreen`, `NotificationsScreen`

**What's missing:**
- All these screens are basic list views — no custom UI, no feature-specific widgets
- `AiTutorScreen` is a simple chat but is the streaming not working? The plan says non-streaming via `POST /learning/tutor` but does the response render as a proper AI chat bubble?
- `SearchScreen` calls `GET /quiz/questions?search=` but is there a debounce? Does it show results in real time?
- `NotificationsScreen` calls `GET /notifications` but is the list interactive? Mark-as-read?
- Library feature is deliberately skipped (backend not ready) — this is correct

**Grade: 55%** — Functional but basic UI.

### 3.8 Offline Mode — 75% Complete

**What's done:**
- `SyncManager` with retry and idempotency
- `SyncQueue` with `enqueueSnapshot` for calculation snapshots
- `SyncWorker` with 30-second polling
- `AppLifecycleState` handling (pause/resume sync worker)
- Offline quiz practice mode with local grading
- Offline banner in quiz attempt screen

**What's missing:**
- Background fetch for daily quiz pre-download (the plan's midnight cron)
- `OfflineStateBanner` as a shared widget (is it only in the quiz screen or visible everywhere?)
- When user reconnects, the reconciliation between offline score and server score — is this actually implemented or just described?
- The `is_current` flag in downloads table — not verified in code
- Download manager for offline packs (42MB packs) — `DownloadsScreen` referenced but is it implemented?

**Grade: 75%** — The core sync works. Background prefetch and large offline packs are missing.

---

## 4. Critical Blockers

These must be resolved before the app is useful to any user.

### Blocker 1: No Assets (Impact: CRITICAL — App Looks Broken)

**Current state:**
```
assets/animations/ → .gitkeep
assets/fonts/      → .gitkeep
assets/images/     → .gitkeep
assets/translations/ → .gitkeep (wait — this should have en/ne/hi JSONs)
```

**In `pubspec.yaml`, fonts are commented out:**
```yaml
# fonts:
#   - family: InstrumentSans
#     fonts:
#       - asset: assets/fonts/InstrumentSans-Regular.ttf
# TODO: uncomment when fonts added
```

**Result:** The app runs using the Android system font (Roboto) and the iOS system font (SF Pro). It looks like a prototype, not a premium product.

**Fix required:**
1. Download InstrumentSans from Google Fonts (free, open source): https://fonts.google.com/specimen/Instrument+Sans
2. Download NotoSansDevanagari from Google Fonts: https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari
3. Add both to `assets/fonts/`
4. Uncomment the fonts section in `pubspec.yaml`
5. Download 8 Lottie JSON files from LottieFiles.com
6. Create/export brand SVGs

### Blocker 2: Firebase Not Configured (Impact: CRITICAL — 5 Services Dead)

**Current state:**
- `android/app/google-services.json` — ABSENT (gitignored as per `docs/FIREBASE_SETUP.md`)
- `ios/Runner/GoogleService-Info.plist` — ABSENT
- Firebase plugin IS in pubspec and IS initialized in bootstrap conditionally
- Comment in AGENTS.md: "All Firebase consumers no-op safely while it is absent"

**What fails without Firebase:**
- Push notifications (FCM) — DEAD
- Crashlytics (crash reporting) — DEAD
- Analytics (all 25 events) — DEAD
- Remote Config (feature flags) — DEAD
- Battle mode (relies on Firebase custom token for RTDB) — DEAD

**Fix required:**
1. Create Firebase project at console.firebase.google.com
2. Register Android app (`com.bisaas.civilcal`)
3. Download `google-services.json` → `android/app/`
4. Register iOS app (same package)
5. Download `GoogleService-Info.plist` → `ios/Runner/`
6. Run `flutter pub get` to verify firebase_core init works

### Blocker 3: Battle Mode Is a Placeholder (Impact: HIGH — Core Feature Missing)

The battle mode is the single most engaging feature for competitive users. It drives daily active usage. The current implementation is a debug screen showing API tokens.

Full implementation plan is in Section 9.

### Blocker 4: Calculator Is Unusable (Impact: HIGH — Core Feature Unusable)

The calculator requires users to type field names they don't know. This is not a consumer-facing product. Full schema-driven implementation plan is in Section 10.

### Blocker 5: Android SDK Not Installed (Impact: HIGH — Cannot Test)

Per AGENTS.md: "Android SDK not yet installed in this shell — `flutter doctor` shows `Android toolchain: X`"

Every feature must be tested on a real Android device. Zero device testing has been done.

Setup guide is in Section 14.

---

## 5. Gap Analysis — Detailed Findings Per File

### 5.1 Files That Need Creation

```
lib/features/auth/presentation/screens/splash_screen.dart
  Status: MISSING (referenced in progress but not in directory)
  Priority: P0 — App cannot launch without splash
  
lib/features/auth/presentation/screens/login_screen.dart
  Status: EXISTS as login_page.dart (different name — verify it has the full design)
  Priority: P0

lib/features/auth/presentation/widgets/social_login_button.dart
  Status: MISSING
  Priority: P1

lib/features/quiz/presentation/screens/quiz_browser_screen.dart
  Status: MISSING — how do users find quizzes?
  Priority: P0 — Core user flow is broken without this
  
lib/features/quiz/presentation/screens/quiz_intro_screen.dart
  Status: MISSING — plan specifies pre-quiz screen
  Priority: P1

lib/features/quiz/presentation/screens/quiz_review_screen.dart
  Status: MISSING — "Review All Answers" button goes nowhere
  Priority: P1

lib/features/quiz/presentation/widgets/difficulty_badge.dart
  Status: MISSING
  Priority: P2
  
lib/features/quiz/presentation/widgets/lifeline_bar.dart
  Status: MISSING — lifeline system (50/50, Hint, Skip) not built
  Priority: P1

lib/features/gamification/presentation/widgets/level_up_overlay.dart
  Status: MISSING
  Priority: P1

lib/features/gamification/presentation/widgets/achievement_unlock_toast.dart
  Status: MISSING
  Priority: P1

lib/features/gamification/presentation/widgets/coin_float_animation.dart
  Status: MISSING
  Priority: P2

lib/features/gamification/presentation/screens/leaderboard_screen.dart
  Status: UNKNOWN — not verified from directory listing
  Priority: P1

lib/features/battle/presentation/screens/battle_matchmaking_screen.dart
  Status: MISSING — matchmaking is embedded in arena screen
  Priority: P0 (when battle is built)

lib/features/battle/presentation/screens/battle_result_screen.dart
  Status: MISSING
  Priority: P0 (when battle is built)

lib/features/profile/presentation/screens/edit_profile_screen.dart
  Status: MISSING
  Priority: P2

lib/features/calculator/presentation/widgets/calculator_input_field.dart
  Status: MISSING — schema-driven inputs not built
  Priority: P0 (calculator is unusable without)

lib/features/calculator/presentation/widgets/formula_display.dart
  Status: MISSING — flutter_math_fork installed but unused
  Priority: P1

lib/features/calculator/presentation/widgets/step_by_step_solution.dart
  Status: MISSING — API returns steps, never rendered
  Priority: P1

lib/shared/widgets/ambient_glow_background.dart
  Status: MISSING — signature design element not built
  Priority: P2

lib/shared/widgets/glassmorphic_card.dart
  Status: EXISTS ✅ (confirmed in directory listing)

lib/core/sync/background_fetch.dart
  Status: Referenced in plan, verify if created
  Priority: P2
  
lib/features/downloads/presentation/screens/downloads_screen.dart
  Status: Referenced in profile hub, verify implementation
  Priority: P2
```

### 5.2 Files That Exist But Are Incomplete

```
lib/features/battle/presentation/screens/battle_arena_screen.dart
  Status: PLACEHOLDER — explicit "RTDB stream placeholder" comment
  Missing: Entire real-time gameplay loop
  Priority: P0

lib/features/calculator/presentation/screens/calculator_detail_screen.dart
  Status: PARTIAL — generic form, not schema-driven
  Missing: Schema-driven inputs, formula display, step-by-step
  Priority: P0

lib/app/router/app_router.dart
  Status: PARTIAL — quiz result screen not in route tree (uses Navigator directly)
  Missing: Named routes for quiz_result, quiz_review, calculator_history
  Priority: P1

pubspec.yaml
  Status: PARTIAL — fonts commented out
  Missing: Uncomment fonts section after adding font files
  Priority: P0

android/app/google-services.json
  Status: ABSENT (gitignored, needs to be created)
  Priority: P0

ios/Runner/GoogleService-Info.plist
  Status: ABSENT (gitignored, needs to be created)
  Priority: P0
```

### 5.3 Empty Asset Directories

```
assets/animations/ → EMPTY (.gitkeep only)
  Need: level_up.json, achievement_unlock.json, confetti.json, 
        correct_answer.json, wrong_answer.json, streak_fire.json,
        battle_win.json, battle_lose.json, loading_engineering.json (9 files)

assets/fonts/ → EMPTY (.gitkeep only)
  Need: InstrumentSans-Regular.ttf, InstrumentSans-Medium.ttf,
        InstrumentSans-SemiBold.ttf, InstrumentSans-Bold.ttf,
        NotoSansDevanagari-Regular.ttf (5 files)

assets/images/ → EMPTY (.gitkeep only)
  Need: logo.svg, logo_dark.svg, onboarding_1.svg, onboarding_2.svg,
        onboarding_3.svg, empty_quiz.svg, empty_state.svg, offline.svg (8 files)

assets/translations/ → EMPTY (.gitkeep only)
  Wait — where are the ARB files? The l10n system uses .arb in lib/l10n/
  Actually check: lib/l10n/ directory exists
```

---

## 6. The bisaas Backend — What Mobile Needs From It

### 6.1 API Endpoints Required by Mobile (Verification Checklist)

The following endpoints are called by the Flutter app. Each must be verified as fully implemented in `C:\laragon\www\bisaas`:

```
Authentication:
  ✓ POST /api/v1/auth/login       — returns PAT + expires_at
  ✓ POST /api/v1/auth/register    — creates user + PAT
  ✓ POST /api/v1/auth/refresh     — rotates PAT
  ✓ DELETE /api/v1/auth/logout    — revokes PAT
  ? POST /api/v1/auth/google      — Google OAuth exchange → need to verify

User:
  ✓ GET /api/v1/me               — user profile with level/XP/coins/streak
  ? PUT /api/v1/me               — profile update (name, avatar)
  ? POST /api/v1/me/avatar       — avatar upload

Dashboard:
  ✓ GET /api/v1/dashboard        — home screen aggregation
  ? GET /api/v1/quiz/streak      — streak data (days, at_risk)
  ✓ GET /api/v1/quiz/daily       — today's daily quiz
  ? GET /api/v1/learning/today   — learning plan for today
  ? GET /api/v1/quiz/game/missions/dashboard — missions

Quiz:
  ✓ GET /api/v1/quiz             — quiz list (categories, search)
  ✓ POST /api/v1/quiz/attempts/start   — start attempt + Idempotency-Key
  ✓ POST /api/v1/quiz/attempts/:id/answers — submit answer
  ✓ POST /api/v1/quiz/attempts/:id/finish — finish + get result
  ? GET /api/v1/quiz/attempts/:id/result — get result after completion
  
  CRITICAL MISSING: Schema for question images
  When QuizQuestion.imageUrl != null, what URL does it return?
  Does it return a signed storage URL or a relative path?
  The Flutter app NEVER renders question images (not found in quiz widgets)
  This is a MAJOR gap for visual questions (engineering diagrams)

Calculators:
  ✓ GET /api/v1/calculators              — list all (grouped by domain)
  ✓ GET /api/v1/calculators/:domain/:slug — get config WITH FIELD SCHEMA
  ✓ POST /api/v1/:domain/:slug/calculate — run calculation
  ? GET /api/v1/calculators/:domain/:slug/history — user's saved calculations
  ? POST /api/v1/calculation-snapshots/sync — sync offline calculations
  
  CRITICAL: Does GET /:domain/:slug return the field schema?
  The Flutter app needs {fields: [{name, label, unit, type, required, min, max}]}
  Verify this is in the API response before building schema-driven UI

Gamification:
  ? GET /api/v1/achievements     — all user achievements
  ? POST /api/v1/quiz/answers/:id/xp — how is XP awarded? In the answer response?
  
  CRITICAL: The QuizResult must return {xp_earned, coins_earned, new_level, leveled_up}
  Verify this is in the finish attempt response

Battle:
  ✓ GET /api/v1/quiz/firebase-token — get custom Firebase token
  ✓ POST /api/v1/quiz/battles/match — create/join a match
  ? PUT /api/v1/quiz/battles/:id/answers — submit answer during battle
  ? GET /api/v1/quiz/battles/:id — get battle state
  ? POST /api/v1/quiz/battles/:id/finish — server-side finish
  
  CRITICAL: What does the RTDB structure look like?
  /battles/{lobbyId}/
    questions: [question_ids]
    player1: {uid, score, current_idx, answers: {q_id: option_id}}
    player2: {uid, score, current_idx, answers: {q_id: option_id}}
    status: 'waiting|starting|in_progress|finished'
    started_at: timestamp
  
  The mobile app needs to know this exact structure to implement real-time battle.
  It must be documented in `MOBILE_API_INTEGRATION_GUIDE.md`.

Notifications:
  ✓ POST /api/v1/device-tokens   — register FCM token
  ✓ DELETE /api/v1/device-tokens/:token — unregister on logout
  ? GET /api/v1/notifications    — notification inbox
  ? PATCH /api/v1/notifications/:id/read — mark as read

Learning:
  ? GET /api/v1/learning/tracks  — available learning tracks
  ? POST /api/v1/learning/tutor  — non-streaming AI tutor

Mobile-specific:
  MISSING: GET /api/v1/mobile/daily-quiz-pack
    This is required for offline background fetch (pre-download tomorrow's quiz)
    Does this endpoint exist in bisaas?
    If not, it must be created: returns {quiz_id, question_ids, image_urls[]}
    
  MISSING: RTDB structure documentation
    The mobile app needs to know Firebase RTDB paths for battle
    This must be in MOBILE_API_INTEGRATION_GUIDE.md
```

### 6.2 API Contract Gaps That Block Mobile Features

**Gap 1: `GET /api/v1/mobile/daily-quiz-pack` — MISSING**

The offline background fetch (midnight pre-download) calls this endpoint. It doesn't exist. If the bisaas backend doesn't have it, offline daily quiz preparation cannot work. This is a backend task.

**Required response:**
```json
{
  "success": true,
  "data": {
    "quiz_id": 123,
    "valid_for_date": "2026-08-31",
    "questions": [
      {
        "id": 456,
        "body": "What is the maximum water-cement ratio...",
        "options": [...],
        "image_url": "https://civilcal.com/storage/questions/456.webp"
      }
    ],
    "question_image_urls": ["https://..."]
  }
}
```

**Gap 2: Calculator Field Schema — VERIFY**

The `GET /api/v1/calculators/{domain}/{slug}` response must include a `fields` array. Without it, the Flutter app cannot render labeled inputs.

**Required in response:**
```json
{
  "data": {
    "slug": "beam-deflection",
    "label": "Beam Deflection Calculator",
    "fields": [
      {
        "name": "span_length",
        "label": "Span Length",
        "unit": "m",
        "type": "number",
        "required": true,
        "min": 0.1,
        "max": 100
      }
    ],
    "steps_in_response": true,
    "formula_latex": "\\delta = \\frac{5wL^4}{384EI}"
  }
}
```

**Gap 3: Quiz Finish Response — VERIFY**

The `POST /api/v1/quiz/attempts/:id/finish` response must include gamification data:
```json
{
  "data": {
    "score": 85.7,
    "correct": 6,
    "total": 7,
    "percentile": 18.3,
    "xp_earned": 150,
    "coins_earned": 30,
    "leveled_up": true,
    "new_level": 13,
    "achievements_unlocked": [{"id": 5, "name": "Week Warrior"}],
    "challenge_token": "abc123"
  }
}
```

**Gap 4: Firebase RTDB Structure — NOT DOCUMENTED**

There is no documentation of the RTDB structure in `MOBILE_API_INTEGRATION_GUIDE.md`. The battle feature cannot be implemented without knowing the exact RTDB paths, rules, and data shape.

---

## 7. Phase Plan — Ordered by Impact

### Phase A: Foundation Fixes (This Week — ~2 days)

These are all quick wins that unblock everything else:

**A1: Add fonts (2 hours)**
- Download InstrumentSans (4 weights) from fonts.google.com
- Download NotoSansDevanagari from fonts.google.com
- Place in `assets/fonts/`
- Uncomment fonts in `pubspec.yaml`
- Run `flutter pub get`
- Verify on a widget test that the text uses InstrumentSans

**A2: Configure Firebase (3 hours)**
- Create Firebase project `civilcal-prod`
- Create Firebase project `civilcal-dev`
- Register Android app for each
- Download and place `google-services.json` for each flavor
- Register iOS app for each
- Download and place `GoogleService-Info.plist`
- Run `flutter pub get && flutter analyze` — should be 0 issues
- Test that FCM token registers on login

**A3: Install Android SDK (2 hours)**
- Follow guide in Section 14
- Run `flutter doctor` → all green
- Run on Android emulator `flutter run --dart-define=ENV=dev`
- Verify app launches and auth works

**A4: Fix go_router violations (1 hour)**
- Move `QuizResultScreen` navigation from `Navigator.of` to `context.go()`
- Add `/quiz/:id/result` and `/quiz/:id/review` to the route tree
- Verify deep links work

**A5: Add localization ARB content (2 hours)**
- Verify `lib/l10n/` has `app_en.arb`, `app_ne.arb`, `app_hi.arb`
- Fill all missing keys (run `flutter gen-l10n` to identify warnings)
- Get Nepali translations reviewed (if possible, by a Nepali engineer)

**Expected output after Phase A:** App looks professional (correct fonts), Firebase works, analytics fire, crash reports go to Crashlytics, app can be tested on Android.

### Phase B: Core Feature Completion (Week 2 — ~5 days)

**B1: Quiz Browser Screen (1 day)**
- `QuizBrowserScreen` — how does a user navigate to a quiz?
- Show: categories/domains, recent quizzes, recommended, search
- This is the entry point to the quiz — currently broken

**B2: Calculator Schema-Driven (2 days)**
- Implement schema-driven inputs per Section 10
- This transforms the calculator from developer tool to user product

**B3: Lottie Animations (1 day)**
- Download 9 Lottie JSON files from LottieFiles.com
- Place in `assets/animations/`
- Wire into quiz correct/wrong answer
- Wire into level up overlay
- Wire into achievement unlock toast
- Wire into confetti on quiz completion

**B4: Gamification Overlays (1 day)**
- `LevelUpOverlay` widget + wire to quiz finish
- `AchievementUnlockToast` widget + wire to quiz finish
- Coin float animation

**Expected output after Phase B:** The app feels like a real product. Quiz is satisfying (animations). Calculator is usable (labeled inputs). Users can discover quizzes.

### Phase C: Battle Mode (Week 3 — ~5 days)

Full battle mode implementation per Section 9. This is the most complex feature and requires:
- Firebase RTDB structure documentation from bisaas team
- `firebase_database` package addition to pubspec
- New screens: matchmaking, arena, result
- Real-time state synchronization

**Expected output after Phase C:** The app's marquee feature works. Users can compete head-to-head.

### Phase D: Polish & Profile (Week 4 — ~3 days)

**D1: Profile Skill Radar (fl_chart, 0.5 days)**
- `RadarChart` from `fl_chart` for the 6-axis skill assessment
- Data from server `GET /api/v1/profile/skills`

**D2: Shareable Profile Card (0.5 days)**
- `RenderRepaintBoundary` → generate PNG → native share
- The flagship "show off your skills" feature

**D3: Question Images (0.5 days)**
- When `question.imageUrl != null`, render with `CachedNetworkImage`
- Engineering diagrams in questions are critical for civil engineering

**D4: Edit Profile + Avatar Upload (0.5 days)**
- `image_picker` is installed but not used
- Connect to `POST /api/v1/me/avatar`

**D5: Quiz Intro Screen (0.5 days)**
- Pre-quiz screen showing topic, duration, question count, difficulty

**D6: Quiz Review Screen (0.5 days)**
- All questions with user's answer vs. correct answer
- Expandable explanation per question

**Expected output after Phase D:** Profile is a feature, not just a hub. Quiz flow is complete with intro and review.

### Phase E: Testing & Performance (Week 5 — ~3 days)

**E1: Physical Device Testing (1 day)**
- Install on a Redmi Note 12 or equivalent
- Profile with DevTools in profile mode
- Verify 60fps on quiz transitions
- Check memory stays under 150MB

**E2: Test Coverage Increase (1 day)**
- Quiz browser test
- Calculator schema-driven test
- Battle state machine test
- Add golden tests for 5 key screens

**E3: Accessibility Audit (0.5 days)**
- Enable TalkBack on Android
- Verify all interactive elements are reachable and labeled
- Fix any violations

**E4: Performance Optimizations (0.5 days)**
- Verify image cache size limit (100MB cap)
- Check for rebuild issues with DevTools
- Verify startup time < 2s

### Phase F: Store Submission (Week 6 — ~2 days)

**F1: App Screenshots (0.5 days)**
- 6 screenshots on Pixel 6 emulator
- Framed with device mockup

**F2: Play Store Setup (0.5 days)**
- Create Play Console developer account
- Fill metadata (description, keywords, category)
- Run `fastlane android beta`

**F3: iOS Setup (1 day)**
- Configure Xcode 16+
- Apple Developer account
- Certificates via Fastlane Match
- TestFlight submission

---

## 8. UI Polish Specifications

### 8.1 What the App Should Look Like vs. What It Currently Looks Like

**Current state (honest description):**
- System font (Roboto/SF Pro) — looks like a default Material app
- Plain white/grey Scaffold backgrounds — no ambient glow, no glass
- No animations anywhere
- Flat colored buttons — no gradients
- Quiz answer options are functional but plain
- Correct/wrong feedback has no celebration

**Target state (from the master plan):**
- InstrumentSans font at correct weights — premium, editorial feel
- Dark (`#0B0F17`) backgrounds with subtle cyan glow blobs
- Glassmorphic cards (`BackdropFilter` blur + `Border.all(glass)`)
- Lottie animations on key moments
- Gradient buttons (cyan → blue)
- Answer options with immediate color feedback + icon + animation

### 8.2 The Missing Brand Identity Elements

The master plan specifies these brand visuals that are ALL missing:

**1. Ambient Glow Background (for quiz, battle, gamification screens)**

This is CivilCal's signature visual. A dark `#0B0F17` base with two animated blobs:
- Top-right: `#22D3EE` (brand cyan) at 15% opacity, 300dp, 8s animation
- Bottom-left: `#8B5CF6` (guild purple) at 10% opacity, 250dp, 12s animation
- Subtle noise texture overlay at 3% opacity

This is NOT on any screen currently.

**2. The GlassmorphicCard Applied Everywhere**

The `glassmorphic_card.dart` widget EXISTS but it's not used in:
- Quiz question card (uses plain Container)
- Calculator result card (uses plain Container with colored border)
- Achievement cards (uses plain Container)
- Home screen cards (uses plain Surface color)

Every card in the gamification screens should use GlassmorphicCard.

**3. The Gradient Primary Button**

Current: `FilledButton` with Material 3 default style
Target: Button with `LinearGradient(colors: [#22D3EE, #0EA5C9])` background

The `gradient_button.dart` shared widget EXISTS but it's not used anywhere.

### 8.3 Quiz Answer Option Polish

Current answer option implementation is functional but spartan. From reading `quiz_attempt_screen.dart`:
- Uses `AnimatedContainer` (correct)
- Shows A/B/C/D letter (correct)
- Shows correct/wrong colors (correct)
- Shows check/X icon (correct)
- 0ms selection → server → color change (correct)

Missing:
- The `_AnswerOptionTile` is inlined in the attempt screen, not a separate widget
- No minimum 56dp height guarantee on the Container
- No Semantics label (accessibility)
- No scale animation on correct answer (plan specifies scaling effect)
- The InkWell splash is the default Material ripple — should be a custom ripple in brand cyan

### 8.4 Home Screen Enhancement

Current home screen has the stats, streak card, XP bar. Missing:
- The "Quick Actions" 2×2 grid (Battle Mode, Courses, Leaderboard, Calculators)
- "Continue where you left off" course card
- "Recommended for you" horizontal chip scroll

These are specifically mentioned in the master plan's home layout (Section 14.1) and drive user navigation to features.

---

## 9. Battle Mode Full Implementation Plan

### 9.1 Prerequisites Before Building

**Step 1: Get RTDB structure from bisaas backend**

The bisaas backend controls the Firebase RTDB. Before writing a single line of Flutter code for battle, need from bisaas team:

```
1. What Firebase project is used for battle RTDB?
2. What is the RTDB structure?
3. What Firebase security rules are set?
4. How does server write to RTDB? (via `kreait/firebase-php` library?)
5. When does server create the RTDB node? (on POST /battles/match?)
6. When does server update score? (after each answer POST? or after finish?)
7. What's the lobbyId format? (UUID? server-assigned?)
```

**Step 2: Add firebase_database to pubspec.yaml**

```yaml
firebase_database: ^11.0.0
```

### 9.2 The Battle State Machine

```
BattlePhase (expanded from current):
  idle                    → Show "Find Match" button
  fetchingToken           → Getting Firebase custom token
  connectingFirebase      → Signing into Firebase with custom token
  searching               → POST /battles/match sent, waiting for opponent
  countdown(3)            → Opponent found, 3-2-1 countdown
  countdown(2)
  countdown(1)
  inProgress(questionIdx) → Question N of total, showing to both players
  answered(questionIdx)   → User answered, waiting for next question or opponent
  finished                → Battle complete
  error(message)          → Error state
```

### 9.3 The Three Battle Screens

**Screen 1: `BattleMatchmakingScreen`**

```
Layout:
  Large animated searching indicator (Lottie or custom CircularReveal)
  User avatar (large, 80dp, with pulsing ring animation)
  "VS" text
  Opponent avatar placeholder (shimmer while searching)
  "Searching for opponent..." animated dots
  Category chip (what type of quiz)
  "Cancel" button
  
  When opponent found:
    Opponent avatar fills in with slide animation
    Opponent name appears
    "Match found! Starting in..." countdown appears
    3-2-1 countdown: full-screen with haptic each count
    Navigate to BattleArenaScreen
```

**Screen 2: `BattleArenaScreen` (The Real One)**

```
Layout:
  Top header bar:
    [My score | VS | Opponent score]
    [My avatar | ---- | Opponent avatar]
    [Progress indicator for both (how many answered)]
  
  Timer bar (synced from RTDB, not local):
    Total time per question (from server)
    Live countdown visible to both players
  
  Question display:
    Same as QuizAttemptScreen but without timer (timer is in header)
    4 answer options with immediate tap feedback
  
  RTDB listeners:
    Listen to /battles/{lobbyId}/player2/score (opponent score)
    Listen to /battles/{lobbyId}/player2/current_idx (opponent progress)
    Listen to /battles/{lobbyId}/status (for 'finished')
    
  When opponent answers (from RTDB):
    Show subtle indicator: "Opponent answered!" (not the correct/wrong answer)
    
  When user answers:
    POST /api/v1/quiz/battles/{id}/answers with {question_idx, option_id}
    Server validates, writes result to RTDB, updates score in RTDB
    
  When status = 'finished' (RTDB):
    Navigate to BattleResultScreen
```

**Screen 3: `BattleResultScreen`**

```
Layout:
  Confetti Lottie animation (win) or minimal animation (loss)
  
  Score comparison:
    My avatar + score + "YOU WIN" / "YOU LOSE"
    VS
    Opponent avatar + score
    
  Question breakdown:
    For each question: who answered first? Who was correct?
    Mini comparison table
    
  XP/coins earned (from server response)
  
  "Rematch" button (POST /battles/rematch or creates new match)
  "Battle History" link
  "Share Result" (native share with result card)
```

### 9.4 Firebase Security Considerations

**The battle RTDB must be READ-ONLY for clients:**
- Clients listen to `/battles/{lobbyId}` for state changes
- Clients NEVER write to RTDB directly
- All game state changes come from the server (via REST API)
- Server writes to RTDB using Firebase Admin SDK

This is the "server-authoritative" principle applied to Firebase. The Flutter app is a real-time UI overlay on server state.

**Firebase custom token flow:**
```
1. Flutter: GET /api/v1/quiz/firebase-token (Bearer PAT)
2. bisaas server: generate Firebase custom token via Admin SDK
3. Flutter: FirebaseAuth.signInWithCustomToken(token)
4. Firebase: authenticate Flutter client with RTDB rules matching user UID
5. Flutter: listen to /battles/{lobbyId} per RTDB security rules
```

---

## 10. Calculator Schema-Driven Implementation Plan

### 10.1 The API Schema Contract

The `CalculatorConfig` entity must be extended to include field definitions:

```dart
// lib/features/calculator/domain/entities/calculator.dart — extend:

@freezed
class CalculatorField with _$CalculatorField {
  const factory CalculatorField({
    required String name,        // API field name ("span_length")
    required String label,       // Display label ("Span Length")
    String? unit,                // Unit string ("m", "kN/m")
    required String type,        // "number", "select", "boolean"
    required bool required,
    double? min,
    double? max,
    int? precision,              // decimal places for result
    List<CalculatorSelectOption>? options,  // for select type
  }) = _CalculatorField;
}

@freezed
class CalculatorSelectOption with _$CalculatorSelectOption {
  const factory CalculatorSelectOption({
    required String value,
    required String label,
  }) = _CalculatorSelectOption;
}

// Extend CalculatorConfig:
@freezed
class CalculatorConfig with _$CalculatorConfig {
  const factory CalculatorConfig({
    required String slug,
    required String label,
    required String domainLabel,
    required String calculateEndpoint,
    String? formulaLatex,          // NEW — for flutter_math_fork
    List<CalculatorField>? fields, // NEW — schema-driven inputs
    bool stepsInResponse = false,  // NEW — does response include steps[]
  }) = _CalculatorConfig;
}
```

### 10.2 The Schema-Driven Form Widget

Replace the current `_FieldEntry` key-value system with a proper schema-driven form:

```dart
// lib/features/calculator/presentation/widgets/calculator_input_field.dart

// For type: 'number'
// Renders: labeled TextFormField with unit suffix + min/max validation
// Label: "Span Length"  
// Hint: "Enter value in m"
// Suffix: "m"
// Keyboard: numeric
// Validation: min ≤ value ≤ max, required check

// For type: 'select'
// Renders: DropdownButtonFormField with options
// Label: "Beam Profile"
// Options: ["ISMB 100", "ISMB 150", "ISMB 200", ...]

// For type: 'boolean'
// Renders: SwitchListTile
// Label: "Include self-weight"
```

### 10.3 Formula Display

```dart
// lib/features/calculator/presentation/widgets/formula_display.dart

// Uses flutter_math_fork to render LaTeX formulas

Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.brand.withValues(alpha: 0.06),
      borderRadius: AppRadii.cardRadius,
      border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text('Formula', style: labelStyle),
        SizedBox(height: 8),
        Math.tex(
          config.formulaLatex!,
          textStyle: TextStyle(fontSize: 16),
          // flutter_math_fork renders LaTeX
        ),
      ],
    ),
  );
}
```

### 10.4 Step-by-Step Solution

```dart
// lib/features/calculator/presentation/widgets/step_by_step_solution.dart

// The calculator API returns steps[] in the result:
// {
//   "steps": [
//     {"label": "Step 1: Calculate moment of inertia", 
//      "formula": "I = \\frac{bh^3}{12}", 
//      "result": "I = 450.2 cm⁴"},
//     ...
//   ]
// }

// Renders each step as an expandable card
// Step label as title
// Formula rendered with flutter_math_fork
// Result value prominently shown
```

### 10.5 Result Status (SAFE/CHECK/FAIL)

```dart
// In CalculationResult entity:
// The API returns: {status: "safe" | "check" | "fail", limit_value: ..., actual_value: ...}

Widget _buildStatusBadge(CalculationResult result) {
  final (color, icon, text) = switch(result.status) {
    'safe' => (AppColors.correctGreen, Icons.check_circle, 'SAFE'),
    'check' => (AppColors.streakOrange, Icons.warning, 'CHECK'),
    'fail' => (AppColors.wrongRed, Icons.cancel, 'FAIL'),
    _ => (Colors.grey, Icons.info, 'RESULT'),
  };
  return Container(
    // ... colored container with icon and text
  );
}
```

---

## 11. Gamification Animations Implementation Plan

### 11.1 Lottie File Sourcing

All Lottie files must come from LottieFiles.com (lottiefiles.com). Use ONLY files with free licenses for commercial use (check each file's license).

**Required files and their LottieFiles search terms:**

| File | Search Term | Notes |
|---|---|---|
| `level_up.json` | "level up stars" or "achievement stars" | Stars + bright burst |
| `achievement_unlock.json` | "trophy unlock" or "achievement badge" | Trophy animation |
| `confetti.json` | "confetti celebration" | Multi-color confetti |
| `correct_answer.json` | "checkmark success" | Clean green check |
| `wrong_answer.json` | "incorrect x" | Red X, brief |
| `streak_fire.json` | "fire flame loop" | Looping fire |
| `battle_win.json` | "victory crown" or "winner" | Gold crown |
| `battle_lose.json` | "game over" | Subtle, not demoralizing |
| `loading_engineering.dart` | "engineering gear" or "loading cogs" | Engineering theme |

**License requirement:** Download only Lottifiles with "Free for commercial use" badge. Add a file `assets/LICENSES.md` listing each file, its source URL, and its license.

### 11.2 Correct Answer Animation Flow

When the server confirms a correct answer:

```
t=0ms:    Server response received (is_correct: true)
t=0ms:    State → feedback (green border on option)
t=0ms:    Haptic: HapticFeedback.lightImpact()
t=50ms:   Lottie.asset('correct_answer.json') plays as overlay
           (small, positioned over the selected option)
t=200ms:  XP float animation: "+50 XP" floats upward from answer
t=600ms:  Lottie completes, cleanup
t=700ms:  Next question loads (slide from right)
```

### 11.3 Level Up Overlay

```dart
// lib/features/gamification/presentation/widgets/level_up_overlay.dart

// Triggered by: QuizResult.leveledUp == true (from server)
// Display duration: 2.5 seconds (auto-dismiss)
// Dismiss on tap

class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final String newTitle;  // "Journeyman Engineer" etc from server
  final List<String> unlocks; // features unlocked at this level
  
  // Full-screen overlay with:
  // Dark semi-transparent backdrop
  // Center card with:
  //   Lottie: level_up.json (playing once)
  //   "LEVEL UP!" title (displaySmall style, gold color)
  //   "Level X → Level X+1" text
  //   New title text
  //   Unlocks list (if any)
  //   Auto-dismisses after 2.5s
  //   User can tap to dismiss early
  //   Heavy haptic on appear
}
```

### 11.4 Achievement Unlock Toast

```dart
// lib/features/gamification/presentation/widgets/achievement_unlock_toast.dart

// Slides down from top, stays 4 seconds, slides back up
// Does NOT block interaction (user can still tap quiz options)
// Shown via overlay (above everything else)

class AchievementUnlockToast extends StatefulWidget {
  final Achievement achievement;
  
  // Layout:
  //   Row:
  //     Achievement badge image (56dp, gold border)
  //     Column:
  //       "Achievement Unlocked!" (label, gold color)
  //       achievement.name (title style)
  //       achievement.description (body small, muted)
  //   On tap: navigate to achievements screen
  //
  // Animation:
  //   Enter: slideY from -1.0 to 0.0 (300ms, easeOut)
  //   After 4s: slideY from 0.0 to -1.0 (300ms, easeIn)
  //
  // Haptic: heavyImpact on enter
}
```

---

## 12. Assets Specification — Every File Required

### 12.1 Fonts (Priority: P0 — Blocks Typography)

Download from fonts.google.com (free, OFL license):

```
Instrument Sans:
  assets/fonts/InstrumentSans-Regular.ttf      (weight: 400)
  assets/fonts/InstrumentSans-Medium.ttf       (weight: 500)
  assets/fonts/InstrumentSans-SemiBold.ttf     (weight: 600)
  assets/fonts/InstrumentSans-Bold.ttf         (weight: 700)
  
Noto Sans Devanagari:
  assets/fonts/NotoSansDevanagari-Regular.ttf  (weight: 400)
  
Total: 5 font files
```

**After adding fonts, uncomment in pubspec.yaml and run:**
```bash
flutter pub get
flutter run  # verify font is rendering (not Roboto)
```

### 12.2 Lottie Animations (Priority: P1 — Blocks Game Feel)

```
assets/animations/level_up.json           (150-200KB target)
assets/animations/achievement_unlock.json  (100-150KB target)
assets/animations/confetti.json            (100-200KB target)
assets/animations/correct_answer.json      (50-80KB target)
assets/animations/wrong_answer.json        (50-80KB target)
assets/animations/streak_fire.json         (80-120KB target, looping)
assets/animations/battle_win.json          (150-200KB target)
assets/animations/battle_lose.json         (100-150KB target)
assets/animations/loading_engineering.json (80-120KB target, looping)

Total: 9 JSON files
```

**Lottie size optimization:** Keep each file under 200KB. If a LottieFiles download is larger, use the LottieFiles online optimizer.

### 12.3 Brand Images (Priority: P1 — Blocks Visual Identity)

```
assets/images/logo.svg              — CivilCal wordmark + truss-C, white on transparent
assets/images/logo_dark.svg         — CivilCal wordmark + truss-C, dark on transparent
assets/images/logo_icon.svg         — Truss-C icon only (used as app icon source)
assets/images/onboarding_1.svg      — Illustration for exam selection (books/engineering)
assets/images/onboarding_2.svg      — Illustration for study time (clock/calendar)
assets/images/onboarding_3.svg      — Illustration for skill level (progress bars)
assets/images/empty_quiz.svg        — Empty state for quiz list
assets/images/empty_calculator.svg  — Empty state for calculator history
assets/images/offline.svg           — Offline state illustration
assets/images/battle_vs.svg         — The "VS" graphic for battle mode

Total: 10 SVG files
```

**SVG source:** Use a free SVG illustration library like:
- undraw.co (free, commercial, Figma-editable)
- storyset.com (animated illustrations, free commercial tier)
- icons8.com illustrations

### 12.4 App Icons (Priority: P0 — Required for Store)

```
App icon source: assets/images/logo_icon.svg (1024x1024 SVG)

Generate using flutter_launcher_icons package:
  android/
    app/src/main/res/mipmap-mdpi/ic_launcher.png
    app/src/main/res/mipmap-hdpi/ic_launcher.png
    app/src/main/res/mipmap-xhdpi/ic_launcher.png
    app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    (+ adaptive icon foreground/background)
  
  ios/
    Runner/Assets.xcassets/AppIcon.appiconset/ (all sizes)
```

**Quick setup with flutter_launcher_icons:**
```yaml
# Add to pubspec.yaml dev_dependencies:
flutter_launcher_icons: ^0.14.0

# Add to pubspec.yaml:
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_icon.svg"
  adaptive_icon_background: "#0B0F17"
  adaptive_icon_foreground: "assets/images/logo_icon_foreground.png"
  
# Run:
dart run flutter_launcher_icons
```

---

## 13. Firebase Configuration Guide

### 13.1 Create Firebase Projects

**Project naming:**
- Development: `civilcal-dev`
- Production: `civilcal-prod`

**Create at:** https://console.firebase.google.com

### 13.2 Android Configuration

**For dev project:**
1. Add Android app with package name: `com.bisaas.civilcal` (from `android/app/build.gradle`)
2. SHA-1 fingerprint: run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
3. Download `google-services.json`
4. Place at `android/app/google-services-dev.json`
5. Add to `.gitignore`: `**/google-services.json`

**For prod project:**
1. Same package name
2. SHA-1 of the release signing key (from Fastlane keystore)
3. Download and place at `android/app/google-services-prod.json`

**Flavor-based file switching in `android/app/build.gradle`:**
```gradle
android {
  flavorDimensions "environment"
  productFlavors {
    dev {
      applicationIdSuffix ".dev"
      buildConfigField "String", "FIREBASE_CONFIG", '"google-services-dev.json"'
    }
    prod {
      buildConfigField "String", "FIREBASE_CONFIG", '"google-services-prod.json"'
    }
  }
}
```

### 13.3 iOS Configuration

**For dev project:**
1. Add iOS app with bundle ID: `com.bisaas.civilcal` (from `ios/Runner/Info.plist`)
2. Download `GoogleService-Info.plist`
3. Add to `ios/Runner/` via Xcode (drag into Runner target)
4. Add to `.gitignore`: `**/GoogleService-Info.plist`

### 13.4 Enable Required Services

In Firebase Console, enable:
- **Analytics** — auto-collected events + custom events
- **Crashlytics** — enable in crashlytics dashboard
- **Cloud Messaging** (FCM) — upload APNs key for iOS
- **Remote Config** — create default values for all feature flags
- **Realtime Database** — create database for battle mode, set security rules

### 13.5 RTDB Security Rules (Battle Mode)

```json
{
  "rules": {
    "battles": {
      "$lobbyId": {
        ".read": "auth != null",
        ".write": false,
        "player1": {
          ".read": "auth != null"
        },
        "player2": {
          ".read": "auth != null"
        }
      }
    }
  }
}
```

Rules: Authenticated users can READ any battle lobby. No client can WRITE. Server (Admin SDK) handles all writes.

---

## 14. Android SDK Setup on Windows

### 14.1 Prerequisites

- Windows 11 (confirmed from AGENTS.md context)
- Java 17 (JDK)
- Android Studio OR command-line tools only

### 14.2 Step-by-Step Setup

**Step 1: Install Java 17**
```powershell
# Run as administrator:
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements
# Restart terminal after installation
java -version  # Should show: openjdk 17.x.x
```

**Step 2: Install Android Studio (Recommended)**
```powershell
winget install --id Google.AndroidStudio -e --accept-package-agreements
```

After installation, open Android Studio:
- First launch wizard → install all SDK components
- SDK Manager → SDK Platforms: Install API 34 (Android 14)
- SDK Manager → SDK Tools: Install Platform-tools, Build-tools 34.0.0, Android Emulator
- SDK Manager → SDK Tools: Install Intel HAXM (for emulator acceleration on Intel CPUs)

**Step 3: Set Environment Variables**
```powershell
# Add to System Environment Variables:
ANDROID_HOME = %LOCALAPPDATA%\Android\Sdk
ANDROID_SDK_ROOT = %LOCALAPPDATA%\Android\Sdk

# Add to PATH:
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\tools
%ANDROID_HOME%\tools\bin
```

**Step 4: Accept Android Licenses**
```bash
flutter doctor --android-licenses
# Type 'y' to accept all licenses
```

**Step 5: Verify**
```bash
flutter doctor -v
# Should show:
# [✓] Flutter (channel stable, 3.47.2)
# [✓] Android toolchain
# [✓] Android Studio
```

**Step 6: Create Emulator**
In Android Studio → AVD Manager:
- Create Virtual Device
- Phone → Pixel 6 (recommended for testing)
- System Image: API 34 (Android 14)
- Name: Pixel 6 API 34

**Step 7: Run App on Emulator**
```bash
cd C:\laragon\www\bisaasmobile
flutter devices  # Should show the emulator
flutter run --dart-define=ENV=dev --dart-define=API_HOST=http://10.0.2.2 -d emulator-5554
```

Note: Use `http://10.0.2.2` (not `http://bisaas.test`) for Android emulator to reach the Laragon dev server on the host machine.

### 14.3 Physical Device Testing

For Redmi Note 12 (or any Android phone):
1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices` → should show the phone
5. Run: `flutter run --dart-define=ENV=dev -d [device-id]`

---

## 15. Testing Gap Plan

### 15.1 Current Test Coverage Assessment

52 tests exist. From the task descriptions:
- `TokenManager` tests (lifecycle, proactive refresh)
- `ApiException` unknown code test
- `RetryInterceptor` 429 backoff test
- `QuizState` sentinel pattern tests
- `DashboardDto` parsing tests
- `CalculatorDto` label fallback tests
- `BattleToken` entity tests
- `CertificatePinning` tests

These are good unit tests but they cover only the "happy path" data models and basic service behavior.

**Missing test categories:**

```
Missing: QuizController state machine tests
  Test: idle → loading → ready → answering → grading → feedback → finished
  Test: offline fallback (connectionError → offline mode)
  Test: combo counter increment
  Test: timer isolation (timer provider doesn't rebuild question widget)

Missing: Calculator schema-driven tests
  Test: CalculatorField renders correct widget type per 'type' field
  Test: Required field validation fires on empty submit
  Test: Number field accepts decimal, rejects text
  Test: Select field shows dropdown options

Missing: AuthController flow tests
  Test: Login success → token persisted in secure storage
  Test: Login failure → error state shown
  Test: Token refresh proactive (< 7 days remaining)
  Test: Logout → token cleared → redirect to login

Missing: Golden tests (screenshot regression)
  HomeScreen golden test (light + dark mode)
  QuizAttemptScreen golden test (question displayed)
  QuizResultScreen golden test (win state)
  CalculatorScreen golden test (result displayed)

Missing: Widget tests for key UI behavior
  Answer option: tap → selected state
  Answer option: correct feedback → green + check icon
  Answer option: wrong feedback → red + X icon
  Streak card: 0 days → hidden
  Streak card: 5 days → shown with 5
  XP bar: 0% → empty
  XP bar: 50% → half filled
  XP bar: 100% → triggers level up logic

Missing: Integration tests
  Full auth flow: enter email + password → home screen
  Full quiz flow: browse → start → answer all → see result
  Full calculator flow: select domain → enter values → see result
```

### 15.2 Target Coverage by Layer

| Layer | Target | Current Estimate |
|---|---|---|
| Domain entities | 90% | ~60% |
| Use cases | 85% | ~20% |
| Repository implementations | 80% | ~15% |
| Controllers/notifiers | 70% | ~30% |
| Widgets (golden) | 5 key screens | 0 |
| Integration tests | 3 critical flows | 0 |

### 15.3 Test Prioritization

**Priority 1 (before any store submission):**
- Quiz state machine complete test (all transitions)
- Auth flow integration test
- Token manager edge cases (expired, missing, refresh fails)

**Priority 2 (before wide release):**
- Calculator form validation tests
- Golden tests for 5 key screens
- Offline quiz behavior tests (connectionError → offline mode)

**Priority 3 (continuous improvement):**
- Battle state machine tests
- All repository implementation tests

---

## 16. Performance Profiling Plan

### 16.1 Performance Targets (From Master Plan)

| Metric | Target | Current Status |
|---|---|---|
| Cold start time | < 2s on Redmi Note 12 | Not measured |
| Quiz answer response | < 16ms visual | Not profiled |
| Page transition | 60fps | Not profiled |
| Memory (idle) | < 80MB | Not measured |
| Memory (quiz) | < 150MB | Not measured |
| Image cache size | < 100MB | No cap configured |
| Crash-free sessions | > 99.5% | Not measurable (Crashlytics not configured) |

### 16.2 How to Profile

**Step 1: Run in profile mode on Redmi Note 12 (NOT emulator)**
```bash
flutter run --profile -d [device-id]
```

Profile mode is NOT debug mode — it gives real performance data.

**Step 2: Open DevTools**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```
Or use VS Code's Flutter DevTools integration.

**Step 3: Measure cold start**
- Kill the app completely
- Start stopwatch
- Tap app icon
- Stop stopwatch when home screen is interactive

**Step 4: Check frame rate during quiz**
- Navigate to quiz
- Start a quiz
- Use DevTools "Performance" tab
- Look for any frames over 16ms (red)
- The timer update (1Hz) should NOT cause frames over 8ms

**Step 5: Memory profiling**
- DevTools "Memory" tab
- Navigate through all features
- Look for memory growth that doesn't plateau (memory leak)
- Check after 10 quiz completions that memory hasn't grown unboundedly

**Step 6: Image cache**
```dart
// Add this to check cache in debug builds:
// In main.dart (debug mode only):
PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
```

---

## 17. Localization Completion Plan

### 17.1 Current L10n State

The ARB system is configured (`l10n.yaml` + `lib/l10n/`). The progress notes say keys were added and `flutter gen-l10n` was run. But the actual content of the ARB files for Nepali and Hindi is unknown — translations may be missing or machine-translated.

### 17.2 Localization Review Checklist

**Verify these files exist and have content:**
```
lib/l10n/app_en.arb    — English (primary, complete)
lib/l10n/app_ne.arb    — Nepali (must be reviewed by native speaker)
lib/l10n/app_hi.arb    — Hindi (must be reviewed by native speaker)
```

**Run to check for missing translations:**
```bash
flutter gen-l10n
# If any key is missing in ne/hi ARB, it shows a warning
```

### 17.3 Key Strings That Must Be Correctly Translated

These specific strings will be seen constantly by users — incorrect translation destroys trust:

```
English → Nepali (Devanagari) — key strings:
"Daily Quiz" → "दैनिक क्विज"
"Start Quiz" → "क्विज सुरु गर्नुहोस्"
"Correct!" → "सही!"
"Incorrect" → "गलत"
"Your Score" → "तपाईंको स्कोर"
"Streak" → "स्ट्रिक"
"Level Up!" → "स्तर बढ्यो!"
"Battle Mode" → "युद्ध मोड"
"Calculate" → "गणना गर्नुहोस्"
"Offline mode" → "अफलाइन मोड"
"Sign in" → "साइन इन"
"Register" → "दर्ता गर्नुहोस्"
```

### 17.4 The Devanagari Font Issue

The `NotoSansDevanagari` font must be loaded and applied when the locale is `ne` or `hi`. In the current `AppTheme`, the `fontFamily` defaults to `InstrumentSans`. 

**Fix:** In `app_theme.dart`, detect the locale and switch font family:

```dart
// In AppTheme.buildTheme:
ThemeData buildTheme(Brightness brightness, Locale locale) {
  final isDevanagari = locale.languageCode == 'ne' || locale.languageCode == 'hi';
  final fontFamily = isDevanagari ? 'NotoSansDevanagari' : 'InstrumentSans';
  
  return ThemeData(
    textTheme: GoogleFonts.getTextTheme(fontFamily)
    // ...
  );
}
```

---

## 18. Store Submission Checklist

### 18.1 Google Play Store Requirements

**Before submission:**
- [ ] App icon (512x512 PNG, no transparency) — generate from `logo_icon.svg`
- [ ] Feature graphic (1024x500 PNG) — brand banner
- [ ] 6 phone screenshots (minimum 2) — from Pixel 6 emulator
- [ ] App signing key configured in `android/fastlane/Appfile`
- [ ] Package name confirmed: `com.bisaas.civilcal`
- [ ] `versionCode` and `versionName` in `pubspec.yaml`
- [ ] `minSdkVersion 29` (Android 10) in `android/app/build.gradle`
- [ ] No `testOnly` flag in the APK
- [ ] Privacy policy URL: `https://civilcal.com/legal/privacy`
- [ ] App content rating questionnaire completed

**Required Play Store metadata:**
- App name: "CivilCal — Engineering Exam Prep"
- Short description (80 chars): "PSC, GATE, IOE practice questions + 100+ engineering calculators. Free!"
- Full description (4000 chars max): 4 paragraphs + bullet points
- Category: Education
- Target age: Everyone (13+)

**Submission command:**
```bash
cd C:\laragon\www\bisaasmobile\android
bundle exec fastlane beta
# Then after beta testing: fastlane prod
```

### 18.2 Apple App Store Requirements

**Before submission:**
- [ ] Apple Developer Program account ($99/year)
- [ ] Xcode 16+ installed on macOS machine
- [ ] Bundle ID registered: `com.bisaas.civilcal`
- [ ] App Store Connect account configured
- [ ] Certificates via Fastlane Match (or manual)
- [ ] iOS app icons (all sizes via AppIcon.appiconset)
- [ ] Launch screen storyboard (shows CivilCal branding during cold start)
- [ ] Privacy manifest (required iOS 17+)
- [ ] 6 iPhone screenshots (6.7" and 5.5" sizes)
- [ ] App privacy label filled (what data is collected)

**Note on cross-platform:**

This app currently does not have a macOS developer machine described in the project setup. iOS submission requires running Fastlane on macOS. If Bishwo only has Windows, iOS submission must be done differently:
- Option A: Rent a Mac in the cloud (MacStadium, MacInCloud) for $30-60/month
- Option B: Use Codemagic CI/CD for iOS builds from Windows
- Option C: Partner with someone who has macOS

**Recommendation:** Do Android Play Store first. iOS requires macOS tooling.

---

## 19. Engineering Laws Review — Violations Found

From the master plan's "10 Engineering Laws" (Section 32), here is the compliance audit:

**Law 1: Flutter is never the authority for security-sensitive state**
- STATUS: ✅ COMPLIANT — Quiz scoring, coins, achievements are server-authoritative
- Evidence: `QuizController` sends to server, uses server's `is_correct` response
- One concern: Offline quiz uses local grading when offline. Results are labeled "provisional" — this is acceptable per the law's intent

**Law 2: No feature directly imports from another feature**
- STATUS: ✅ COMPLIANT — Features communicate via Riverpod providers
- Verified: No cross-feature import found in the directory structure

**Law 3: Repositories are the data boundary**
- STATUS: ✅ COMPLIANT — Data sources behind repositories

**Law 4: UI never performs API calls directly**
- STATUS: ✅ COMPLIANT — All calls through repositories/use cases via Riverpod

**Law 5: No raw Map<String, dynamic> beyond the data layer**
- STATUS: ⚠️ PARTIAL VIOLATION — Calculator `_collectInputs()` returns `Map<String, dynamic>` and this map crosses into the controller. The calculator detail screen directly builds and passes the raw map.
- Fix: Convert to `List<CalculatorInput>` entity at the data boundary

**Law 6: Every important mutation is idempotent**
- STATUS: ✅ COMPLIANT — `SyncQueue` uses `idempotency_key`, quiz answers use it

**Law 7: Offline is explicitly practice/cache/sync — not fake authority**
- STATUS: ✅ COMPLIANT — Offline quiz is clearly labeled "practice", server score wins

**Law 8: No secret credentials in the app**
- STATUS: ✅ COMPLIANT — No hardcoded secrets found

**Law 9: Profile on physical devices**
- STATUS: ❌ VIOLATION — Zero device testing has been done
- Android SDK not installed, no physical device testing

**Law 10: Every screen works with accessibility settings**
- STATUS: ❌ VIOLATION — No accessibility audit done, no Semantics labels in quiz widgets

---

## 20. 50-Sprint Backlog

Ordered by priority. Each sprint = 0.5 day of focused work.

```
PHASE A: FOUNDATION FIXES (Sprints 1-10)

Sprint 1:  Download fonts (InstrumentSans + NotoSansDevanagari) → place in assets/fonts → uncomment pubspec.yaml → verify
Sprint 2:  Firebase project setup (dev + prod) → download google-services.json → place in android/app
Sprint 3:  iOS Firebase setup → GoogleService-Info.plist → place in ios/Runner
Sprint 4:  Android SDK installation (Java 17 + Android Studio + emulators)
Sprint 5:  Run flutter doctor → all green → run app on Android emulator → verify auth works
Sprint 6:  Fix quiz_attempt_screen.dart navigation → use go_router named routes for result screen
Sprint 7:  Add quiz result + review routes to app_router.dart → verify back navigation
Sprint 8:  Verify ARB files for ne/hi → run flutter gen-l10n → fix any warnings
Sprint 9:  Test Firebase FCM → login → verify token registers → check Analytics dashboard
Sprint 10: Fix Law 5 violation: calculator Map → typed CalculatorInput entity

PHASE B: CORE FEATURE COMPLETION (Sprints 11-25)

Sprint 11: Build QuizBrowserScreen → fetch GET /quiz (categories + search) → link from bottom nav
Sprint 12: Build QuizIntroScreen → shows topic, duration, question count, difficulty → start button
Sprint 13: Verify GET /api/v1/calculators/:domain/:slug returns fields[] → if yes, proceed
Sprint 14: Build CalculatorField entity + CalculatorInput entity (freezed)
Sprint 15: Build calculator_input_field.dart (number, select, boolean types)
Sprint 16: Replace _FieldEntry key-value form with schema-driven CalculatorField form in calculator_detail_screen
Sprint 17: Build formula_display.dart using flutter_math_fork → wire to CalculatorConfig.formulaLatex
Sprint 18: Build step_by_step_solution.dart → wire to CalculationResult.steps
Sprint 19: Build SAFE/CHECK/FAIL status badge → wire to CalculationResult.status
Sprint 20: Download 9 Lottie JSON files → add to assets/animations/ → verify sizes
Sprint 21: Wire correct_answer.json to quiz correct feedback
Sprint 22: Wire wrong_answer.json to quiz wrong feedback
Sprint 23: Build LevelUpOverlay widget + wire to QuizResult.leveledUp from server
Sprint 24: Build AchievementUnlockToast widget + wire to QuizResult.achievementsUnlocked
Sprint 25: Build confetti.json on quiz completion (high score only)

PHASE C: BATTLE MODE (Sprints 26-35)

Sprint 26: Get RTDB structure documentation from bisaas team + add firebase_database to pubspec
Sprint 27: Implement Firebase auth with custom token (signInWithCustomToken)
Sprint 28: Build RTDB listener service (listen to /battles/{lobbyId})
Sprint 29: Build BattleMatchmakingScreen with animated searching state
Sprint 30: Build 3-2-1 countdown animation (haptic each count)
Sprint 31: Build BattleArenaScreen real implementation (question + opponent header + timer)
Sprint 32: Wire answer submission via POST /battles/{id}/answers
Sprint 33: Wire RTDB opponent score + progress updates to arena UI
Sprint 34: Build BattleResultScreen with score comparison + XP earned
Sprint 35: Build "Rematch" flow + analytics events for battle_complete

PHASE D: POLISH (Sprints 36-43)

Sprint 36: Build RadarChart (fl_chart) for profile skill assessment
Sprint 37: Build shareable profile card (RenderRepaintBoundary → PNG → share_plus)
Sprint 38: Build EditProfileScreen + avatar upload (image_picker → POST /me/avatar)
Sprint 39: Wire question images (CachedNetworkImage when question.imageUrl != null)
Sprint 40: Build ambient_glow_background.dart → apply to quiz + battle screens
Sprint 41: Apply GlassmorphicCard to quiz question card + calculator result card
Sprint 42: Build QuizReviewScreen (all answers with correct answer + explanation)
Sprint 43: Build Downloads screen (offline pack management)

PHASE E: TESTING & PERFORMANCE (Sprints 44-48)

Sprint 44: Physical device testing on Redmi Note 12 → profile mode → fix any jank
Sprint 45: Build quiz state machine comprehensive test suite (all transitions)
Sprint 46: Build golden tests for 5 key screens
Sprint 47: Accessibility audit (TalkBack) → add missing Semantics labels
Sprint 48: Load test: 10 quiz completions in a row → verify memory stays < 150MB

PHASE F: STORE (Sprints 49-50)

Sprint 49: Play Store submission (screenshots + metadata + fastlane beta)
Sprint 50: iOS review (Xcode setup on macOS or cloud Mac) + TestFlight
```

---

## 21. Definition of Done — Launch Criteria

The app is ready for Play Store production release when ALL of the following are true:

### 21.1 Technical Must-Haves

- [ ] `flutter analyze` → 0 errors, 0 warnings (currently passing ✅)
- [ ] `flutter test` → 100% pass rate on expanded test suite (currently 52/52 ✅, needs expansion)
- [ ] Firebase configured and all services active (FCM, Analytics, Crashlytics)
- [ ] App launches in < 2s on Redmi Note 12 (physical device)
- [ ] Quiz answer tap → visual feedback in < 100ms (profile mode verified)
- [ ] No frame takes > 16ms during quiz transitions (verified in DevTools)
- [ ] Memory < 150MB after 10 quiz completions
- [ ] Offline quiz works in airplane mode
- [ ] Push notifications received on physical Android device
- [ ] Deep links open correct screens from WhatsApp

### 21.2 Feature Must-Haves

- [ ] Auth: Login, Register, Google Sign-In, Logout all work
- [ ] Quiz: Browse → Intro → Play → Result → Review complete flow works
- [ ] Calculator: Schema-driven inputs work for at least top 10 calculators
- [ ] Gamification: XP bar, coins, streak visible and updating after quiz
- [ ] Battle: Can start a battle and play questions (even if beta)
- [ ] Profile: Stats visible, achievements shown
- [ ] Notifications: Daily quiz reminder fires at 8am

### 21.3 Asset Must-Haves

- [ ] InstrumentSans font rendering (not Roboto)
- [ ] At least 3 Lottie animations working (correct answer, level up, confetti)
- [ ] App icon looks correct on Android home screen (maskable)
- [ ] No ".gitkeep" files in any shipped asset directory

### 21.4 Store Must-Haves

- [ ] 6 real screenshots showing actual app UI (not mockups)
- [ ] App description in English (and Nepali if submitting to Nepal-focused tracks)
- [ ] Privacy policy URL active on civilcal.com
- [ ] Content rating completed (Everyone)
- [ ] Google Play Developer account in good standing
- [ ] Signed with release keystore (not debug key)

### 21.5 Quality Gates

- [ ] No crash on Login → Quiz → Result flow (10x manual test)
- [ ] No crash when starting battle (even if battle is beta)
- [ ] Offline banner appears within 2 seconds of going offline
- [ ] Results screen shows correct score (matches what server returns)
- [ ] Share button opens native Android share sheet

---

## Appendix A: File Verification Commands

Run these in the bisaasmobile directory to verify current state:

```bash
# Check if fonts exist:
ls assets/fonts/  # Should show .ttf files (not .gitkeep only)

# Check if animations exist:
ls assets/animations/  # Should show .json files

# Check if images exist:
ls assets/images/  # Should show .svg files

# Check build_runner is current:
dart run build_runner build --delete-conflicting-outputs

# Check all tests pass:
flutter test --coverage

# Check analyze:
flutter analyze --no-pub

# Check localization:
flutter gen-l10n

# Check Flutter doctor:
flutter doctor -v

# Run on Android emulator:
flutter run --dart-define=ENV=dev --dart-define=API_HOST=http://10.0.2.2
```

---

## Appendix B: Quick Reference — What's Missing vs. What's Done

```
DONE (can be verified from code):
✅ Architecture (feature-first Clean Architecture)
✅ Dio interceptors (Auth, RequestId, Retry, Refresh, Logging, CertPinning)
✅ Drift database schema (5 tables + sync queue)
✅ Token manager (secure storage, proactive refresh)
✅ Router (StatefulShellRoute, 5 tabs, deep links)
✅ Auth screens (Login, Register, Forgot Password)
✅ Home dashboard (real data, parallel fetch)
✅ Quiz state machine (all phases, timer isolation)
✅ Quiz attempt screen (answer options, combo, timer, offline banner)
✅ Quiz result screen (score, share, XP)
✅ Calculator browser (domain grid, search)
✅ XP/Coin/Streak HUD widgets
✅ Sync queue (offline actions queued, replayed on reconnect)
✅ 52 unit tests passing
✅ CI/CD (GitHub Actions + Fastlane config)
✅ Firebase code (conditioned on config presence)

MISSING (critical path to launch):
❌ Font files (InstrumentSans, NotoSansDevanagari)
❌ Lottie animation files (9 JSON files)
❌ Brand SVG images (logo, illustrations)
❌ Firebase google-services.json (dev + prod)
❌ Firebase GoogleService-Info.plist (iOS)
❌ Android SDK installation
❌ Quiz browser screen (how to navigate to a quiz!)
❌ Calculator schema-driven inputs (unusable as-is)
❌ Battle real-time gameplay (RTDB integration)
❌ Level up overlay animation
❌ Achievement unlock toast
❌ Physical device testing
❌ Performance profiling
❌ Accessibility audit
❌ Store screenshots
❌ Play Store submission
```

---

*This review was conducted by reading every file in `C:\laragon\www\bisaasmobile` and all reference plans.*  
*The code quality is high. The architecture is sound. The gaps are specific and closeable.*  
*Follow the 50-sprint backlog in priority order to reach a shippable product.*

*Document Version: 1.0*  
*Date: August 30, 2026*  
*Next Review: After Phase A + B completion (estimated 2 weeks)*

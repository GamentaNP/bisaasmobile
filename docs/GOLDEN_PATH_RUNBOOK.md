# Golden Path E2E Runbook — CivilCal v1.0

> **patrol** integration tests are deferred to Phase 6 per `AGENTS.md` (native plugins break
> `flutter build appbundle`). Until Phase 6, use this runbook for manual release smoke testing.
> When Phase 6 ships, implement these as `test/integration/golden_path_test.dart` with patrol.

## Prerequisites

- `google-services.json` + `GoogleService-Info.plist` present (Firebase provisioned)
- Backend: `https://bisaas.test` or `https://bisaas.com` reachable
- Device: Redmi Note 12 (Android 13, 4GB RAM) or emulator API 34
- Build: `flutter build apk --dart-define=ENV=dev` then `flutter install`

## Golden Path (manual checklist)

### 1. Launch
- [ ] App opens in <2s cold start (Firebase init is guarded, doesn't block)
- [ ] Splash → Onboarding OR Home (if already logged in)
- [ ] No crash on launch

### 2. Auth flow
- [ ] Register new account: `testN@bisaas.test` / `TestPass123!`
- [ ] Login with registered account
- [ ] Token persisted (restart app → stays logged in)
- [ ] Logout → token cleared → redirected to login

### 3. Home dashboard
- [ ] PlayerHUD shows `xp`, `level`, `coins`, `streak_days`
- [ ] Calculators section shows domain tiles
- [ ] Recent activity card appears

### 4. Quiz flagship (P0 — the critical path)
- [ ] Navigate to Quiz tab → subject list loads
- [ ] Select a subject → quiz questions appear (no 404)
- [ ] Answer 5 questions: option tap → immediate visual feedback
- [ ] Use a lifeline (50/50) → two options hidden
- [ ] Submit quiz → `POST /quiz/attempts/{id}/complete` succeeds
- [ ] Result screen shows server-graded score (not placeholder)
- [ ] Share button opens share sheet

### 5. Calculator
- [ ] Open Voltage Drop calculator
- [ ] Fill inputs → Calculate → result card shows
- [ ] No 404 or formula_latex error

### 6. Learning + EICE
- [ ] Navigate Learning tab → courses load
- [ ] Open a module → content renders
- [ ] EICE calendar shows scheduled items

### 7. Profile
- [ ] Edit name + save via `PATCH /me` → updates reflected
- [ ] Avatar upload succeeds

### 8. Economy / Gamification
- [ ] Wallet screen shows balance (not empty 404 placeholder since WO-1 shipped)
- [ ] Achievements screen loads (not empty since WO-4 shipped)
- [ ] Streak screen shows current streak

### 9. Notifications
- [ ] Notifications inbox loads (WO-8 shipped)
- [ ] Mark one as read

### 10. Account delete (store submission blocker)
- [ ] Settings → Delete Account → confirmation dialog → `DELETE /account` returns 200
- [ ] User is logged out after deletion

## Performance gates (Redmi Note 12, release build)
- Cold start (launch → home): **< 2s**
- Quiz question tap → answer feedback: **< 100ms** (UI instant, server 404 < 500ms)
- Frame time: **< 16ms** (60fps) — check via `flutter run --profile` + DevTools

## Security checklist (release build)
- [ ] `certificate_pinning.dart`: prodPins populated from `dart_defines/production.json`
- [ ] `app_security.dart`: freeRASP initialized (check logcat: `freeRASP started`)
- [ ] `encryption.dart`: AES-256 key present in Keystore (check via ADB or SecureStorage inspector)
- [ ] No token in SharedPreferences / plain files (only flutter_secure_storage)
- [ ] Screen capture blocked on sensitive screens (run `blockScreenCapture` verification)

## Release commands

```bash
# Build release AAB with production defines
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define-from-file=dart_defines/production.json \
  --dart-define=SIGNING_CERT_HASH=sha256/XXXXXXX \
  --dart-define=IOS_BUNDLE_ID=com.bisaas.bisaasmobile \
  --dart-define=IOS_TEAM_ID=XXXXXXXXXX \
  --dart-define=CERT_PIN_1=sha256/XXXXXXX \
  --dart-define=CERT_PIN_2=sha256/XXXXXXX  # backup pin

# Analyze size
flutter build appbundle --analyze-size --dart-define=ENV=prod \
  --dart-define-from-file=dart_defines/production.json

# Tag and deploy
git tag v1.0.0 -m "Internal Track release — 20/22 capabilities playable"
git push origin v1.0.0
# Then: fastlane android beta  (from android/ directory, requires PLAY_SERVICE_JSON secret)
```

## Phase 6 patrol E2E (deferred)

When Phase 6 ships, reintroduce patrol as a separate test harness (not in pubspec.yaml dev_dependencies
— use a dedicated `e2e/` package per flutter/flutter#92978). The golden path above becomes automated:

```dart
// e2e/test/golden_path_test.dart (Phase 6)
patrolTest(
  'golden path: launch → login → home → start quiz → answer 20 → lifeline → submit → result → share',
  ($) async {
    await $.pumpWidgetAndSettle(app);
    // ... patrol interactions
  },
);
```
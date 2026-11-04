# Golden Path E2E Runbook — CivilCal

> **Why this is still manual.** `patrol` is deliberately not used: its native
> plugin changes the release artifact, and `integration_test` would put
> Espresso inside the release AAB. Automation therefore lives in three other
> places — `test/integration/mobile_journey_e2e_test.dart` (the five-leg
> journey through the whole client stack), `device_tests/` (8 smoke tests on
> an emulator in CI plus the live-API test), and the golden-path checks below
> are the **human** pass for what none of those can see: real notification
> delivery, keyboard/IME behaviour, heat and battery, store-account state.

## Prerequisites

- `android/app/google-services.json` present — it is **gitignored**, so a
  fresh clone does not have it. Firebase features degrade gracefully without
  it; push and Crashlytics will not work.
- Backend reachable through the adb tunnel (see `README.md` §"Physical
  device — the adb-reverse tunnel"). `https://bisaas.com` is **not live** as
  of 2026-11-04 — see `LAUNCH_READINESS.md`.
- Device: the QA phone is a **Redmi 6A, Android 9 (API 28)**. CI also runs
  API 30. An API-34 emulator is fine for a quick pass but is not the floor.
- Build for the phone:
  ```bash
  flutter build apk --debug --dart-define=ENV=dev \
    --dart-define=API_HOST=https://localhost:8443
  adb install -r build/app/outputs/flutter-apk/app-debug.apk
  adb reverse tcp:8443 tcp:443   # re-assert after every install
  ```

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
- [ ] Submit quiz → `PUT /quiz/attempts/{id}/completion` succeeds (`/complete` is a legacy alias)
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

## Performance gates (Redmi 6A, release build)
- Cold start (launch → home): **< 2s**
- Quiz question tap → answer feedback: **< 100ms** (UI immediate; the graded response is a server round trip)
- Frame time: **< 16ms** (60fps) — check via `flutter run --profile` + DevTools

## Security checklist (release build)
- [ ] `certificate_pinning.dart`: `prodPins` populated from `dart_defines/production.json`; the build starts at all (it refuses to otherwise)
- [ ] `app_security.dart`: freeRASP initialised (logcat: `freeRASP started`)
- [ ] `encryption.dart`: AES-256 key present in the Keystore
- [ ] No token in SharedPreferences or plain files — only `flutter_secure_storage`
- [ ] Screen capture blocked on sensitive screens

## Release commands

```bash
# production.json already carries SIGNING_CERT_HASH, CERT_PIN_1/2 and the
# bundle/team ids. Do NOT pass placeholder overrides: Gradle's isUsablePin
# rejects "XXXXXXX" and refuses the build — measured, not theoretical.
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define-from-file=dart_defines/production.json \
  --obfuscate --split-debug-info=build/symbols

# Analyze size
flutter build appbundle --analyze-size --dart-define=ENV=prod \
  --dart-define-from-file=dart_defines/production.json

# Tag and deploy (tags are the only push that builds a publishable artifact)
git tag v1.0.2 -m "Internal track — 1.0.2+2"
git push origin v1.0.2
# Then: fastlane android beta (from android/, requires the Play service account)
```

**Do not tag before the domain/TLS step in `LAUNCH_READINESS.md` is done.**
The pins in `production.json` are only valid for the certificate the domain
actually serves; a stale pin makes the release refuse every request.
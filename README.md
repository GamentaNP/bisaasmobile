# bisaasmobile — CivilCal Flutter Client (Android • iOS)

> **Flutter client for the BiSaaS / CivilCal ecosystem.**
> This repo is the **mobile surface only**. The server of record is `C:\laragon\www\bisaas` (Laravel 13 + Filament 5 + Inertia). See `AGENTS.md` for the boundary rule.

## Where things live

| Path | What | Owner |
|------|------|-------|
| `C:\laragon\www\bisaas` | Laravel web + Filament admin + `GET /api/v1/*` | Server — all business logic (grading, coins, leaderboards, fraud, subscriptions) |
| `C:\laragon\www\bisaasmobile` | Flutter app (this repo) | Client — pixels, animations, offline queue, push |
| `C:\laragon\www\bisaas\docs\mobileapp` | Master plans (Flutter, PWA, Social Proof Engine) | Spec — SSOT for architecture |
| `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md` | Auth flow, envelope, error codes, pagination, push | Contract — frozen per `2026.08` |

**Rule:** Flutter never computes what the server owns. Offline mode queues intent and reconciles on reconnect — it never finalizes a grade or mints a coin.

## Stack

Flutter **3.47.2** (stable, `C:\src\flutter`) · Dart **3.13.2** · Riverpod + go_router + Dio + Drift + flutter_secure_storage · Firebase (FCM/Analytics/Crashlytics). **Remote Config is not used** — it was removed because it disagreed with the operator's flags; operator control runs through `GET /api/v1/app/config` (feature flags, maintenance, min-version floor). See `pubspec.yaml` and `.metadata` for pins.

## API contract (read before you code)

- **BasePath = `/api/v1` only** — `lib/app/config/api_config.dart:4`. No header negotiation, no unversioned paths.
- **Headers:** `Accept: application/json` always + `Accept-Language` for i18n. 429 respects `Retry-After`; log `X-Request-Id`.
- **Envelope:** `{success, data, message, pagination, timestamp, api_version}` → `lib/core/network/api_response.dart:12`.
- **Errors:** `ApiErrorCode` mirrors `App\Http\Support\ApiErrorCode` — `lib/core/network/api_exception.dart:8`. Unknown codes → generic.
- **Auth:** `POST /api/v1/auth/login` → bearer PAT stored in Keychain/Keystore via `TokenManager` (`lib/core/security/token_manager.dart:16`). Never `SharedPreferences`.
- **Refresh:** When `expires_at < 7d`, `POST /api/v1/auth/refresh` with `X-Device-Name` (single-use rotation, persist atomically). Any 401 → logout.
- **Idempotency:** `Idempotency-Key: <uuid>` on `POST /quiz/attempts/start`, purchases, etc.

Full catalog: `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md:125` · live spec: `GET /api/v1/openapi.json`.

### Backend URLs

**Cleartext HTTP is blocked in every build — including debug** (`network_security_config.xml`, W2.6). Plain `http://…` will never connect from Android, no matter the define. Use the https forms below; debug builds carry a dev-only certificate shim that tolerates Laragon's self-signed cert for the allowed dev hosts.

| Target | Host | Command |
|--------|------|----------|
| Chrome / Windows desktop (dev) | `https://bisaas.test` | `--dart-define=ENV=dev` (default) |
| Android emulator (dev) | `https://10.0.2.2` | `--dart-define=API_HOST=https://10.0.2.2 --dart-define=ENV=dev` |
| **Physical Android device (dev)** | `https://localhost:8443` | `--dart-define=API_HOST=https://localhost:8443 --dart-define=ENV=dev` **plus `adb reverse tcp:8443 tcp:443`** |
| staging | `https://staging.bisaas.com` | `--dart-define=ENV=staging` |
| prod | `https://bisaas.com` | `--dart-define=ENV=prod` |

Override raw: `--dart-define=API_BASE_URL=https://x/api/v1`.

### Physical device — the adb-reverse tunnel (this is the step everyone skips)

**0. The backend must actually be running.** The app cannot work without the
Laravel server: open **Laragon → Start All** (Apache + PostgreSQL), then verify
with `curl -sk https://bisaas.test/api/v1/app/config` → expect `"success":true`.
If Apache keeps dying, start it detached:
`powershell Start-Process C:\laragon\bin\apache\httpd-2.4.68-260617-Win64-VS18\bin\httpd.exe -ArgumentList '-d','C:/laragon/bin/apache/httpd-2.4.68-260617-Win64-VS18' -WindowStyle Hidden`.

**0b. The default :443 vhost must serve the bisaas app.** The tunnel arrives
with SNI `localhost`, which matches no `auto.*.test` vhost name and lands on
`C:\laragon\etc\apache2\sites-enabled\00-default.conf`'s `_default_:443` block —
it must contain `DocumentRoot "C:/laragon/www/bisaas/public"`. That file lives
**outside** both repos (Laragon's own config, hand-maintained — nothing
re-creates the fix if it regresses). If the phone gets a plain Apache **404**,
this is why; verify with
`curl -sk --resolve localhost:443:127.0.0.1 https://localhost/api/v1/app/config`.

`bisaas.test` does not resolve on a phone and cleartext is blocked, so a debug
build on a physical device reaches the Laragon backend through a **localhost
HTTPS tunnel**:

```powershell
# 1. Build with the tunnel host baked in (debug only — never point a release at Laragon)
flutter build apk --debug --dart-define=ENV=dev --dart-define=API_HOST=https://localhost:8443

# 2. Install
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# 3. Re-assert the tunnel — installing, rebooting, replugging or an adb-server
#    restart CLEARS it. If login says "Could not reach the server", run this first.
adb reverse tcp:8443 tcp:443
```

The phone's `https://localhost:8443` then lands on the host's Apache :443,
whose default vhost answers `localhost` with Laragon's cert — which the debug
cert shim accepts (dev env only; the shim is compiled out of release/profile
builds).

MIUI gotchas (Redmi 6A and friends):
- Settings → Developer options → **"Install via USB"** and **"USB debugging
  (Security settings)"** must both be on, or MIUI silently refuses adb installs
  (`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`, **no dialog on
  screen** — MIUI resets these toggles after security sweeps/updates, so if
  installs suddenly stop working, check them first).
- **Wi-Fi-transport adb silently breaks `adb reverse`** — the mapping looks
  listed but no listener works. Verify `adb devices -l` shows a `usb:` marker
  (`adb -s SERIAL usb` forces it).
- With reverse working, the listener lives **on the phone** — a host-side
  `curl https://127.0.0.1:8443` always fails with exit 7 and proves nothing.
- MIUI also needs ~1.5–3 GB free for a debug install; the debug APK is ~265 MB
  (all four ABIs — the release APK is ~95 MB, arm-only) and odex expansion needs
  headroom (`adb shell dumpsys diskstats` → Data-Free).

Dev login fixtures (local-only seeder `bisaas/database/seeders/LocalTestUserSeeder.php`):
`user@bisaas.test` / `BisaasLocal!2026`, email verified.

## Project structure (Clean Arch + feature-first)

```
lib/
  main.dart                 — minimal, calls bootstrap()
  app/
    bootstrap.dart          — Dio + SecureStorage init
    config/env.dart        — flavor → host
    config/api_config.dart  — baseUrl + timeouts + headers
    router/app_router.dart  — go_router + auth guard + deep links
    theme/app_colors.dart / app_theme.dart — Material 3 (seed #22D3EE)
  core/
    network/dio_client.dart + auth_interceptor.dart + api_response/exception.dart
    security/token_manager.dart — Keychain/Keystore
    storage/  errors/  analytics/  logging/  connectivity/  sync/
  features/
    auth/  quiz/  calculator/  gamification/  battle/  social/ ...
```

From `FLUTTER_APP_MASTER_PLAN_2026.md:212`. Features never import each other — communicate via Riverpod or router.

## Getting started (Windows 11)

### Prereqs already done in this setup

- Flutter SDK **3.47.2** at `C:\src\flutter` on user `PATH` (restart shell after first install, or ` $env:Path = "C:\src\flutter\bin;$env:Path"` for current shell).
- `flutter doctor`: **fully green** ("No issues found!") — Android SDK 36 at `C:\Users\Bishwo\AppData\Local\Android\Sdk`, Temurin JDK 17, licences accepted. If the machine's global `ANDROID_HOME` points at a dead path, override it per-shell.

### Complete the Android toolchain (one-time, ~2 GB, needs admin)

```powershell
# JDK 17 (required by Android Gradle plugin)
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements

# Android Studio (installs SDK + platform-tools + emulator)
winget install --id Google.AndroidStudio -e --accept-package-agreements
# Open Android Studio → SDK Manager → SDK Platforms: API 34 + 35
#                              → SDK Tools: Android SDK Build-Tools, Platform-Tools, Emulator
flutter doctor --android-licenses   # accept all
flutter doctor -v                   # should become [√] Android toolchain
```

Minimal CLI alternative (no Studio UI): `https://developer.android.com/studio#command-tools` → unzip to `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest` → `sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"`.

Windows desktop (optional): install Visual Studio 2022 with **Desktop development with C++**.

### Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after changing the Drift schema
flutter analyze && flutter test

flutter run -d chrome  --dart-define=ENV=dev               # web vs bisaas.test
flutter run -d windows --dart-define=ENV=dev               # windows
# emulator can't resolve bisaas.test and http is blocked → use:
flutter run -d android --dart-define=API_HOST=https://10.0.2.2 --dart-define=ENV=dev
# physical device → build + install via the tunnel recipe in the section above
```

Build:

```bash
# dev/debug APK for a physical device (tunnel define — see section above)
flutter build apk --debug --dart-define=ENV=dev --dart-define=API_HOST=https://localhost:8443

# release/prod builds fail CLOSED without signing material + cert pins
# (android/key.properties + CERT_PIN_1/2 in dart_defines/production.json — both checked in CI):
flutter build apk       --release --dart-define-from-file=dart_defines/production.json --obfuscate --split-debug-info=build/symbols
flutter build appbundle --release --dart-define-from-file=dart_defines/production.json --obfuscate --split-debug-info=build/symbols
flutter build web   --dart-define-from-file=dart_defines/production.json
flutter build windows --dart-define=ENV=prod --dart-define-from-file=dart_defines/production.json
```

## Device tests (on a real phone)

`device_tests/` is its own package (it depends on `integration_test`, which must
never leak into the app's release AAB):

```bash
cd device_tests && flutter pub get && flutter analyze
cd device_tests && flutter test integration_test -d DEVICE_ID
```

The suite boots the real app stack on the phone (engine, plugins, platform
channels, navigation) and runs 7 smoke tests + 1 live-API test gated behind
`RUN_LIVE_TESTS`. After any install, re-assert `adb reverse tcp:8443 tcp:443`
first — the live test talks to the backend through the same tunnel.

## AI-agent checklist

1. Read `AGENTS.md` in this repo **and** `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md` before any endpoint work.
2. Verify the route in OpenAPI — don't invent ` /api/...`.
3. Import URL/host only from `ApiConfig` — never string-concatenate in a feature.
4. Store tokens only via `TokenManager`; never `SharedPreferences`.
5. Handle `429` (`Retry-After`), `401` (refresh-or-logout), and envelope errors uniformly.

## Links

- Flutter install: `C:\src\flutter` · `flutter doctor -v` · `flutter --version`
- Bisaas backend: `C:\laragon\www\bisaas` (`php artisan serve` / Laragon Apache → `http://bisaas.test`)
- Master plan: `C:\laragon\www\bisaas\docs\mobileapp\FLUTTER_APP_MASTER_PLAN_2026.md`
- Research pack: `C:\laragon\www\bisaas\docs\mobileapp\mobileapp-design-reserch-flutter.md`
- Social Proof Engine: `C:\laragon\www\bisaas\docs\mobileapp\SOCIAL_PROOF_REFERRAL_ACHIEVEMENT_ENGINE_MASTER_PLAN.md`

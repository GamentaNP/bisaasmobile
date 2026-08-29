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

Flutter **3.47.2** (stable, `C:\src\flutter`) · Dart **3.13.2** · Riverpod + go_router + Dio + Drift + flutter_secure_storage · Firebase (FCM/Analytics/Crashlytics/RemoteConfig). See `pubspec.yaml` and `.metadata` for pins.

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

| Flavor | Host | Run flag |
|--------|------|----------|
| dev (Laragon) | `http://bisaas.test` | `--dart-define=ENV=dev` (default) |
| dev Android emulator | `http://10.0.2.2` | `--dart-define=API_HOST=http://10.0.2.2` |
| staging | `https://staging.bisaas.com` | `--dart-define=ENV=staging` |
| prod | `https://bisaas.com` | `--dart-define=ENV=prod` |

Override raw: `--dart-define=API_BASE_URL=https://x/api/v1`.

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
- `flutter doctor` baseline: `[√] Flutter, [√] Chrome, [X] Android toolchain, [X] Visual Studio` — see `flutter doctor -v`.

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
dart run build_runner build --delete-conflicting-outputs   # after freezed/json/drift changes
flutter analyze && flutter test

flutter run -d chrome  --dart-define=ENV=dev               # web vs bisaas.test
flutter run -d windows --dart-define=ENV=dev               # windows
flutter run -d android --dart-define=ENV=dev               # needs Android SDK (above)
# emulator can't resolve bisaas.test → use:
flutter run -d android --dart-define=API_HOST=http://10.0.2.2 --dart-define=ENV=dev
```

Build:

```bash
flutter build apk --dart-define=ENV=prod
flutter build appbundle --dart-define=ENV=prod
flutter build web --dart-define=ENV=prod
flutter build windows --dart-define=ENV=prod
```

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

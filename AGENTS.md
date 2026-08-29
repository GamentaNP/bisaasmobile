# AGENTS.md — bisaasmobile (Flutter Android / iOS Client)

> **Scope:** This file governs ONLY `C:\laragon\www\bisaasmobile` — the Flutter client.
> Web + Admin panel lives at `C:\laragon\www\bisaas`. Never mix them.

## Boundary Rule (non-negotiable)

```
C:\laragon\www\bisaas\*                 = Laravel 13 web + Filament admin + API server. Source of truth for ALL business logic.
C:\laragon\www\bisaasmobile\*           = Flutter client. Owns ONLY pixels, animations, local state, offline queue, push handling.
C:\laragon\www\bisaas\docs\mobileapp\*  = Canonical mobile specs (master plans, API guide). Client MUST stay faithful to them.
```

Flutter **never** grades quizzes, mints coins, unlocks achievements, ranks leaderboards, detects fraud, or validates subscriptions locally — those are server-authoritative via `C:\laragon\www\bisaas` (`/api/v1`).

If a rule conflicts between `bisaas` and `bisaasmobile`, `bisaas` wins for API contract, `bisaasmobile` wins for Flutter idioms — but the file system boundary never blurs.

## API Contract — versioned, never drift

- **BasePath = `/api/v1` only.** No header negotiation. No unversioned `/api/...` calls. See `lib/app/config/api_config.dart:4`.
- **Always send `Accept: application/json`** + `Accept-Language` when localized. Without it, error bodies may be HTML/Inertia.
- **Envelope:** `{success, data, message, pagination, timestamp, api_version}` — see `docs/MOBILE_API_INTEGRATION_GUIDE.md:73` and `lib/core/network/api_response.dart:12`.
- **Error codes:** `ApiErrorCode` registry (`App\Http\Support\ApiErrorCode` on server, mirrored in `lib/core/network/api_exception.dart:8`). Treat unknowns as generic.
- **Auth:** Bearer PAT from `POST /api/v1/auth/login` (or register/social). Stored ONLY in `flutter_secure_storage` via `lib/core/security/token_manager.dart:16`, never SharedPreferences.
- **Refresh:** Proactive when `expires_at < 7 days` → `POST /api/v1/auth/refresh` with `X-Device-Name` (single-use rotation; persist new token atomically).
- **Idempotency:** `Idempotency-Key: <uuid>` on POSTs that must not double-fire (attempt start, purchases). Client retries must reuse the same key.
- **Streaming:** Day-one client uses **non-streaming** AI endpoints (`POST /learning/tutor`). SSE (`/learning/tutor/stream`) is web-only until mobile demand is proven.
- **Push:** Register FCM after login → `POST /api/v1/device-tokens {token, platform}`; delete on logout.

Full catalog: `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md:125` and OpenAPI at `GET /api/v1/openapi.json` + `/api/v1/quiz/openapi.json`.

## Local backend reference

- Default dev backend: `http://bisaas.test` (Laragon + PostgreSQL) — see `lib/app/config/env.dart:18`. Chrome/web can hit it directly; Android emulator must use `http://10.0.2.2` mapping.
- Production: `https://bisaas.com` (or whatever `APP_URL` is on the server). Never hardcode hosts in features — import from `ApiConfig`.
- **Do not** add `/api/v1` twice: `ApiConfig.baseUrl` already ends with `/api/v1`.

## Flutter stack pins (keep in sync with pubspec.yaml)

Dart ^3.13.2 / Flutter >=3.27.0 / Riverpod + go_router + Dio + Drift + flutter_secure_storage. Run `flutter pub get` after any pubspec edit; run `dart run build_runner build --delete-conflicting-outputs` when touching `freezed`/`json_serializable`/`riverpod_generator`/`drift`.

## Architecture (from `FLUTTER_APP_MASTER_PLAN_2026.md:140`)

Clean Architecture, feature-first:

```
lib/
  app/        — app.dart, bootstrap.dart, router/, theme/, config/, localization/
  core/       — network/, storage/, security/, errors/, analytics/, logging/, connectivity/, sync/
  features/   — auth/, quiz/, calculator/, gamification/, battle/, social/, ...
  shared/     — reusable UI
```

Rules:
- `features/` never import each other directly — communicate via Riverpod providers or router.
- `domain/` entities are pure Dart (no Flutter).
- `data/` owns DTO + Dio + Drift; `presentation/` owns screens/widgets/providers.

## AI-agent hygiene

- Before adding an endpoint, verify it exists in `MOBILE_API_INTEGRATION_GUIDE.md` or OpenAPI — do not invent routes.
- Before adding a calculation, confirm the backend is source of truth — do not duplicate calculator math on-device except for offline preview (and then reconcile with server on sync).
- Every network call honors `X-Request-Id` logging, `X-RateLimit-*` backoff, and `Retry-After` on 429.
- No `env()`-style secrets in committed code; flavor config lives in `lib/app/config/env.dart` + `--dart-define`.

## Runbook

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome --dart-define=ENV=dev        # web against bisaas.test
flutter run -d windows --dart-define=ENV=dev
flutter run -d android --dart-define=ENV=dev       # needs Android SDK (see below)
```

## Android toolchain (Windows 11)

Flutter SDK is at `C:\src\flutter` (stable 3.47.2, Dart 3.13.2, added to user PATH). Android SDK not yet installed in this shell — `flutter doctor` shows `Android toolchain: X`.

Install path (winget, requires admin + ~2 GB + reboot of shell):

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements
winget install --id Google.AndroidStudio -e --accept-package-agreements
# then in Android Studio: SDK Manager -> SDK Platforms (API 34, 35) + SDK Tools (Platform-tools, Build-tools)
flutter doctor --android-licenses
flutter doctor -v   # should become [√] Android toolchain
```

Or minimal CLI tools: `https://developer.android.com/studio#command-tools` → unzip to `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest` → `sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"`.

Visual Studio (Windows desktop) likewise needs `Desktop development with C++` workload for `flutter build windows`.

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

Dart ^3.13.2 / Flutter >=3.27.0 / Riverpod + go_router + Dio + Drift + flutter_secure_storage. Run `flutter pub get` after any pubspec edit.

**Codegen:** the *only* generated file is `lib/core/storage/database/app_database.g.dart` (Drift). Run `dart run build_runner build --delete-conflicting-outputs` when touching the Drift schema in `app_database.dart`, and nothing else. The `freezed` / `json_serializable` / `riverpod_generator` chain was removed on 2026-09-28 as dead weight — there are zero `@freezed`, `@JsonSerializable` and `@riverpod` annotations in the tree, every DTO hand-writes `fromJson`, and every provider is hand-written. Do not reintroduce it without a real reason; if you do add codegen, also add the matching `pubspec` deps and a `build.yaml`.

**Entry points:** `lib/main.dart` is the only entry point. Environment is selected with `--dart-define=ENV=dev|staging|prod`, not by separate `main_*.dart` files (the byte-identical `main_dev`/`main_prod`/`main_staging` copies were deleted as misleading on 2026-09-28).

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
flutter gen-l10n                                   # after any *.arb edit (CI runs this too)
flutter analyze
flutter test
flutter run -d chrome --dart-define=ENV=dev        # web against bisaas.test
flutter run -d windows --dart-define=ENV=dev
flutter run -d android --dart-define=ENV=dev       # needs Android SDK (see below)
```

Wiring notes (verified 2026-09-27 by an on-device run):

- **Cleartext is blocked in EVERY build — including debug.** The claim that
  `android/app/src/debug/AndroidManifest.xml` enables plain http is **wrong**: the debug manifest
  does set `usesCleartextTraffic="true"`, but `src/main/AndroidManifest.xml:14` sets
  `android:networkSecurityConfig`, and that attribute **overrides** `usesCleartextTraffic`.
  `res/xml/network_security_config.xml` has `base-config cleartextTrafficPermitted="false"`, so
  `API_HOST=http://…` will not work anywhere. Release builds additionally keep strict TLS plus
  optional pinning (`CertificatePinning.prodPins`).
- **Reaching a local Laragon backend from a device — use HTTPS over an adb tunnel.** `bisaas.test`
  does not resolve on a phone. Laragon's vhost
  (`C:\laragon\etc\apache2\sites-enabled\auto.bisaas.test.conf`) already has `localhost` in
  `ServerAlias`, and `dio_client.dart:73-82` tolerates Laragon's self-signed cert for `localhost`
  **only when `kDebugMode && currentEnv().isDev`**. So:

  ```powershell
  adb reverse tcp:8443 tcp:443    # 443 itself is refused: "cannot bind listener: Permission denied"
  flutter build apk --debug --dart-define=API_HOST=https://localhost:8443
  adb install -r build\app\outputs\flutter-apk\app-debug.apk
  adb reverse tcp:8443 tcp:443    # re-assert — install and reboot clear it
  ```

  Never point a release/profile build at Laragon: the cert shim is compiled out of non-debug
  builds by design, so the self-signed cert is rejected.
- **minSdk is 28** (lowered from 29 on 2026-09-27 so the physical QA device, a Redmi 6A on
  Android 9, can install). Flutter's engine for 3.47.2 references the API-34 type
  `UiModeManager.ContrastChangeListener` from its accessibility bridge, so **TalkBack does not work
  on API 28–33** — the engine catches the `NoClassDefFoundError` and disables the bridge. The app
  itself runs fine. See `docs/MOBILE_REMAINING_WORK_2026-09-27.md` §3 item V.
- **Firebase is active.** `android/app/google-services.json` exists (project
  `bisaas-realtime-123`), so the conditional google-services Gradle plugin applies and FCM /
  Crashlytics / Analytics / Remote Config are live. Without Play Services reachable,
  `firebase_messaging.getToken()` throws an **unhandled** `PlatformDispatcher` exception on every
  login — `push_notification_service.dart:55` needs a guard.
- **Deep links:** `civilcal://` + `https://bisaas.com` are registered on Android
  (intent-filters) and iOS (`CFBundleURLTypes`); runtime routing via `app_links` →
  `DeepLinkHandler.parse` in `app.dart`. App-Link verification on bisaas.com needs
  `/.well-known/assetlinks.json` (still unpublished).
- **Token refresh:** `RefreshInterceptor` is registered on the Dio chain (401 → single-use
  rotation → replay with `skipAuthRefresh` guard); `RetryInterceptor` never replays
  non-idempotent POSTs unless an `Idempotency-Key` header is present.

## Android toolchain (Windows 11) — INSTALLED

Flutter SDK is at `C:\src\flutter` (stable 3.47.2, Dart 3.13.2, on user PATH).

**As of 2026-09-27 the Android toolchain is installed and `flutter doctor` reports
"No issues found!"** — Android SDK 36.0.0 at `C:\Users\Bishwo\AppData\Local\Android\Sdk`,
build-tools 36.0.0, `platforms;android-37.0`, emulator 37.1.11.0, Temurin JDK 17.0.20.1,
all Android licences accepted. `compileSdk = 37`, `targetSdk = 36`.

Do **not** re-run the install steps below; they are kept only as a recovery reference for a
fresh machine.

<details>
<summary>Recovery install path (winget, admin, ~2 GB)</summary>

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements
winget install --id Google.AndroidStudio -e --accept-package-agreements
# then in Android Studio: SDK Manager -> SDK Platforms + SDK Tools (Platform-tools, Build-tools)
flutter doctor --android-licenses
flutter doctor -v
```

</details>

Or minimal CLI tools: `https://developer.android.com/studio#command-tools` → unzip to
`%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest` → `sdkmanager "platform-tools" "platforms;android-37.0" "build-tools;36.0.0"`.

Visual Studio (Windows desktop) likewise needs `Desktop development with C++` workload for `flutter build windows`.

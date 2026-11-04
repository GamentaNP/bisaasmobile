# Firebase — what is actually provisioned

**Verified 2026-11-04.** One Firebase project, one Android config file, no
flavours and no Remote Config. This file replaces the two-project / three-
flavour setup it used to describe, which never matched the tree.

| Fact | Value |
|---|---|
| Project | **`bisaas-realtime-123`** (single project for all environments) |
| Android package | `com.bisaas.bisaasmobile` |
| Android config | `android/app/google-services.json` — **gitignored**, present only on the founder's machine |
| iOS bundle | `com.bisaas.bisaasmobile` |
| iOS config | `ios/Runner/GoogleService-Info.plist` — gitignored |
| Gradle plugin | applied **conditionally** when the config file exists (`android/app/build.gradle.kts:16`) |
| Services in use | Analytics, Crashlytics, Cloud Messaging, Realtime Database |
| **Not** in use | **Remote Config** — removed on purpose. It disagreed with the operator's flags; feature flags, maintenance and the min-version floor come from `GET /api/v1/app/config`. |

## Consequences of the config being gitignored

A fresh clone — and **every CI run** — has no Firebase config. That is
deliberate and handled:

- `lib/app/bootstrap.dart` short-circuits `Firebase.initializeApp()`; the app
  runs, and every local path (quiz, calculator, library, settings) works.
- Push registration, Analytics, Crashlytics and the RTDB battle path are
  disabled in that state. CI's device tests therefore assert the *graceful
  absence* path, not push delivery. Push must be verified on a machine that
  has the config file (the Redmi 6A run does).
- A release built without the config file is not publishable: push would be
  dead for every user. Check `android/app/google-services.json` exists before
  building a store artifact.

## Android registration (when the file must be regenerated)

1. Firebase Console → project `bisaas-realtime-123` → Add app → Android →
   package `com.bisaas.bisaasmobile`.
2. Add the **release** SHA-1/SHA-256 from the upload keystore (Play App
   Signing re-signs the artifact, so also add the app-signing SHA-1 from Play
   Console once enrolled — Google Sign-In and Dynamic Links fail without it).
3. Download `google-services.json` into `android/app/`. Do not commit it.

## iOS registration

1. Add app → iOS → bundle `com.bisaas.bisaasmobile`.
2. Download `GoogleService-Info.plist` into `ios/Runner/` and add it to the
   Runner target in Xcode (drag into the project, "Copy items if needed").
3. Upload an APNs auth key (Cloud Messaging → iOS configuration). Without it,
   push to iOS silently fails.

## Realtime Database rules (battle)

```json
{
  "rules": {
    "battles": {
      "$lobbyId": {
        ".read": "auth != null",
        ".write": false
      }
    }
  }
}
```

Clients **read** lobby state; every write comes from the server through the
Admin SDK. Keep `.write: false` — a client that can write to a lobby can fake
a battle result.

## Verify

```bash
flutter pub get
# emulator, with the backend reachable over TLS
flutter run --dart-define=ENV=dev --dart-define=API_HOST=https://10.0.2.2

# on login, the app registers the device:
#   POST /api/v1/device-tokens {token, platform}
# then send a test push from Console → Engage → Cloud Messaging
```

A cleartext `http://` host will not connect at all — see `README.md`.

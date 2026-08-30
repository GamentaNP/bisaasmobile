# Firebase Setup — Bisaasmobile (CivilCal)

> **Status (2026-08-30):** Setup script generated. Real `google-services.json` and `GoogleService-Info.plist` are **gitignored** — see `C:\laragon\www\bisaasmobile\.gitignore`. The bootstrap in `lib/app/bootstrap.dart` no-ops safely if Firebase is not initialised so dev builds still run.

## 1. Create Firebase Projects

Create **two** Firebase projects (dev / prod):

| Env | Project ID | Console URL |
|---|---|---|
| Dev | `civilcal-dev` | https://console.firebase.google.com/project/civilcal-dev |
| Prod | `civilcal-prod` | https://console.firebase.google.com/project/civilcal-prod |

## 2. Android

### 2.1 Register Android App (both projects)
- Package name: `com.bisaas.civilcal`
- Debug SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
- Release SHA-1: from Fastlane keystore

### 2.2 Download `google-services.json`
- Dev → `android/app/google-services-dev.json`
- Prod → `android/app/google-services-prod.json`

### 2.3 Wire flavor switching in `android/app/build.gradle.kts`
Already wired via the `flutter.dev` / `flutter.staging` / `flutter.prod` flavors. The Gradle plugin uses `apply plugin: "com.google.gms.google-services"` and the file is referenced via the flavor's source set in `android/app/src/{dev,staging,prod}/google-services.json`. See `C:\laragon\www\bisaasmobile\android\app\build.gradle.kts` for the current wiring.

## 3. iOS

### 3.1 Register iOS App
- Bundle ID: `com.bisaas.civilcal`
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/GoogleService-Info.plist` (gitignored)
- Open `ios/Runner.xcworkspace` in Xcode and add the plist to the Runner target

## 4. Enable Firebase Services

In both projects, enable:
- **Analytics** — auto + custom events (already wired in `AnalyticsService`)
- **Crashlytics** — required for crash reporting
- **Cloud Messaging (FCM)** — required for push; upload APNs key for iOS
- **Remote Config** — define keys: `force_update_min_version`, `feature_eice_enabled`, `feature_battle_enabled`
- **Realtime Database** — required for Battle mode (see `C:\laragon\www\bisaas\docs\mobileapp\RTDB_BATTLE_SCHEMA.md`)

## 5. RTDB Security Rules (Battle Mode)

```json
{
  "rules": {
    "battles": {
      "$lobbyId": {
        ".read": "auth != null",
        ".write": false,
        "player1": { ".read": "auth != null" },
        "player2": { ".read": "auth != null" }
      }
    }
  }
}
```

**Rule:** clients NEVER write to RTDB. Server (Firebase Admin SDK) handles all writes.

## 6. Verify

After the config files are in place:

```bash
cd C:\laragon\www\bisaasmobile
flutter pub get
flutter run --dart-define=ENV=dev --dart-define=API_HOST=http://10.0.2.2
# On login, verify the app posts to POST /api/v1/device-tokens
# In Firebase Console → Engage → Cloud Messaging, send a test push
```

## 7. Local Dev Without Firebase

If `google-services.json` is absent, `lib/app/bootstrap.dart` short-circuits `Firebase.initializeApp()`. The app still works for offline quiz practice, calculator, and any other local-only path. Push, Analytics, Crashlytics, RemoteConfig, and Battle mode are all disabled in this state.

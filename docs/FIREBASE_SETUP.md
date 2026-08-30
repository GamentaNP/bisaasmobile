# Firebase Setup — bisaasmobile

This repo is wired for Firebase (FCM + Analytics + Crashlytics + Remote Config) via pubspec
(`firebase_core`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics`,
`firebase_remote_config`), but no native config is committed.

## How activation works

- **Android:** `android/app/build.gradle.kts` applies `com.google.gms.google-services`
  (declared in `android/settings.gradle.kts`) **only when `google-services.json` exists**
  next to it. Without the JSON, builds succeed and every Firebase call is guarded
  (`bootstrap.dart` try/catch + `Firebase.apps.isNotEmpty` checks).
- **iOS:** drop `GoogleService-Info.plist` into `ios/Runner/` and add it to the Xcode
  project (Runner target) so it ships in the bundle.

## Add native config (one-time)

1. Firebase Console → Add project (or reuse the existing `bisaas-…` project — the Laravel
   side keeps `storage/app/firebase/…-adminsdk.json`).
2. Add Android app: package `com.bisaas.bisaasmobile`, download `google-services.json`, place at:
   `android/app/google-services.json` (gitignored — never commit).
3. Add iOS app: bundle `com.bisaas.bisaasmobile`, download `GoogleService-Info.plist`, place at:
   `ios/Runner/GoogleService-Info.plist` (gitignored — never commit), and add it to the
   Runner target in Xcode.
4. In Firebase Console → Project Settings → General, add SHA-1/SHA-256 for Play signing if
   you enable App Check.
5. Rebuild. `bootstrap.dart` logs `Firebase initialized` when activation worked; FCM device
   tokens are then registered to `POST /api/v1/device-tokens` right after login.

## Push routing

`PushNotificationService` registers the FCM token after login and deletes it on logout.
`NotificationHandler.routeFor` maps notification `type` payloads to routes
(`quiz_reminder → /quiz`, `battle_invite → /battle`, …).

## Remote Config keys (must match lib/app/config/feature_flags.dart)

`economy_enabled`, `ads_enabled`, `guest_calculator_enabled`, `social_engine_enabled`,
`referral_rewards_enabled`, `share_creatives_enabled`. Defaults live in
`FeatureFlags.defaults`; missing/uninitialized config falls back to those defaults.

## Sentry (optional, release only)

Compile-time DSN: `--dart-define=SENTRY_DSN=https://…`. `bootstrap.dart` initializes
SentryFlutter only in release builds with a DSN; `ErrorReporter` then fans out to both
Crashlytics and Sentry.

## Secrets

Never commit `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, or
any `*-adminsdk.json`. They are gitignored.

## Certificate pinning

Before public release, fill `CertificatePinning.prodPins`
(`lib/core/network/certificate_pinning.dart`) with the SHA-256 base64 digest of the leaf
certificate:

```
openssl s_client -connect bisaas.com:443 </dev/null 2>/dev/null | openssl x509 -outform DER \
  | openssl dgst -sha256 -binary | openssl base64
```

Pinning fails closed: with pins configured, any certificate that does not match is rejected.

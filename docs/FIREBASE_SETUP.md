# Firebase setup — bisaasmobile

This repo is ready for Firebase (FCM + Analytics + Crashlytics + Remote Config) via pubspec.yaml: firebase_core 4.14.0 etc., but no native config is committed.

## Add native config (one-time)

1. Firebase Console ? Add project (or reuse isaas-.... if you already have storage/app/firebase/...-adminsdk.json on the Laravel side).
2. Add Android app: package com.bisaas.bisaasmobile, download google-services.json ? place at

   `
   C:\laragon\www\bisaasmobile\android\app\google-services.json
   `

   (This file is gitignored via ndroid/app/google-services.json pattern — never commit.)

3. Add iOS app: bundle com.bisaas.bisaasmobile, download GoogleService-Info.plist ?

   `
   C:\laragon\www\bisaasmobile\ios\Runner\GoogleService-Info.plist
   `

4. In Firebase Console ? Project Settings ? General, add SHA-1/SHA-256 for Play signing if you enable App Check.

## Dev without Firebase (works today)

The app boots without google-services.json; Firebase calls are no-ops until the files exist. lib/app/bootstrap.dart should guard Firebase.initializeApp() with try/catch (see docs/mobileapp/FLUTTER_APP_MASTER_PLAN_2026.md:28). For push testing without FCM, use lutter run -d chrome + POST /api/v1/device-tokens manually.

## Remote Config keys (must match lib/app/config/feature_flags.dart)

economy_enabled, ds_enabled, social_engine_enabled, guest_calculator_enabled, eferral_rewards_enabled etc. Defaults are in FeatureFlags.init().

## Secrets

Never commit ndroid/app/google-services.json, ios/Runner/GoogleService-Info.plist, or any *-adminsdk.json. They are gitignored.

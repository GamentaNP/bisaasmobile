# Release checklist — CivilCal mobile

Everything that has to be true before the app can be published on Google
Play or the App Store, split into **what the code already guarantees** and
**what only the founder can supply**.

The code side fails closed: a release build without a certificate pin or
without signing material is refused by Gradle, and a production build
without a usable pin refuses to start on the device. The founder side
cannot be automated — those are accounts, certificates and portal
settings that only the account owner can touch.

---

## 1. Automated checks — must be green

| Check | Command | Where |
|---|---|---|
| Static analysis | `flutter analyze` | CI, `analyze-test` job |
| Unit + integration tests | `flutter test` | CI, `analyze-test` job |
| Test coverage | `flutter test --coverage` then `dart scripts/coverage_check.dart --min=55` | CI, `analyze-test` job |
| Device-test analysis | `cd device_tests && flutter analyze` | CI, `device-tests-analyze` job |
| Device tests on an emulator | `cd device_tests && flutter test integration_test -d emulator-5554` | CI, `Device tests` workflow (API 28 + 30) |
| Release APK + AAB build | `flutter build apk --release …` / `flutter build appbundle --release …` | CI, `build-android` job — **`main` only** |
| Obfuscated artifact scan | `bash scripts/scan_release_artifact.sh <apk>` | CI, `Mobile Security Gate` workflow |
| Device tests on hardware | `cd device_tests && flutter test integration_test -d DEVICE_ID` | needs a physical device |

A release build must also be **obfuscated** and **split-debug-info**d,
so that the Dart symbols never ship in the artifact:

```bash
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=APP_VERSION=1.0.2 \
  --dart-define-from-file=dart_defines/production.json \
  --obfuscate --split-debug-info=../build/symbols/android
```

The symbols in `build/symbols/` are needed to de-obfuscate a crash report.
They are a private CI artifact and must never be attached to a store
submission or a public repository.

---

## 2. Values only the founder can supply

These live in `dart_defines/production.json` or in a store portal. The
file is committed on purpose — it holds no secrets, only identifiers —
but a value that is still a placeholder will not do.

| Value | Where | Current state | What breaks without it |
|---|---|---|---|
| `CERT_PIN_1`, `CERT_PIN_2` | `dart_defines/production.json` | **real** | The Gradle build refuses a production release, and the runtime refuses to start. Already correct. |
| `SIGNING_CERT_HASH` | `dart_defines/production.json` | **real** | Android runs without the freeRASP device-integrity runtime. |
| `IOS_TEAM_ID` | `dart_defines/production.json` | `__REPLACE_WITH_APPLE_TEAM_ID__` | **iOS runs without the device-integrity runtime entirely.** See §5. |
| `APP_STORE_ID` | `dart_defines/production.json` | **missing** | The iOS force-update link falls back to the support page instead of the App Store listing. Add `"APP_STORE_ID": "1234567890"` once Apple issues it. |
| `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` | `--dart-define` | **missing** | Google sign-in is hidden entirely (which is correct behaviour, not a crash — see §4). |
| `APPLE_CLIENT_ID`, `APPLE_REDIRECT_URI` | `--dart-define` | **missing** | Sign in with Apple is hidden entirely. The redirect URI is required on Android and web; on iOS the "Sign in with Apple" capability must also be enabled on the App ID in the Apple Developer portal. |
| `android/key.properties` | `android/key.properties` (gitignored) | present on the founder machine, **absent in a fresh clone** | The Gradle build refuses a release. See §3. |
| `android/fastlane/play-service.json` | `android/fastlane/play-service.json` (gitignored) | **absent** | `fastlane supply` aborts in all three lanes. The Play Appfile resolves `play-service.json` relative to `android/fastlane/`; CI materialises it from the `PLAY_SERVICE_JSON_BASE64` secret. |
| Play / ASC API keys | CI secrets | — | `fastlane supply` / `deliver` / `upload_to_testflight` cannot authenticate. |
| `MATCH_PASSWORD` | CI secret | — | `fastlane match` cannot decrypt the signing certificates. |
| Apple numeric App Store ID | App Store Connect | — | See `APP_STORE_ID` above. |

---

## 3. Android release

1. Create the upload keystore and `android/key.properties`:

   ```properties
   keyAlias=upload
   keyPassword=…
   storeFile=../upload-keystore.jks
   storePassword=…
   ```

   The build fails closed and **names the missing key** if any of the
   four is absent or if `storeFile` points at a file that does not exist.
   (It used to fail with a bare "null cannot be cast to non-null type"
   from inside the Kotlin DSL, which reads like a toolchain bug.)

2. Confirm the certificate pins are current. A pin that no longer
   matches bricks the app on a user's phone, so re-check them against
   the live server certificate whenever the certificate is renewed.
   `CERT_PIN_2` exists for that rollover; add `CERT_PIN_3` if you need a
   third.

3. Verify the uploaded bundle's slices and permissions:

   ```bash
   bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
     --output=/tmp/apks.zip
   ```

   The AAB must contain **arm64-v8a** and **armeabi-v7a** only. It must
   **not** contain `android.permission.CAMERA`.

4. Generate the Play listing from the committed metadata:

   ```bash
   cd android
   version=$(grep -E '^version:' ../pubspec.yaml | sed -E 's/^version:[[:space:]]*//' | cut -d+ -f2)
   fastlane supply --package_name com.bisaas.bisaasmobile \
     --metadata_path fastlane/metadata/android \
     --skip_upload_apk --skip_upload_images \
     --release_notes "$(cat fastlane/metadata/android/en-US/changelogs/$version.txt)"
   ```

   **Do not use `jq` to read `pubspec.yaml`** — it is YAML, not JSON, so
   `jq -r .version` fails and takes the whole command with it. The `grep`
   above is the same extraction CI uses (`ci.yml`, "Resolve app version").

   The screenshots already exist — 8 of them, captured on the Redmi 6A
   against the live backend — but they live in `docs/store-assets/`, not in
   the upload tree. Copy them to `android/fastlane/metadata/android/*/images/`
   before running `supply` without `--skip_upload_images`; Play requires at
   least two phone screenshots.

5. Fill in the **Data safety** form from
   `docs/data_safety_inventory.md`. It already answers every question
   from the code; the open items are listed in §6 of that document.

---

## 4. iOS release

1. Generate `ios/Podfile.lock` on a macOS machine and commit it:

   ```bash
   flutter pub get
   (cd ios && pod install)
   ```

   CocoaPods does not run on Windows, so this step cannot be done in this
   repository's development environment. Without the lock, two machines
   can resolve different pod versions for the same commit.

2. Verify the bundle id is `com.bisaas.bisaasmobile` everywhere:
   `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`),
   `ios/fastlane/Appfile`, `ios/fastlane/Matchfile`, and the App Store
   Connect app record. A mismatch fails at signing with a misleading
   "no profile found" error.

3. Confirm the privacy manifest is in the bundle root:

   ```bash
   unzip -l build/ios/ipa/Runner.ipa | grep PrivacyInfo
   ```

   Apple rejects an upload with **ITMS-91053** if the app touches a
   Required Reason API without declaring the reason. The manifest is
   wired into the Xcode project's Resources build phase.

4. Confirm the store links resolve: `https://bisaas.com/privacy` and
   `https://bisaas.com/support` must be live pages. They are referenced
   by `ios/fastlane/metadata/*/privacy_url.txt` and `support_url.txt`,
   and by the iOS force-update fallback. **This is currently blocked** —
   `bisaas.com` redirects to a domain broker. See
   `LAUNCH_READINESS.md` §"The one fact that decides everything".

5. The social sign-in buttons are **hidden** when their client ids are
   not configured. That is deliberate — a button that is guaranteed to
   fail is worse than no button — but it means the store screenshots
   must not show them until the ids exist, and the server must have the
   matching OAuth clients before the buttons are enabled.

6. Submit:

   ```bash
   cd ios
   fastlane beta     # TestFlight
   fastlane prod     # App Store Review
   ```

   The Fastfile builds `Runner.ipa` — `flutter build ipa` names the
   archive after the Xcode target, not after the store product name.

---

## 5. The freeRASP iOS gap

`IOS_TEAM_ID` is still the placeholder `__REPLACE_WITH_APPLE_TEAM_ID__`.
That means an iOS build ships with the device-integrity runtime
completely disabled — `app_security.dart` logs the warning and starts
without a config. Android is unaffected, because `SIGNING_CERT_HASH` is
real.

This is not a crash and it does not block the upload. It does mean:

- the Play Data Safety form must answer the "diagnostic data" question
  for **Android only** if the iOS build is published without the value;
- the iOS privacy manifest
  (`ios/Runner/PrivacyInfo.xcprivacy`) declares
  `NSPrivacyCollectedDataTypeOtherDiagnosticData`, because the app is
  *built* to collect it. If `IOS_TEAM_ID` is not filled in, that one
  declaration has to come out before upload — the manifest must match
  what the shipped binary does, not what it is capable of.

**Recommendation: fill in `IOS_TEAM_ID` before the first iOS publish.**
It is one value, it makes the manifest and the Data Safety form match
across both platforms, and it restores the tamper detection that the
rest of the security plan assumes.

---

## 6. Also required before the first public release

- [ ] The privacy policy is published at a stable URL and the app's
      Settings → Privacy links to it. `docs/legal/privacy-policy-en.md` is
      the source (with `-ne` and `-hi` alongside); the Policy compliance
      section of `docs/data_safety_inventory.md` marks what still needs a
      decision.
- [ ] The Play listing has phone screenshots (8 exist in `docs/store-assets/`)
      and the App Store listing has at least one screenshot per required
      device size (still missing).
- [ ] The App Store "App privacy" labels are filled in from
      `docs/data_safety_inventory.md` §2.
- [ ] The `App Links` verification file is published at
      `https://bisaas.com/.well-known/assetlinks.json`, otherwise the
      `https://bisaas.com` deep links open a browser instead of the app.
- [ ] `IOS_TEAM_ID` is filled in — see §5.
- [ ] The Firebase project is switched to a data region that matches the
      launch market (currently `asia-southeast1`).
- [ ] A support address that a human reads is in place. The app points
      at `privacy@bisaas.com` and `security@bisaas.com`.

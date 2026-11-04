# Data Safety & Privacy Label inventory — CivilCal mobile

The exact answers for the **Play Console → App content → Data safety**
form and the **App Store Connect → App privacy** labels.

Every row below is traced to the code that produces it, so the form
cannot drift away from what the app actually does. The privacy manifest
(`ios/Runner/PrivacyInfo.xcprivacy`) and the in-app consent sheet
(`lib/core/consent/consent_screens.dart`) are written from the same
table.

**Rule applied throughout:** if the app sends it, it is declared. The
previous consent copy ("We collect nothing beyond what the app needs to
work") was not true — a push token, crash reports and a device-integrity
signal all leave the device before the user has chosen anything.

---

## 1. Summary — Play "Data safety" form

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | see the table below |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | TLS 1.2+ on every API call, plus certificate pinning in release builds (`lib/core/network/certificate_pinning.dart`) |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In-app account deletion (Settings → Delete Account → `DELETE /api/v1/account`), in-app erasure of the anonymous visitor profile (`lib/features/privacy/presentation/privacy_data_screen.dart`, `DELETE /api/v1/visitor-data`), and a web deletion URL for users who cannot open the app (Play requires one). |
| Is the data collected shared with third parties? | **Yes, limited** | Google Firebase — crash reporting (Crashlytics), opt-in analytics, push (FCM) and live battle lobbies (Realtime Database); Talsec freeRASP for the device-integrity verdict; the configured AI provider for tutor/calculator prompts. **No data is shared for advertising.** |
| Is data collected used for tracking? | **No** | no advertising SDK, no cross-app tracking, `NSPrivacyTracking = false` |
| Does the app collect the **Advertising ID**? | **No** | The advertising-id permissions that Firebase's measurement libraries merge in are removed at manifest-merge time (`tools:node="remove"` in `android/app/src/main/AndroidManifest.xml`). Without them the Firebase installation id is a random UUID rather than a value derived from the advertising id, so the app cannot identify a user across apps. See §3.3. |
| Do you offer a way to opt out of analytics? | **Yes** | Settings → Privacy → Analytics, and the consent sheet on first launch |

**Data is not sold, and it is not used for advertising or advertising
attribution.** There is no ad SDK in the dependency tree.

---

## 2. Summary — App Store "App privacy" labels

| Data type | Collected | Linked to the user | Used for tracking | Purposes |
|---|---|---|---|---|
| Contact info — Email address | Yes | Yes | No | App functionality |
| Identifiers — User ID | Yes | Yes | No | App functionality |
| Identifiers — Device ID | Yes | Yes | No | App functionality |
| Usage data — Product interaction | Yes (opt-in) | **Yes** — `AnalyticsService.setUserId` attaches the account id to events | Analytics |
| Diagnostics — Crash data | Yes | Yes | No | App functionality |
| Diagnostics — Other diagnostic data | Yes | Yes | No | App functionality |

Apple's privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`) declares the same
six types, with `NSPrivacyTracking = false` and an empty
`NSPrivacyTrackingDomains`. **Corrected 2026-11-04:** it previously omitted
`EmailAddress`, and this table claimed product interaction was unlinked while
the manifest — correctly — says linked. Both were fixed in the manifest, not
just here, because Apple validates the manifest at upload.

---

## 3. The full inventory

### 3.1 Account data — collected when you sign in

| Data | Where it is produced | Purpose | Play category |
|---|---|---|---|
| Email address | `POST /api/v1/auth/login`, `/auth/register` | Sign-in, account recovery | Contact info → Email address |
| Password | Sent to the server and stored **only** as a hash server-side. The client never persists it — `TokenManager` stores the token, its expiry and the device name, nothing else | Authentication | Not collected (transient) |
| Display name, profile picture, preferred language | `PUT /api/v1/me`, `POST /api/v1/me/avatar` | Profile | Personal info → User name; Photos (only if you pick one) |
| Referral code | `POST /api/v1/referrals/claim` | Rewards | Personal info → Other info (it is an identifier, not a purchase history) |

### 3.2 Learning activity — collected while you use the app

| Data | Where it is produced | Purpose |
|---|---|---|
| Quiz attempts, answers, score, time | `POST /api/v1/quiz/attempts/*`, `GET /api/v1/quiz/attempts/history` | Grading (server-authoritative), history, review |
| Streaks, XP, coins, achievements, leaderboard position | `GET /api/v1/economy/*`, `/gamification/*` | Progression and rewards |
| Battle records and answer timings | `POST /api/v1/battle/*` | Matchmaking and scoring |
| Calculator history and saved calculations | `POST /api/v1/calculator/history` | History and sharing |
| Library downloads, notes, bookmarks | `POST /api/v1/library/*` | Offline packs and study notes |
| Course progress | `POST /api/v1/courses/*` | Progress tracking |
| AI tutor conversations and calculator-assist prompts | `POST /api/v1/learning/tutor`, `POST /api/v1/ai/calculator-assist` | The feature you asked for |

All of this is **app functionality** and cannot be turned off without
breaking the product. It is deleted when you delete your account.

### 3.3 Device identifiers and diagnostics

| Data | Exact form | Where it is produced | Play category |
|---|---|---|---|
| **Install id** | A random UUID v4 generated on the device and kept in the platform keystore/keychain. It is not derived from hardware, so it cannot be used to fingerprint a device, and it resets when the app is uninstalled. | `X-Install-Id` on every request — `lib/core/network/install_identity_interceptor.dart:77` | Identifiers → Device ID |
| **Firebase installation id** | Firebase's own per-install identifier. With the advertising-id permissions removed it is a random UUID, not a value derived from the user's advertising id — so it identifies this install and nothing else. | Firebase Analytics / Crashlytics | Identifiers → Device ID |
| **Push token** | The Firebase Cloud Messaging registration token for this install | `POST /api/v1/device-tokens` — `lib/core/notifications/push_notification_service.dart:197`; deleted on logout via `DELETE /api/v1/device-tokens/{token}` (`:226`) | Identifiers → Device ID |
| **Device name** | A stable, human-readable name for this install (e.g. "Redmi 6A") | `X-Device-Name` on login and token refresh — `lib/core/network/auth_interceptor.dart:30` | Identifiers → Device ID |
| **App version, platform** | `1.0.2`, `android` / `ios` | `X-App-Version`, `X-Platform` — `install_identity_interceptor.dart:82` | Diagnostics |
| **Device integrity band** | One of `clean`, `suspicious`, `compromised`. It is a **coarse band, not an identifier** — it says "this install shows a root/debugger signal", not which device it is. | `X-Device-Risk` on every request — `lib/core/network/device_risk_interceptor.dart:17` | Diagnostics → Other diagnostic data |
| **Crash reports** | The exception, the stack trace, the app version, the device model, the OS version, the locale and the network type. | Firebase Crashlytics — `lib/core/analytics/crash_reporting.dart:25` | Diagnostics → Crash data |
| **Analytics events** | The event *name* and a small parameter map. **No question content is ever included** — see the event list in `lib/core/analytics/analytics_service.dart:29`. Tied to a device identifier; `setUser` is never called, so no event carries a user id. | Firebase Analytics, behind the consent gate — `lib/core/consent/consent_gate.dart:33` | Usage data → Product interaction |

### 3.4 Anonymous visitor profile — collected before you sign in

| Data | Exact form | Where it is produced |
|---|---|---|
| **Visitor id** | An HMAC-signed `_bs_vid` cookie issued by the server. The client never sends a visitor id — identity is never by a request value the client could forge. | `lib/features/privacy/domain/entities/visitor_data.dart:5` |
| **Intent events** | Which calculator a user looked at, so the server can rank recommendations. No answer content. | `POST /api/v1/intents` — `lib/features/privacy/data/datasources/privacy_remote_data_source.dart:92` |
| **Consent mode** | `functional`, `analytics` or `none` | `PUT /api/v1/public/cookie-consent` — `lib/core/consent/consent_controller.dart:97` |

The app lets you read and erase this profile in-app, and the server
refuses an anonymous erasure once the profile has been stitched to an
account — at which point the account-level deletion applies instead.

---

## 4. What the app does **not** do

- It does **not** collect your contacts, SMS, call logs, photos or
  location. The photo library is read once, only when you tap "Change
  avatar", and only the image you pick is uploaded.
- It does **not** use an advertising SDK, and there is no ad ID in the
  manifest. `NSPrivacyTracking` is `false`.
- It does **not** sell or share personal information.
- It does **not** include question content in analytics events.
- It does **not** back up the app's data to the cloud. `allowBackup` is
  `false` and both the Android backup rules and the data-extraction
  rules exclude everything, so the bearer token and the cached quiz
  answers never leave the device — not even through a device-to-device
  transfer on an OEM build that ignores the manifest flag.
- It does **not** read the advertising id. `com.google.android.gms.permission.AD_ID`
  and `android.permission.ACCESS_ADSERVICES_AD_ID` arrive with Firebase's
  measurement libraries and are removed at manifest-merge time, so the
  app cannot link a user across apps even by accident.

---

## 5. Third parties

| Processor | What it handles | Where |
|---|---|---|
| Google Firebase (Crashlytics) | Crash reports and stack traces | `firebase_crashlytics` |
| Google Firebase (Analytics) | Opt-in usage events | `firebase_analytics` |
| Google Firebase (Cloud Messaging) | Push delivery; the token itself | `firebase_messaging` |
| Google Firebase (Realtime Database) | Realtime features | `firebase_database` |
| Sentry | Optional crash reporting, only when configured with a DSN | `sentry_flutter` |
| Talsec (freeRASP) | Runs **on the device**. It produces the coarse integrity band; the raw signals never leave the device. | `freerasp` |

The Firebase services can be pinned to an EU or US data region. The
current project is configured for `asia-southeast1`; change the region
before the public launch if the primary market is elsewhere, and update
this table.

---

## 6. Open items before the forms can be submitted

These are **not** code problems. Each one needs a decision or a value
that only the founder can supply.

- [x] **Retention windows.** Answered on 2026-11-04: the policy's retention
      table (`docs/legal/privacy-policy-en.md` §5) now states them — account
      and study data 30 days after deletion (90 in backups), crash reports 90
      days, usage events 14 months then aggregates, anonymous visitor profile
      13 months after last visit, server logs 30 days, calculator telemetry 7
      days. Keep the policy and the server's prune schedules in step.
- [ ] **Firebase data region.** Confirm `asia-southeast1` is the right
      region for the launch market.
- [ ] **Sentry.** The SDK is bundled but sends nothing — no `SENTRY_DSN` is
      configured in `dart_defines/production.json`. Either configure it (and
      then add it to this table, the policy's third-party list and the Play
      "shared with third parties" answer in the same change) or remove the
      dependency.
- [ ] **The `freeRASP` iOS gap.** `IOS_TEAM_ID` in
      `dart_defines/production.json` is still the placeholder
      `__REPLACE_WITH_APPLE_TEAM_ID__`, so **iOS builds do not run the
      device-integrity runtime at all** and therefore do not report a
      risk band. Android does, because `SIGNING_CERT_HASH` is real. Two
      ways to close this, and one of them has to be chosen before the
      forms are submitted:
      1. Fill in `IOS_TEAM_ID` and declare the integrity band on both
         platforms (the table above already assumes this).
      2. Leave it as is, and answer the Play Data Safety "diagnostic
         data" question for **Android only**, with the iOS build
         documented as not collecting it.

  Note that the iOS privacy manifest
  (`ios/Runner/PrivacyInfo.xcprivacy`) declares
  `NSPrivacyCollectedDataTypeOtherDiagnosticData` because the app is
  *built* to collect it on both platforms and the gap is a one-value
  deployment fix — but the Data Safety form must match what the shipped
  binary does, not what it is capable of. **If `IOS_TEAM_ID` is not
  filled in, the iOS privacy manifest has to drop that one data type
  before upload.**

---

## 7. Where the user's rights are exercised in the app

| Right | Where |
|---|---|
| See what is stored (Art. 15) | Settings → Privacy → Data stored about this device |
| Erase the anonymous profile (Art. 17) | The same screen, or `DELETE /api/v1/visitor-data` |
| Withdraw consent | Settings → Privacy → the per-category switches |
| Export the account | By email to `privacy@bisaas.com` |
| Delete the account | By email to `privacy@bisaas.com` |

Contact: **privacy@bisaas.com** · Security reports:
**security@bisaas.com**

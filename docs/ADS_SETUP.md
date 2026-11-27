# AdMob rewarded ads (mobile only)

Status: **scaffolded, not live**. The client can load and show a rewarded
video, and it owns the two-step server claim, but no feature screen calls it
yet — the screens are owned by other workstreams. Ads stay invisible until all
four defines are supplied **and** the server's `ads_earn_coins_enabled` flag is
on.

`google_mobile_ads: ^9.2.0` is the only ad SDK. Google's verified publisher is
`google.dev`; the plugin requires Flutter >= 3.38.1 / Dart >= 3.10 (this repo
is on 3.47.2 / 3.13.2).

---

## 1. Dashboard setup (one-time, AdMob)

1. Sign in to <https://admob.google.com> and create an AdMob account (or use
   the existing publisher account). Accept the policies. Complete the payment
   profile before expecting any revenue.
2. **Apps → Add app**.
   - Platform **Android**. Bundle ID must match the application id in
     `android/app/build.gradle.kts`: `com.beardbishwo.lovemcq`. AdMob shows the
     **App ID** as `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` — copy it.
   - Platform **iOS**. Bundle ID is `com.beardbishwo.lovemcq` (the Flutter
    Runner target). Copy its App ID (`ca-app-pub-…~…`).
   - Do both apps even if only one ships first; the four dart-defines are
     platform-specific and the service checks the current platform.
3. **Ad units → New ad unit → Rewarded** for each app.
   - Name them after the placement, e.g. `lovemcq_daily_quiz_rewarded`.
   - Copy the **Ad unit ID**: `ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz`
     (slash, not tilde — that is the app ID).
4. **Privacy & messaging**: keep GDPR/CCPA settings in the AdMob UI as the
   operator requires. The client deliberately adds **no App Tracking
   Transparency prompt** and no `NSUserTrackingUsageDescription`: it does not
   read IDFA and this change does not alter that posture.
5. **iOS → SKAdNetwork IDs**: copy the identifiers from
   <https://developers.google.com/admob/ios/ios14> into
   `ios/Runner/Info.plist` under `SKAdNetworkItems`. The full published Google
   list is already in this repo. These are public network identifiers, not
   secrets; add any extra ones required by a mediation partner only if a
   partner is actually added (none is today).

**No ad ID is committed to this repository.** Every value above is supplied at
build time.

---

## 2. The four dart-defines

| Define | Value | Used by |
| --- | --- | --- |
| `ADMOB_APP_ID_ANDROID` | Android app ID (`~`) | `android/app/build.gradle.kts` → `${admobApplicationId}` manifest placeholder → `com.google.android.gms.ads.APPLICATION_ID` |
| `ADMOB_REWARDED_UNIT_ID_ANDROID` | Android rewarded ad unit ID (`/`) | `AdConfig.fromEnvironment()` → `RewardedAd.load` |
| `ADMOB_APP_ID_IOS` | iOS app ID (`~`) | `AdConfig.fromEnvironment()` and the `GADApplicationIdentifier` build-setting variable in `ios/Runner/Info.plist` |
| `ADMOB_REWARDED_UNIT_ID_IOS` | iOS rewarded ad unit ID (`/`) | `AdConfig.fromEnvironment()` → `RewardedAd.load` |

Production Android values are already in `dart_defines/production.json` (app
ID `ca-app-pub-3662424462984969~9265865820`, rewarded unit
`ca-app-pub-3662424462984969/8054090036`) from the Love Mcq AdMob account;
the manifest placeholder injects the app ID at build time. iOS has no AdMob
app or ad unit yet, so iOS ads stay disabled until those two defines are added
alongside a real `GADApplicationIdentifier`.

Example (local verification with Google's published **test** IDs — safe to
use in development, never in a release):

```powershell
flutter run -d android --dart-define=ENV=dev \
  --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713 \
  --dart-define=ADMOB_REWARDED_UNIT_ID_ANDROID=ca-app-pub-3940256099942544/5224354917
```

For a real build add all four to the environment's dart-define file / CI
invocation alongside `CERT_PIN_1` etc. A define that is missing, blank, or a
placeholder leaves ads **disabled** — no exception, no SDK init, no ad request.
`createAdRewardService()` returns `NoOpAdRewardService`, whose `isAvailable`
is `false` so the UI can hide the entry point entirely.

### iOS build setting

`ios/Runner/Info.plist` declares
`GADApplicationIdentifier = $(ADMOB_APP_ID_IOS)` rather than a literal. Set
`ADMOB_APP_ID_IOS` as a build setting on the Runner target (or in an xcconfig
for that target) when preparing the iOS build; the same value must also be
passed as a `--dart-define` so the Dart side enables the service. The Xcode
project now defines `ADMOB_APP_ID_IOS = ""` in every configuration, so an
unset value resolves to empty rather than the literal `$(...)` string. Replace
that build setting (or override it in an xcconfig) with the real AdMob app ID
before an iOS release. With the setting absent, the SDK is never initialised
by this code path and ads stay off — it cannot crash the app.

---

## 3. Platform guard

`google_mobile_ads` has no web/desktop implementation. `AdConfig` reads
`kIsWeb` and `defaultTargetPlatform`; anything other than Android/iOS yields
`supported: false`, and `createAdRewardService()` returns the no-op service.
**Flutter web / Chrome cannot show ads** — running `flutter run -d chrome`
with all four defines still yields `AdRewardOutcome.unavailable`. This is
intentional, not a bug to work around.

The Android manifest still removes `com.google.android.gms.permission.AD_ID`
and `ACCESS_ADSERVICES_AD_ID` at merge time — that privacy decision is
unchanged by ads, and no ATT/IDFA permission is requested on iOS.

Unity LevelPlay is deliberately **NOT** integrated. Its iOS path requires
`NSAllowsArbitraryLoads=true` in `NSAppTransportSecurity`, which would undo
the app's strict ATS posture (`ios/Runner/Info.plist` still has
`NSAllowsArbitraryLoads=false`, no exceptions). One rewarded ad format from
the official Google plugin is enough; no mediation SDK is worth weakening TLS
for.

---

## 4. Dart API

`lib/core/ads/`:

| File | Role |
| --- | --- |
| `ad_config.dart` | Reads the four defines, enforces the platform guard. |
| `ad_reward_result.dart` | `AdRewardOutcome` (`rewarded`/`dismissed`/`failed`/`unavailable`) and the SDK gateway seam. The production gateway calls `RewardedAd.load` and `RewardedAd.show` and listens for `onAdLoaded`, `onAdFailedToLoad`, `onUserEarnedReward` and the full-screen content callbacks. |
| `ad_reward_service.dart` | `AdRewardService.initialize()`, `isAvailable`, `showRewardedAd()`; no-op when unsupported/unconfigured. |
| `ad_claim_session.dart` | DTO for `data.claimToken` from initiate. |
| `ad_reward_remote_data_source.dart` | `POST /ads/reward/initiate` and `PUT /ads/reward/claim`. |
| `ad_reward_flow.dart` | Composes initiate → show → claim without crediting locally. |
| `ads_providers.dart` | Riverpod providers for screens to consume. |

A reward is reported **only** when the official SDK's `onUserEarnedReward`
callback fires. A load failure, a timeout, a dismissal and a missing define
are separate outcomes. The client never credits coins, never writes a wallet
entry and never displays a server-unconfirmed amount.

---

## 5. Server claim flow (authoritative)

Source of truth: `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md`
§8d. All calls use the canonical `/api/v1` base URL and `Accept:
application/json` (both added by the shared Dio client). The user must be
signed in.

```
1. POST /api/v1/ads/reward/initiate   {reward_type?, slot_code?}
   → data.claimToken              (server-issued, TTL 300s, camelCase on wire)
   → data.requiredDurationSeconds (minimum watch time, enforced server-side)

2. Show the rewarded ad via AdRewardService.showRewardedAd().
   Only AdRewardOutcome.rewarded may proceed.

3. PUT /api/v1/ads/reward/claim
     body:    {"claim_token": "<data.claimToken>"}
     header:  Idempotency-Key: <uuid>        (REQUIRED)
   → the server verifies timing/fraud and credits its own coinsExpected.
```

`POST /ads/reward/claim` is **not** a registered route — do not use it. The
legacy alias `ad_view_id` is accepted by the server but must carry the same
server-issued token; this client always sends `claim_token`.

Order matters: initiate stamps the server's start time, so the claim session
must be opened **before** the video is shown. A retry of a failed claim must
reuse the **same** `Idempotency-Key` (`AdRewardFlow.run(claimIdempotencyKey:
…)`); minting a new one is a fresh credit attempt. An initiate failure or a
claim failure returns `AdRewardOutcome.failed` with `claimError` — the UI must
not show a coin award on that path, because the ledger was not updated.

The server also defaults `ads_earn_coins_enabled` to **false**. Even a perfect
client flow returns no coins until an operator turns that flag on in the
Bisaas admin panel. This is expected and is not a client bug.

### Wiring a screen (other workstreams)

No presentation file was changed here. To add the entry point:

```dart
final ready = ref.watch(adRewardReadyProvider);
// ready.value == false → hide the button (web/unsupported/not configured)

final result = await ref.read(adRewardFlowProvider).run(
  rewardType: 'quiz_reward',          // only a server-defined value
  claimIdempotencyKey: const Uuid().v4(), // mint once, reuse on retry
);
switch (result.outcome) {
  case AdRewardOutcome.rewarded:
    // Refresh the wallet/balance from the server; do not add coins locally.
  case AdRewardOutcome.dismissed:
  case AdRewardOutcome.failed:
  case AdRewardOutcome.unavailable:
    // No credit. failed → show a retry with the SAME idempotency key.
}
```

---

## 6. Verification

```powershell
flutter pub get
flutter analyze
flutter test test/core/ads/**
```

Device/web checks:

- `flutter run -d chrome ...` → no ad SDK initialisation, `isAvailable ==
  false`, no entry point (the no-op path is unit-tested).
- Android with the four defines → merged manifest contains the real
  `com.google.android.gms.ads.APPLICATION_ID` value; a rewarded ad loads and
  the SDK logs a reward callback. Without the defines → placeholder is empty
  and the Dart service never calls `MobileAds.instance.initialize()`.
- iOS with the build setting + dart-define → `GADApplicationIdentifier` is the
  real app ID in the built plist, `SKAdNetworkItems` contains Google's list,
  ATS remains `NSAllowsArbitraryLoads=false`.
- Watch one ad with server flag off → ad completes but no coins appear; turn
  the flag on → `PUT /ads/reward/claim` returns 2xx and the server's wallet
  endpoint shows the credit. Replaying the same idempotency key must not
  double-credit.

Test coverage lives in `test/core/ads/` and uses injected gateways/fakes — no
real ad network or AdMob account is needed to run the suite.

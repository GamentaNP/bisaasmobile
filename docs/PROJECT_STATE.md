# Project state — the client, measured

**Counts re-measured 2026-11-27.** Every number here was read from the tree
or from CI, not carried forward from an earlier note; the server-contract
facts were last verified 2026-11-04. Anything that is a plan rather than a
fact lives in [LAUNCH_READINESS.md](LAUNCH_READINESS.md) — its store section is
a historical record under the 2026-09-11 directive; anything the server owes
lives in [SERVER_CONTRACT_STATUS.md](SERVER_CONTRACT_STATUS.md).

This file replaces `MOBILE_CLIENT_STATE_2026-09-28.md` and
`MOBILE_REMAINING_WORK_2026-09-27.md`, both of which described a smaller app
and are retired.

**Standing decisions (reconciled 2026-11-26 — not open work):** no store
publication ever, unless the founder reverses the 2026-09-11 PERMANENT
directive in writing; offline is read-cache only with the write outbox
deliberately unwired; no billing library and no IAP — coins are earned and
server subscription state is display-only; `sentry_flutter` has no DSN and
therefore sends nothing.

## 1. What this repository is

The Flutter client for LoveMCQ (Nepal-first civil-engineering exam prep),
Android and iOS, talking to the Laravel server in `C:\laragon\www\bisaas`
over `/api/v1` only.

The client owns **pixels, animations, local state, the offline read-cache and
push handling**. It never grades a quiz, mints coins, unlocks an achievement,
ranks a leaderboard, detects fraud or validates a subscription. Every one of
those is a server answer the client renders. Subscription state is
**display-only**: there is no billing library and no IAP, and coins are earned,
not bought.

## 2. Baseline

| Measure | Value | How to re-measure |
|---|---|---|
| Dart files under `lib/` | not pinned — active feature work; re-measure | `Get-ChildItem -Recurse -File lib -Filter *.dart \| Measure-Object` |
| Dart files under `test/` | not pinned — active feature work; re-measure | `Get-ChildItem -Recurse -File test -Filter *.dart \| Measure-Object` |
| Feature modules | not pinned — active feature work; re-measure | `Get-ChildItem -Directory lib/features \| Measure-Object` |
| Host test files | not pinned — active feature work; re-measure | `Get-ChildItem -Recurse -File test -Filter *_test.dart \| Measure-Object` |
| Host test declarations | not pinned — active feature work; re-measure | `grep -rhoE '^\s*(test\|testWidgets)\(' test \| wc -l` |
| Device smoke tests | 10 declarations (9 default + 1 live-only) | `device_tests/integration_test/device_smoke_test.dart` |
| Translations | 1,360 messages × en/ne/hi | `python tool/generate_arb.py` (writes all three ARBs from one table; count non-`@` keys) |
| App version | `1.0.2+2` | `pubspec.yaml` |
| SDK floor / target | minSdk 26 (Android 8.0) / targetSdk 36 / compileSdk 37 | `android/app/build.gradle.kts:134-172` |
| Release AAB | built by CI on `main`, upload-key signed (size not pinned here); internal test build, not a submission candidate | `flutter build appbundle --release …` |
| Coverage floor | 55% (CI-enforced), roadmap target 70% | `scripts/coverage_check.dart` |

Thirteen keys per locale are byte-identical to English on purpose — unit
symbols, brand names, format tokens and a sample URL (`%`, `XP`, `★`,
`LoveMCQ`, `https://api.example.com/v1`). The translation audit treats those
as correct, not as gaps.

## 3. What is shipped and where it is proven

The three test layers are complementary, and each one catches a class of bug
the others cannot:

| Layer | Location | What it has actually caught |
|---|---|---|
| Unit | `test/**` | DTO parsing, controller state, interceptor behaviour, l10n coverage. |
| Integration | `test/integration/` | The whole client stack — real Dio → interceptors → adapter → envelope → DTO → repository → controller — against a scripted transport. Every production contract bug found in October lives here as a regression. |
| Device | `device_tests/` (separate package) | Engine, plugins, real navigation, secure storage. 10 declarations, of which 9 run by default on the emulator in CI (API 28 and 30) and 1 is gated behind `RUN_LIVE_TESTS`. |

Shipped surfaces, all server-backed: auth (email, Google, Apple — the social
buttons are hidden by the production defines, see C4), guest funnel, daily quiz,
practice and bookmark drills, mock tests, syllabus and book readers, numerical
practice, calculator suite (schema-driven), economy (wallet, shop, premium —
display-only subscription state, no IAP), gamification (streak, missions, check-in, spin,
world map), battle (offline bot kernel + online lobbies), **arcade**
(Survival, Lightning, True/False — timed runs started, ended and scored by
the server, with an optional category scope), library, notifications,
referrals, share, profile/settings, trilingual UI.

## 4. Invariants the code holds — do not regress these

1. **A failure is never an empty list.** Data sources throw; controllers
   render an error with a retry. `lib/core/network/api_failure.dart`,
   `envelope.dart`, `pagination.dart` are the only place that decides.
2. **Envelope + `ApiErrorCode`.** Unknown codes degrade to a generic message;
   they never surface a Dart stack trace to a user.
3. **Cursor pagination only on the four question-family collections.** Never
   send `page` to them.
4. **Bearer PAT only in `flutter_secure_storage`.** Backup and device
   transfer are disabled in the manifest and in both XML rule sets.
5. **The tenant is a property of the credential.** `X-Tenant` is sent only
   when the user has selected one. `TENANT_MISMATCH` forces a fresh login;
   `TENANT_INACTIVE` (with `error.details.tenant_id`) has **no retry** at all —
   a full-screen workspace-closed state takes over the app. The global gate
   nests inside ForceUpdate/Maintenance, so operator kill switches win. See
   [TENANT_SWITCHER_CONTRACT.md](TENANT_SWITCHER_CONTRACT.md).
6. **Release fails closed.** No keystore or no usable `CERT_PIN_1` refuses a
   production release at Gradle *and* at runtime.
7. **Cleartext HTTP is blocked in every build**, including debug; the debug
   certificate shim never covers a production host.
8. **No codegen except Drift.** Zero `@freezed`, `@JsonSerializable`,
   `@riverpod` annotations; every DTO hand-writes `fromJson`.
9. **No hardcoded user-facing string.** `test/app/localization_coverage_test.dart`
   enforces it; the audit checks the copy is consistent, not merely present.
10. **The write outbox stays unwired** (`core/sync/`) — **settled product
    decision: read-cache only, not an open task**. Enqueuing a quiz answer
    before the server can score it offline would be a lie. See §5 C1.

## 5. Tracked client items (C1–C6) — current standing

The six items and their measured facts are kept. Under the 2026-09-11
PERMANENT directive there is no store launch, so none is a launch blocker: C1
is settled, C3/C4 are **moot for store submission; may still be needed for
on-device testing**, C2 is latent behind C1, and C5/C6 are known constraints.

| # | Item | Status / owner | Fact and current standing |
|---|---|---|---|
| C1 | Offline **answering** (write outbox) | **Settled (founder/lead) — not open** | **SETTLED: read-cache only.** `SyncQueueService` is built and tested but nothing enqueues, by decision: grading is server-authoritative, so a replayed answer would be a lie. `test/core/storage/unwired_tables_test.dart` pins the invariant. Do not wire `.enqueue()`. |
| C2 | Sync queue tenant binding | Client (settled 2026-11-26) | Queued rows carry a tenant id (`lib/core/sync/sync_queue.dart:47,121`) and a mismatched row is dropped at drain rather than replayed cross-tenant (`lib/core/sync/sync_manager.dart:60-63`). With C1 settled as read-cache only this stays **latent, not active work**, but the binding itself is in place. |
| C3 | iOS `IOS_TEAM_ID` is a placeholder | Founder | `dart_defines/production.json` still holds `__REPLACE_WITH_APPLE_TEAM_ID__`; the App ID also needs the Sign in with Apple capability. **Moot for store submission; may still be needed for on-device testing** (no App Store publication under the 2026-09-11 directive). Not a launch blocker. |
| C4 | Social sign-in IDs absent | Founder | `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`, `APPLE_CLIENT_ID`, `APPLE_REDIRECT_URI` are not in the production defines, so those buttons are correctly hidden. Without the *server* client id the SDK issues no id_token. **Moot for store submission; may still be needed for on-device testing.** Not a launch blocker. |
| C5 | TalkBack on API 26–33 | Upstream engine | Flutter 3.47.2's accessibility bridge references an API-34 type and disables itself on older releases. The app runs; screen-reader support starts at API 34. Documented, not fixable here. |
| C6 | No on-device E2E automation | Client | Patrol was declined because its native plugin changes the release artifact. Under the 2026-09-11 directive this is a **QA tool, not a release gate**. Device tests are a curated smoke suite; the five-leg journey test runs on the host stack. |

## 6. How to verify this file

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage --concurrency=4
dart scripts/coverage_check.dart --min=55
flutter gen-l10n && dart run tool/arb_coverage.dart && python tool/audit_translations.py
cd device_tests && flutter pub get && flutter analyze
```

CI runs all of the above on every push to `main` and `development`, plus an
emulator run of the device tests and an obfuscated release build whose APK is
unpacked and scanned for forbidden content.

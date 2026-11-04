# Project state — the client, measured

**Verified at `0cee095`, 2026-11-04.** Every number here was read from the
tree or from CI, not carried forward from an earlier note. Anything that is
a plan rather than a fact lives in [LAUNCH_READINESS.md](LAUNCH_READINESS.md);
anything the server owes lives in
[SERVER_CONTRACT_STATUS.md](SERVER_CONTRACT_STATUS.md).

This file replaces `MOBILE_CLIENT_STATE_2026-09-28.md` and
`MOBILE_REMAINING_WORK_2026-09-27.md`, both of which described a smaller app
and are retired.

## 1. What this repository is

The Flutter client for CivilCal (Nepal-first civil-engineering exam prep),
Android and iOS, talking to the Laravel server in `C:\laragon\www\bisaas`
over `/api/v1` only.

The client owns **pixels, animations, local state, the offline read-cache and
push handling**. It never grades a quiz, mints coins, unlocks an achievement,
ranks a leaderboard, detects fraud or validates a subscription. Every one of
those is a server answer the client renders.

## 2. Baseline

| Measure | Value | How to re-measure |
|---|---|---|
| Dart files under `lib/` | 360 | `find lib -name '*.dart' \| wc -l` |
| Feature modules | 34 | `ls lib/features \| wc -l` |
| Host test files | 117 | `find test -name '*_test.dart' \| wc -l` |
| Host test declarations | 1,185 | `grep -rhoE '^\s*(test\|testWidgets)\(' test \| wc -l` |
| Device smoke tests | 8 + 1 live-only | `device_tests/integration_test/device_smoke_test.dart` |
| Translations | 1,192 messages × en/ne/hi | `python -I -c "import json;print(len([k for k in json.load(open('lib/l10n/app_en.arb'))if not k.startswith('@')]))"` |
| App version | `1.0.2+2` | `pubspec.yaml` |
| SDK floor / target | minSdk 26 (Android 8.0) / targetSdk 36 / compileSdk 37 | `android/app/build.gradle.kts:134-172` |
| Release AAB | 79,848,351 bytes (76.1 MiB), upload-key signed | `flutter build appbundle --release …` |
| Coverage floor | 55% (CI-enforced), roadmap target 70% | `scripts/coverage_check.dart` |

Twelve keys per locale are byte-identical to English on purpose — unit
symbols and brand strings (`%`, `XP`, `★`, `CivilCal`). The translation audit
treats those as correct, not as gaps.

## 3. What is shipped and where it is proven

The three test layers are complementary, and each one catches a class of bug
the others cannot:

| Layer | Location | What it has actually caught |
|---|---|---|
| Unit | `test/**` | DTO parsing, controller state, interceptor behaviour, l10n coverage. |
| Integration | `test/integration/` | The whole client stack — real Dio → interceptors → adapter → envelope → DTO → repository → controller — against a scripted transport. Every production contract bug found in October lives here as a regression. |
| Device | `device_tests/` (separate package) | Engine, plugins, real navigation, secure storage. 8 tests on the emulator in CI; 9/9 on the founder's Redmi 6A against the live backend. |

Shipped surfaces, all server-backed: auth (email, Google, Apple), guest
funnel, daily quiz, practice and bookmark drills, mock tests, syllabus and
book readers, numerical practice, calculator suite (schema-driven), economy
(wallet, shop, premium), gamification (streak, missions, check-in, spin,
world map), battle (offline bot kernel + online lobbies), library,
notifications, referrals, share, profile/settings, trilingual UI.

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
   when the user has selected one; `403 TENANT_MISMATCH` forces re-auth
   instead of retrying.
6. **Release fails closed.** No keystore or no usable `CERT_PIN_1` refuses a
   production release at Gradle *and* at runtime.
7. **Cleartext HTTP is blocked in every build**, including debug; the debug
   certificate shim never covers a production host.
8. **No codegen except Drift.** Zero `@freezed`, `@JsonSerializable`,
   `@riverpod` annotations; every DTO hand-writes `fromJson`.
9. **No hardcoded user-facing string.** `test/app/localization_coverage_test.dart`
   enforces it; the audit checks the copy is consistent, not merely present.
10. **The write outbox stays unwired** (`core/sync/`). Enqueuing a quiz
    answer before the server can score it offline would be a lie. See §5.

## 5. Open work that belongs to the client

| # | Item | Owner | Why it is open |
|---|---|---|---|
| C1 | Offline **answering** (write outbox) | Product decision first | `SyncQueueService` is built and tested but nothing enqueues. Wiring `.enqueue()` needs a decision about what the UI tells a user whose answers will be graded later — or never. `test/core/storage/unwired_tables_test.dart` pins the current state so it cannot drift silently. |
| C2 | Sync queue has no tenant binding | Client | Rows carry no tenant id, so a queued write replayed after an organization switch would land under the new tenant. Must be fixed *before* C1 is wired, not after. |
| C3 | iOS `IOS_TEAM_ID` is a placeholder | Founder | `dart_defines/production.json` still holds `__REPLACE_WITH_APPLE_TEAM_ID__`; the App ID also needs the Sign in with Apple capability. No iOS build can be signed until then. |
| C4 | Social sign-in IDs absent | Founder | `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`, `APPLE_CLIENT_ID`, `APPLE_REDIRECT_URI` are not in the production defines, so those buttons are correctly hidden. Without the *server* client id the SDK issues no id_token. |
| C5 | TalkBack on API 26–33 | Upstream engine | Flutter 3.47.2's accessibility bridge references an API-34 type and disables itself on older releases. The app runs; screen-reader support starts at API 34. Documented, not fixable here. |
| C6 | No on-device E2E automation | Client | Patrol was declined because its native plugin changes the release artifact. Device tests are a curated smoke suite; the five-leg journey test runs on the host stack. |

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

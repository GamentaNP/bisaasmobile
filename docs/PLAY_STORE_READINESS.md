# Play Store readiness — bisaasmobile (CivilCal)

Status as of 2026-10-24. Read this top to bottom before inviting testers.

## 1. CRITICAL PATH — production backend does not exist yet

The app's production build points at `https://bisaas.com` (`env.dart`), but
**bisaas.com is not ours** — the domain is parked for sale at HugeDomains
(every subdomain resolves to the parking service). The only working backend
today is the local Laragon dev server (`https://bisaas.test`).

A release build against the current defines will boot and render, but every
network call fails. **No tester can get past login until a backend is
deployed.**

### The path to a live backend (founder decisions + actions)

1. **Register a domain we own.** `bisaas.com` is held by a reseller (buy-back
   is typically USD 2–5k — not recommended). Recommended: register a fresh
   domain for the brand — e.g. `civilcal.app` / `civilcal.com` (the app's
   product name is CivilCal, so the brand and the domain align) — ~USD 10–15/yr.
2. **Host the Laravel backend** (repo `C:\laragon\www\bisaas`): any VPS or
   managed host running PHP 8.3 + PostgreSQL (Laragon mirrors this stack
   locally). Deploy, run migrations, seed, set `APP_URL` to the new domain.
3. **TLS**: a Let's Encrypt certificate on the host.
4. **Update the client (this repo)** — the flip is four small changes:
   - `lib/app/config/env.dart`: prod host → the new domain.
   - `dart_defines/production.json`: regenerate `CERT_PIN_1`/`CERT_PIN_2`
     from the new server's certificate chain (pin the leaf + the
     intermediate; command in `docs/` below).
   - `android/app/src/main/AndroidManifest.xml`: intent-filter hosts for
     deep links (`civilcal://` stays; the https host changes).
   - `ios/Runner/Info.plist` + associated-domains, if iOS follows.
5. **Web auth artifacts on the server**: `/.well-known/assetlinks.json`
   (Android App Links verification — currently unpublished) and the Apple
   equivalent when iOS ships.

### Regenerating certificate pins (when the server exists)

```bash
# leaf:
echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER 2>/dev/null \
  | openssl dgst -sha256 -binary | base64
# intermediate: add -showcerts and repeat per chain certificate
```

Put the leaf hash in `CERT_PIN_1`, the intermediate in `CERT_PIN_2`.

## 2. What is DONE and verified

| Item | State |
|---|---|
| Release APK (signed, pinned, obfuscated) | 89.6 MB, boots + renders on the physical Redmi 6A (Android 9) |
| Release AAB (Play upload format) | 76.0 MB at `build/app/outputs/bundle/release/app-release.aab` |
| Host test suite | 1,597/1,597 passing |
| On-device integration suite | 7/7 + 1 skip on the Redmi (API 28) and the API 30 emulator |
| minSdk | 26 (Android 8.0) — ~96% of active devices |
| targetSdk | 36 (Android 16) — current Play requirement |
| Localizations | en / ne / hi, 1,163 keys, coverage-gated in CI |
| Security | cert pinning (fail-closed), freeRASP, secure storage, consent gating |

## 3. Play Console checklist (per release)

- [ ] App name: **CivilCal** (product name; package `com.bisaas.bisaasmobile`).
- [ ] Short + full description (drafts below).
- [ ] Screenshots: min 2, recommended 1080×1920 — captured from the emulator
      against the local backend (see `docs/store-assets/`).
- [ ] Feature graphic 1024×500 (needs design).
- [ ] **Data safety form** — the app transmits:
      - account email + user id (account management — required for the service);
      - device name + FCM push token (push notifications);
      - crash logs (Firebase Crashlytics);
      - app-interaction events (Firebase Analytics) — **gated behind the
        in-app consent sheet, off until the user opts in**;
      - device-integrity signals (freeRASP) for fraud prevention.
      Nothing is collected before consent except what the service requires.
- [ ] Privacy policy URL — must exist on the backend domain (server side).
- [ ] Content rating questionnaire: education/quiz app, no user-generated
      content sharing beyond share-sheets, no ads.
- [ ] Target audience: 13+ (engineering students).
- [ ] Internal testing track first: upload the AAB, add testers by email.

## 4. Listing copy drafts

**Short description (80 chars max):**
Civil engineering quizzes, calculators & courses — study, compete, get licensed.

**Full description (draft):**
CivilCal is the all-in-one study companion for civil engineering students and
Loksewa/licensure aspirants in Nepal and India. Practice thousands of
server-graded MCQs, solve real calculators, read the book library, battle
friends in realtime, keep streaks alive, and climb the leaderboards — in
English, नेपाली, and हिन्दी.

## 5. Version

Current: `1.0.2+2` (versionName 1.0.2, versionCode 2 — bumped past the
released `v1.0.1` tag because the server's `EnforceAppVersion` gate answers
426 to older builds). For the first Play internal release this is fine; bump
`versionCode` for every upload after.

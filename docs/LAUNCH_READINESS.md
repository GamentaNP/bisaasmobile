# Launch readiness — what stands between this build and the Play Store

**Re-audited 2026-11-25.** This is the founder-facing document:
the ordered critical path, the decisions only the founder can make, and the
honest status of each. Mechanical release steps live in
[release_checklist.md](release_checklist.md); the store copy lives in
[store_listing.md](store_listing.md); the publishable policy lives in
[legal/](legal/).

It replaces `PLAY_STORE_READINESS.md` and `LAUNCH_ROADMAP.md`, which
disagreed with each other about an old domain question that is now closed.

## The one fact that decides everything

Production is **live** at `https://lovemcq.com` (web and `/api/v1` both
answer 200). Staging is `https://staging.lovemcq.com`. The published ids are
`com.beardbishwo.lovemcq` for both Android (applicationId) and iOS (bundle
id). `dart_defines/production.json` ships:

```json
"API_HOST": "https://lovemcq.com",
"API_BASE_URL": "https://lovemcq.com/api/v1",
"CERT_PIN_1": "sha256/E8fEUpIJzzIGi2ZYCA04yv4PwxZq96Rl1QKEjFWy9HQ=",
"CERT_PIN_2": "sha256/E8fEUpIJzzIGi2ZYCA04yv4PwxZq96Rl1QKEjFWy9HQ=",
"SIGNING_CERT_HASH": "sha256/Idhu5QABO16+E+ITyW/C23QfqrjrfZWMtxm0WCGK1B4="
```

The old `bisaas.com` domain question is **resolved**: there is no domain
blocker and no store step waits on a domain decision. Pins still fail closed
by design, so re-check them against the live chain after any certificate
renewal (add `CERT_PIN_3` for a rollover rather than pasting an untried value).

## Critical path, in order

### 1. Backend + TLS + App Links identity (verify before tagging)

1. Deploy the Laravel API by
   [BACKEND_DEPLOYMENT_RUNBOOK.md](BACKEND_DEPLOYMENT_RUNBOOK.md). It is
   currently correct for PHP 8.4 + Sanctum, PostgreSQL, Redis, queue and
   scheduler.
2. Confirm the API answers:
   `GET https://lovemcq.com/api/v1/app/config` → 200.
3. Confirm `CERT_PIN_1`/`CERT_PIN_2` in `dart_defines/production.json` still
   match the live chain (a stale pin fails closed by design).
4. Set the Android SHA-256 fingerprints in **Admin → Settings → Mobile App
   Settings → "Store identity & app links"**; the Laravel route serves
   `https://lovemcq.com/.well-known/assetlinks.json`. Add the Play
   **app-signing** key fingerprint too, or links fail on every Play-installed
   build. There is no `docs/ASSETLINKS.json` and a static
   `public/.well-known/assetlinks.json` must never be restored — a real file
   would shadow the config-driven route forever. See
   [APP_LINKS_DEPLOYMENT.md](APP_LINKS_DEPLOYMENT.md).

### 2. Legal + policy URLs (blocks the store form, not the build)

1. Pick the single publishable policy — `docs/legal/privacy-policy-en.md`
   (with `-ne` and `-hi` as linked translations). The older
   `docs/privacy_policy.md` is retired and its unique disclosures have been
   folded into the legal pack.
2. Replace the `support@civilcal.app` placeholder with a working, monitored
   address on the production domain. Play rejects a privacy policy whose
   contact bounces.
3. Publish the three policies at stable URLs, e.g. `/privacy`, `/privacy/ne`,
   `/privacy/hi`, and the terms at `/terms`.
4. Reconcile the Data Safety form against
   [data_safety_inventory.md](data_safety_inventory.md) — it is the
   code-traced answer key, not a guess.

### 3. Store assets and listing (can run in parallel)

| Asset | Status |
|---|---|
| 8 phone screenshots (Redmi 6A, live backend) | Done — `docs/store-assets/screenshots/` |
| Feature graphic 1024×500 | Done — `docs/store-assets/feature-graphic-1024x500.png` |
| Play icon 512×512 | Done — `docs/store-assets/play-icon-512.png` |
| Full/short description, title (en + ne) | Done — `android/fastlane/metadata/android/` |
| "What's new" per version | **Missing** — no `changelogs/` directory; add `2.txt` before uploading `1.0.2+2` |
| iOS screenshots | **Missing** — App Store needs its own set |
| iOS description | **Wrong** — it is a byte-copy of the Android text and says "built for Android" |

### 4. Play Console mechanics

1. Play account, app record, package `com.beardbishwo.lovemcq` (Gradle's
   `namespace` may still say `com.bisaas.bisaasmobile`; that is not the
   published id).
2. Upload the AAB (CI builds it on `main`; `deploy_android.yml` does the
   same on a `v*` tag). Signing uses the upload keystore; Play App Signing
   re-signs it — that is the app-signing fingerprint from step 1.4.
3. Data safety + content rating + ads declaration ("no ads").
4. Internal testing track → closed → production.
5. Account-deletion URL is mandatory for apps with accounts: Play requires a
   **web** URL even though deletion works in-app
   (Settings → Delete Account → `DELETE /api/v1/account`).

## What is already done and verified

- Host suite green in CI: 122 test files, 1,199 declarations; coverage floor
  55% enforced; `flutter analyze` clean.
- Device tests: 8 smoke tests on an emulator (API 28 and 30) in CI; 9/9 on
  the founder's Redmi 6A against the live Laragon backend, including the
  tenant-selection secure-storage round trip.
- Release artifact: AAB built by CI on `main`, signed with the upload key;
  certificate hash matches `SIGNING_CERT_HASH`.
- Release hardening: obfuscation + split symbols, pins fail closed, cleartext
  blocked in every build, backup/transfer disabled, AD_ID removed, only the
  shipping ABIs bundled.
- Security gate in CI: gitleaks, OSV dependency scan, and an artifact scan
  that unpacks the real APK and fails on forbidden content.
- Trilingual UI: 1,289 messages × en/ne/hi, coverage + consistency audits in
  CI.
- App Links: fingerprints are stored in Admin → Settings → Mobile App Settings
  and served by the Laravel route; no static identity file exists or may be
  restored.

## Decisions only the founder can make

| Decision | Why it is not a code question |
|---|---|
| Operating entity + governing law in the terms | Nepal entity vs otherwise; the terms currently assert Nepal law. |
| Free-forever vs subscriptions | There is **no billing library in the app and no IAP in the store listing**. The terms were corrected to match: coins are earned, not bought. Reintroducing paid tiers is a product + compliance change, not a copy edit. |
| Offline answering | Whether users may answer without the server. Until decided, the outbox stays unwired. See [PROJECT_STATE.md](PROJECT_STATE.md) §5 C1. |
| Sentry | `sentry_flutter` is a dependency but no `SENTRY_DSN` is configured, so it sends nothing. Either configure it or drop the dependency before the Data Safety form claims crash reporting. |

## Deliberately deferred

- **On-device E2E automation (Patrol).** Its native plugin would change the
  release artifact; the curated smoke suite plus the host journey test cover
  the same ground for now.
- **SSE tutor streaming.** Non-streaming endpoints are enough for launch;
  SSE is a web-only affordance until mobile demand is proven.
- **Hi locale in the store listing.** The app ships Hindi; the Play listing is
  English + Nepali because that is what the ASO research supports at launch.

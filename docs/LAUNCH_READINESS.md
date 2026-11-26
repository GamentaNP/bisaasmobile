# Launch readiness — historical store plan (voided) and the internal-test posture

> **STATUS — HISTORICAL, NOT CURRENT WORK.** The founder's 2026-09-11
> PERMANENT directive
> (`C:\laragon\www\bisaas\docs\mobileapp\MOBILE_RELEASE_DECISION_2026-09-11.md`)
> stands: the Flutter client is **never** published to Google Play or the App
> Store. Everything below about store submission, ASO, Play Console, store
> assets, a store Data Safety form or an iOS Team ID for submission is a record
> of a plan that was voided. Build/test facts and QA items are kept because the
> app remains an internal development and test instrument for `/api/v1`.

**Re-audited 2026-11-25; reconciled with the standing decisions 2026-11-26.**
This document retains the ordered critical path and founder decision list as
history, each marked with its current status. Mechanical build/test steps live
in [release_checklist.md](release_checklist.md); the historical store copy lives
in [store_listing.md](store_listing.md); the written policy lives in
[legal/](legal/).

It replaces `PLAY_STORE_READINESS.md` and `LAUNCH_ROADMAP.md`, two historical
store-launch plans that disagreed with each other about an old domain question
that is now closed.

## Infrastructure facts (still true; no store decision hangs on them)

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
blocker, and with no store submission there is no store step at all. Pins still
fail closed by design, so re-check them against the live chain after any
certificate renewal (add `CERT_PIN_3` for a rollover rather than pasting an
untried value).

## The former critical path — historical, voided by the 2026-09-11 directive

Sections 1–4 below are retained as the infrastructure and QA context for the
internal test build. None of it is current work, and none of it is a launch
blocker because there is no store launch.

### 1. Backend + TLS + App Links identity (test instrument; store steps historical)

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
   `https://lovemcq.com/.well-known/assetlinks.json`. The Play
   **app-signing** key fingerprint was for the voided store track only — there
   are no Play-installed builds. There is no `docs/ASSETLINKS.json` and a static
   `public/.well-known/assetlinks.json` must never be restored — a real file
   would shadow the config-driven route forever. See
   [APP_LINKS_DEPLOYMENT.md](APP_LINKS_DEPLOYMENT.md).

### 2. Legal + policy URLs (historical — no store form to block)

1. Pick the single publishable policy — `docs/legal/privacy-policy-en.md`
   (with `-ne` and `-hi` as linked translations). The older
   `docs/privacy_policy.md` is retired and its unique disclosures have been
   folded into the legal pack.
2. Replace the `support@civilcal.app` placeholder with a working, monitored
   address on the production domain. (The original reason — "Play rejects a
   privacy policy whose contact bounces" — is historical: there is no Play
   submission. The address still matters for a published policy.)
3. Publish the three policies at stable URLs, e.g. `/privacy`, `/privacy/ne`,
   `/privacy/hi`, and the terms at `/terms`.
4. The Data Safety form is voided with the store path.
   [data_safety_inventory.md](data_safety_inventory.md) remains the code-traced
   record of what the app does — including that `sentry_flutter` has no DSN and
   sends nothing — not a guess.

### 3. Store assets and listing (historical — never submitted)

These were prepared for a submission that is voided. No further screenshot,
ASO or listing work is current.

| Asset | Status at the time of the voided plan |
|---|---|
| 8 phone screenshots (Redmi 6A, live backend) | Done — `docs/store-assets/screenshots/` |
| Feature graphic 1024×500 | Done — `docs/store-assets/feature-graphic-1024x500.png` |
| Play icon 512×512 | Done — `docs/store-assets/play-icon-512.png` |
| Full/short description, title (en + ne) | Done — `android/fastlane/metadata/android/` |
| "What's new" per version | Was **missing** — no `changelogs/` directory; the old plan called for `2.txt` before uploading `1.0.2+2`, which never happened |
| iOS screenshots | Was **missing** — the old plan wanted a separate App Store set |
| iOS description | Was **wrong** — a byte-copy of the Android text saying "built for Android"; historical copy, never uploaded |

### 4. Play Console mechanics — VOID, do not do this

Recorded only because the old plan contained it. The 2026-09-11 directive
voids all of it: no account, app record, upload, track, rating, declaration or
deletion-URL work is to be done.

1. Play account, app record, package `com.beardbishwo.lovemcq` (Gradle's
   `namespace` may still say `com.bisaas.bisaasmobile`; that is not the
   published id).
2. Upload the AAB (CI builds it on `main`; `deploy_android.yml` does the
   same on a `v*` tag). Signing uses the upload keystore; Play App Signing
   re-signs it — that is the app-signing fingerprint from step 1.4.
3. Data safety + content rating + ads declaration ("no ads").
4. Internal testing track → closed → production.
5. Account-deletion URL was mandatory for apps with accounts: Play required a
   **web** URL even though deletion works in-app
   (Settings → Delete Account → `DELETE /api/v1/account`).

## Verified facts about the internal test build

- Host suite green in CI: 122 test files, 1,199 declarations; coverage floor
  55% enforced; `flutter analyze` clean.
- Device tests: 8 smoke tests on an emulator (API 28 and 30) in CI; 9/9 on
  the founder's Redmi 6A against the live Laragon backend, including the
  tenant-selection secure-storage round trip.
- Release artifact: AAB built by CI on `main`, signed with the upload key;
  certificate hash matches `SIGNING_CERT_HASH`. It is a **test build, not a
  submission candidate**.
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

## Former founder decision list — current status

These entries belonged to the voided store plan. Only the recorded decisions
below are settled; none of them is a launch blocker because there is no store
launch.

| Decision | Current status |
|---|---|
| Operating entity + governing law in the terms | Historical store-plan item, **moot for store submission** (no store). The terms currently assert Nepal law; no decision beyond the permanent no-store directive is recorded here. |
| Free-forever vs subscriptions | **SETTLED: no billing library and no IAP.** Coins are earned, not bought; server subscription state is display-only. The old "reintroducing paid tiers is a product + compliance change" framing treated an option that is now off the table. |
| Offline answering | **SETTLED: read-cache only.** The write outbox stays deliberately unwired because grading is server-authoritative. See [PROJECT_STATE.md](PROJECT_STATE.md) §5 C1. |
| Sentry | **Current truth:** `sentry_flutter` is bundled but no `SENTRY_DSN` is configured, so **it sends nothing** — no crash data is transmitted. That is the data-safety implication recorded in [data_safety_inventory.md](data_safety_inventory.md); no configure-or-drop decision is pending. |

Items C3 (iOS `IOS_TEAM_ID`) and C4 (social sign-in IDs) in
[PROJECT_STATE.md](PROJECT_STATE.md) §5 are **moot for store submission; they
may still be needed for on-device testing**. They are not launch blockers.

## Former deferrals — current status

- **On-device E2E automation (Patrol).** Under the 2026-09-11 directive this is
  a **QA tool, not a release gate**. Its native plugin would change the release
  artifact, so the curated smoke suite plus the host journey test remain the
  chosen coverage.
- **SSE tutor streaming.** Non-streaming endpoints are enough for the test
  instrument; SSE is a web-only affordance until mobile demand is proven.
- **Hi locale in the store listing.** The app ships Hindi; the historical,
  never-published store listing is English + Nepali, which is what the ASO
  research supported.

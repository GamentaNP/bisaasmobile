# Launch roadmap — bisaasmobile (CivilCal) → Play Store

Owner legend: **YOU** = founder decisions/actions (money, accounts, servers);
**AI** = work done in this repo in a session. The critical path runs through
Phase A — everything else can start in parallel.

## Phase 0 — start TODAY (longest lead time, zero code)

| # | Task | Owner | Time |
|---|---|---|---|
| 0.1 | Register a Play Console developer account ($25 one-time). Identity verification can take several days — this is why it is first. | YOU | 30 min + wait |
| 0.2 | Register the domain. `bisaas.com` is parked by a reseller (buy-back $2–5k — declined). Recommended: `civilcal.app` / `civilcal.com` (brand = product name). | YOU | 20 min |
| 0.3 | Provision hosting for the Laravel backend: VPS with PHP 8.3 + PostgreSQL + Redis (Hetzner/DO ~$6–12/mo, or a Nepali host if latency to Nepal matters). | YOU | 1 h |

## Phase A — backend production deployment (critical path)

| # | Task | Owner | Notes |
|---|---|---|---|
| A.1 | Point the domain DNS at the server; TLS via certbot (Let's Encrypt). | YOU | |
| A.2 | Deploy the bisaas Laravel repo: `.env` (APP_URL = new domain, DB, Redis), `migrate --seed`, queue workers (supervisor), scheduler (cron), storage link. | YOU | The repo is outside this workspace — I can generate the exact deployment runbook on request. |
| A.3 | Post-deploy verification: `GET /api/v1/app/config` returns JSON; login works with a seeded user; quiz catalogue returns rows. | AI | I verify from here and from the phone. |
| A.4 | Publish `/.well-known/assetlinks.json` (App Links verification) — content generated from the app's signing cert SHA-256. | AI generates / YOU publishes | |
| A.5 | Configure Firebase server-side (Filament → Firebase settings page): service account for FCM sends. | YOU | |

## Phase B — client repointing (AI, one session)

1. `lib/app/config/env.dart` prod host → the new domain.
2. Regenerate `CERT_PIN_1`/`CERT_PIN_2` from the live certificate chain
   (commands in `docs/PLAY_STORE_READINESS.md`).
3. `AndroidManifest.xml` https intent-filter hosts → new domain.
4. Version bump → `1.0.3+3`.
5. Rebuild release AAB + APK; full hardware QA on the Redmi against production
   (login, daily quiz, a full attempt, leaderboard).

## Phase C — store listing (parallel with A/B)

| # | Task | Owner |
|---|---|---|
| C.1 | Screenshots: home, quiz play, calculator, leaderboard, streak — captured against the live backend at 1080×2400 (first asset done: login). | AI |
| C.2 | Feature graphic 1024×500 (design asset — brand logo + wordmark on brand green). | YOU + design |
| C.3 | Privacy policy + Terms pages on the website (the backend must serve them). | YOU |
| C.4 | Data Safety form: entries enumerated in `docs/PLAY_STORE_READINESS.md` §3 (email/user id — account; device name + push token; crash logs; consent-gated analytics; device-integrity signals). | YOU (AI supplies the exact answers) |
| C.5 | Content rating questionnaire: education/quiz, no UGC feed, no ads → likely Everyone/PEGI 3. | YOU |
| C.6 | Listing copy: English draft done; finalize ne/hi store translations. | AI |

## Phase D — pre-launch hardening (AI, before the tag)

1. Rerun the full security audit with network enabled (`mimosa audit`) — the
   deep-scan components were unavailable during today's commits.
2. Decide the crash-reporting mix: Crashlytics is live; Sentry needs a
   `SENTRY_DSN` define — either provision it or stay Crashlytics-only for v1.
3. Backend: set `EnforceAppVersion` floor to the shipped version; verify
   `EnforceMobileKillSwitches` flags in Filament.
4. Upload-key hygiene: enroll in Play App Signing, back up the keystore
   OFF this machine.
5. Optional: an API-26 emulator added to the device-test matrix (the new floor).

## Phase E — release mechanics

1. Tag `v1.0.3` → `deploy_android.yml` builds and ships the signed artifacts.
2. Upload the AAB to the internal track; smoke-test the Play-delivered build
   on the Redmi (Play App Signing re-signs — verify the app runs from the
   store install, not just a local install).
3. Internal testing 1–2 weeks → closed testing → production rollout.

## Deliberately deferred (post-launch, with reasons)

- **Offline answer outbox**: built but unwired. Wiring it needs a server
  decision about accepting late answers (grading integrity). Keep unwired for v1.
- **TalkBack gap (API 26–33)**: Flutter engine bug disables the bridge —
  ~40% of the base. Track upstream; note accessibility status honestly.
- **Untested thin features** (search/downloads/onboarding/psc/settings).
- **EICE pattern analytics, question hints, per-user push segments** — feature roadmap.

## Infra cost at launch

Domain ~$10–15/yr · VPS ~$6–12/mo · Play Console $25 one-time. Everything else $0.

# CivilCal Privacy Policy

**Effective date:** 2026-11-04 (supersedes the 2026-10-25 version)
**Operator:** Bisaas (the "Service"), product name CivilCal
**Contact:** support@bisaas.com · **Security:** security@bisaas.com

This policy explains what data the CivilCal mobile app and its backend
collect, why, and what control you have. It applies to the Android and iOS
apps and the API that powers them. The Nepali and Hindi versions are
translations of this text; if they ever disagree, this English version is the
operative one.

## 1. What we collect

**Account data** — your name, email address and profile photo. If you sign in
with Google or Apple, we receive the identifier and basic profile those
providers share. This is required to create and secure your account.

**Study data** — quiz attempts, answers, scores, streaks, coins, achievements
and leaderboard standing. This is the service itself: grading, progress and
rankings are computed on our servers, and the app displays the results.

**Device and technical data** — a random install identifier, app version,
platform, device name, and your push-notification token. Crash reports
(Firebase Crashlytics) are collected when the app malfunctions. A
device-integrity signal (clean / suspicious / compromised), produced by the
Talsec freeRASP library, is sent with requests to prevent fraud and abuse.

**Battle data** — when you join an online battle, the lobby state (who is in
the match, whose turn it is, the score) is stored in Google Firebase Realtime
Database so both players see the same match. Your account identifier is part
of that state while the lobby exists.

**Guest and visitor data** — if you use the app without signing in, we create
an anonymous visitor identifier so your progress survives a restart and so we
can measure whether the guest experience works. It is not linked to a name or
email unless you later create an account.

**Analytics** — app-interaction events (Firebase Analytics), **only if you opt
in**. Analytics are off until you accept them through the consent sheet shown
on first launch, and you can withdraw at any time in Settings. Turning
analytics off stops new events; it does not retroactively delete counts
already recorded. The operational data described above (account, study,
device, crash and integrity data) is processed to run the service and is not
governed by the analytics consent.

**AI features** — if you use the AI tutor or calculator assistance, the text
of your question and its context are processed by an AI provider to generate
the answer. If you connect your own AI key ("bring your own key"), the key is
stored write-only on our servers and is never displayed again in full — only a
masked preview.

**Local device data** — your session token is kept in the device's secure
storage, and a small offline cache (e.g. the daily quiz pack, downloaded
courses) is kept in the app's local database. Backups and device-to-device
transfer of this data are blocked at the system level.

## 2. What we do not do

- We do not show third-party ads and there is no advertising SDK in the app.
  The Android advertising identifier is explicitly removed from the build.
- We do not sell or rent your personal data.
- We do not collect your location, contacts, camera, microphone or photo
  library.
- We do not enable analytics before you consent.
- We do not use your study data for advertising.

## 3. Legal bases

Where applicable law requires a basis: account and study data are processed to
perform the service you requested (contract); analytics are processed on the
basis of your consent; fraud prevention, security and service integrity are
legitimate interests.

## 4. Third parties

| Provider | Purpose | Data |
|---|---|---|
| Google (Firebase Analytics) | Opt-in product analytics | Interaction events, a random app-instance id |
| Google (Firebase Crashlytics) | Crash diagnosis | Stack traces, device model, OS version, app version |
| Google (Firebase Cloud Messaging) | Push notifications | Device push token |
| Google (Firebase Realtime Database) | Live battle lobbies | Lobby state and the participant identifiers |
| Google / Apple sign-in | Authentication | The identifier and profile you authorise |
| Talsec freeRASP | Device-integrity signal | App integrity verdict; no personal content |
| AI provider | Generating tutor/calculator answers | The prompt you send and its context |
| Hosting provider | Running the backend | All service data, under a data-processing agreement |

A secondary crash-reporting SDK (Sentry) is present in the app's dependencies
but **is not enabled in the shipped build** — no reporting endpoint is
configured, so it transmits nothing. If that changes, this policy changes
first.

Each provider processes data under its own terms. We share only what the
purpose requires.

## 5. Retention

| Data | How long |
|---|---|
| Account and learning activity | While your account is active; removed from live systems within 30 days of deletion, from backups within 90 days |
| Crash reports | Up to 90 days |
| Usage events | Up to 14 months, then only aggregate counts remain |
| Anonymous visitor profile and intent events | Until you erase it, or 13 months after your last visit |
| Server request logs | 30 days |
| Calculator telemetry (guest calculations) | 7 days |
| Battle lobby state | Deleted shortly after the match ends |

## 6. Account deletion

You can delete your account **inside the app**: Settings → Delete Account,
confirmed by typing `DELETE`. Deletion removes your account and personal data
from our systems and cannot be undone. Residual copies in encrypted backups
are purged within 90 days.

If you cannot open the app, deletion can also be requested from the web page
at the operator's `/account/delete` address; the same erasure applies.

Uninstalling the app removes all device-local data; it does **not** delete
your server account.

## 7. Your rights

You may access, correct, export or delete your personal data, object to
processing, and withdraw consent at any time: in the app's settings, or by
contacting support@bisaas.com. We respond within 30 days.

## 8. Children

CivilCal is an exam-preparation service for students of civil engineering and
is not directed at children under 13. We do not knowingly collect data from
children under 13; if we learn we have, we delete it.

## 9. Security

Data travels over TLS with certificate pinning in the app. Passwords are
hashed server-side; session tokens are stored only in device secure storage,
and Android backups of that storage are disabled. Access to production data is
restricted to the operator. A security issue can be reported to
security@bisaas.com.

## 10. Changes

We will announce material changes to this policy in the app before they take
effect. Continued use after an announcement means acceptance. The effective
date at the top always identifies the current version.

## 11. Contact

Bisaas — support@bisaas.com

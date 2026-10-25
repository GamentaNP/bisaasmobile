# Legal pack — ready to publish

Six files: privacy policy and terms, each in English, Nepali and Hindi.

**Before publishing (Phase A of the launch roadmap):**

1. The contact address `support@civilcal.app` is a placeholder — replace it
   with the real mailbox on whichever domain is registered.
2. Publish `privacy-policy-en.md` as the policy URL in the Play Data Safety
   form. Host the Nepali and Hindi versions alongside it and link them from
   the same page (the app is served in all three languages).
3. The terms' governing law is written as Nepal. Change it if the operating
   entity is incorporated elsewhere.
4. Every factual claim in the policy is true of the codebase as of
   2026-10-25: analytics behind the first-launch consent sheet, account
   deletion at `DELETE /api/v1/account` with server-side erasure, write-only
   BYOK keys, backup/transfer blocked, cert pinning on. If any of that
   changes, update the policy in the same commit.

Play Console mapping: the Data Safety form in `docs/PLAY_STORE_READINESS.md`
mirrors section 1 of the privacy policy — keep them in sync.

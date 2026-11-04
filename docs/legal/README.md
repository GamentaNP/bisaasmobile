# Legal pack — publishable text

Six files: a privacy policy and terms of service, each in English, Nepali and
Hindi. The English text is operative; the other two are translations of it and
say so in their first paragraph.

| File | Purpose |
|---|---|
| `privacy-policy-en.md` | The policy URL for the Play Data Safety form and the App Store privacy field. |
| `privacy-policy-ne.md`, `privacy-policy-hi.md` | The same policy for the two non-English interfaces. Publish alongside, linked from the English page. |
| `terms-en.md`, `terms-ne.md`, `terms-hi.md` | Terms of service. |

**Status on 2026-11-04:** the text is complete and matches the code — analytics
behind the first-launch consent sheet, in-app account deletion at
`DELETE /api/v1/account`, write-only BYOK keys, backup/transfer blocked, cert
pinning on, no billing library anywhere. Contacts are `@bisaas.com`. The
remaining work is publishing, not writing.

## Before publishing

1. **The domain must be live.** `bisaas.com` currently redirects to a domain
   broker; the `@bisaas.com` addresses in this pack do not work until it is
   owned and configured. See `../LAUNCH_READINESS.md`. If the launch moves to
   another domain, every address in these six files changes with it.
2. Publish `privacy-policy-en.md` at a stable URL (e.g. `/privacy`), with the
   Nepali and Hindi versions at linked URLs (`/privacy/ne`, `/privacy/hi`).
3. Publish the terms at `/terms` (and `/terms/ne`, `/terms/hi`).
4. The terms state Nepal as the governing law. Change it if the operating
   entity is incorporated elsewhere.
5. Play also requires a **web** account-deletion URL even though deletion works
   in-app. Point it at a page that describes the in-app path and offers a
   request form; the policy names `/account/delete` as that address.

## Keeping it true

Every claim in the policy is traceable to the code. When one of these changes,
the policy changes in the same commit:

- the consent gate (`lib/core/consent/consent_gate.dart`);
- account deletion (`DELETE /api/v1/account`, Settings → Delete Account);
- the retention table — it restates the server's prune schedules;
- the third-party list — adding an SDK with a network call adds a row;
- the Sentry line: the SDK is bundled but **inactive without a `SENTRY_DSN`**,
  so it is disclosed as inactive. Configuring it makes that sentence false.

The Data Safety answers live in `../data_safety_inventory.md`; they must agree
with §1 and §5 of the policy.

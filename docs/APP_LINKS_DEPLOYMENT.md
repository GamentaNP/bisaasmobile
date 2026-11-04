# Android App Links — the file that must be served, and how to verify it

> **Prerequisite, currently unmet (2026-11-04):** `bisaas.com` does not serve
> this application — it 302s to a domain broker. The file below cannot be
> deployed until the domain resolves to the app server and serves TLS. See
> [LAUNCH_READINESS.md](LAUNCH_READINESS.md). Everything else in this file
> stays correct once that is done.

Android verifies `https://bisaas.com` links against a file published by the
**server**, not by this app:

```
https://bisaas.com/.well-known/assetlinks.json
Content-Type: application/json
```

`docs/ASSETLINKS.json` in this repository is the exact file for this build's
upload certificate. It was generated from the release keystore and checked
against `SIGNING_CERT_HASH` in `dart_defines/production.json`:

| Field | Value |
|---|---|
| package | `com.bisaas.bisaasmobile` (from `android/app/build.gradle.kts:144`) |
| SHA-256 | `21:D8:6E:E5:00:01:3B:5E:BE:13:E2:13:C9:6F:C2:DB:74:1F:AA:B8:EB:7D:95:8C:B7:19:B4:58:21:8A:D4:1E` |
| source of truth | upload keystore (`android/key.properties` → `storeFile`), alias `upload` |

The hash in `production.json` is the same value base64-encoded
(`sha256/Idhu5QABO16+E+ITyW/C23QfqrjrfZWMtxm0WCGK1B4=`); both were compared on
2026-11-04.

## Deploy

1. Copy `docs/ASSETLINKS.json` to the Laravel server as
   `public/.well-known/assetlinks.json` (the directory does not exist yet —
   create it). Do not rename the file.
2. Ensure the web server serves dot-directories. Apache does by default under
   `DocumentRoot`; verify with the probe below.
3. Deploy. The file must be reachable **without** a redirect and with
   `application/json`.

## Play App Signing — the trap

If the app is enrolled in Google Play App Signing (the default for new apps),
Google re-signs the AAB with an **app-signing key** that is not this upload
key. `assetlinks.json` must then contain **both** fingerprints:

* the upload key above (used by local/release builds you install yourself),
* the **app signing key SHA-256 from Play Console → Release → Setup → App
  signing** (used by installs from the Play Store).

With only the upload key, links verify on a sideloaded build and fail on every
Play-installed build.

## Verify

```bash
curl -s https://bisaas.com/.well-known/assetlinks.json | head
adb shell pm get-app-links com.bisaas.bisaasmobile
adb shell pm verify-app-links --re-verify com.bisaas.bisaasmobile
```

`get-app-links` must report `verified` for `bisaas.com`. Until then, an
`https://bisaas.com/...` link opens a browser; the `civilcal://` scheme is
unaffected.

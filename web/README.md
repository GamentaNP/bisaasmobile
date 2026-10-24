# Web target notes

## Drift web worker (required for `flutter run -d chrome`)

`drift_worker.js` is a generated third-party artifact from the `drift`
package and is deliberately NOT committed (it is 354 KB of minified
generated code, and static scanners flag it forever after). Copy it in
before the first web run — it is already gitignored:

```bash
cp "$(ls -d ~/AppData/Local/Pub/Cache/hosted/pub.dev/drift-2.35.3 2>/dev/null || ls -d ~/AppData/Local/Pub/Cache/hosted/pub.dev/drift-* | tail -1)/drift_worker.js" web/
```

The database reads it at `driftWorker: Uri.parse('drift_worker.js')` —
see `lib/core/storage/database/app_database.dart`.

Gate pass verified 2026-10-24.

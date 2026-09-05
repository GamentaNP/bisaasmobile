#!/usr/bin/env bash
# scan_release_artifact.sh — the mobile release security gate's artifact scan
# (security plan W2.8).
#
# Scans a built Android/iOS artifact for content that must never ship:
#   - credentials and secrets (.env, *.pem, *.key, service-account JSON)
#   - premium/answer/question-bank/private asset bundles
#   - local databases (.db / .sqlite)
#   - Dart VM snapshots and debug symbol / mapping files that would defeat
#     the --obfuscate step (app.dill, mapping.txt, *.dSYM, snapshot blobs)
#
# Usage:  scripts/scan_release_artifact.sh build/app/outputs/.../app-release.apk
# Exit 0 = clean, exit 1 = forbidden content found (or artifact unreadable).
# CI calls this right after the obfuscated release build; it is also safe to
# run locally against any apk/aab/ipa/zip.
set -euo pipefail

ARTIFACT="${1:-}"
if [[ -z "$ARTIFACT" || ! -f "$ARTIFACT" ]]; then
  echo "usage: $0 <path-to-apk|aab|ipa|zip>" >&2
  exit 1
fi

# Forbidden path patterns inside the archive (matched as case-insensitive
# substrings of the entry name). Keep this list in lockstep with the W2.8
# row of docs/mobileapp/BISAAS-SECURITY-MASTER-PLAN-2026.md.
# Note: database patterns require a real extension match — AndroidX ships
# `*.version` metadata files like androidx.sqlite_sqlite-framework.version
# whose names merely CONTAIN 'sqlite'; substring-matching '.sqlite' there
# would false-positive on every build.
FORBIDDEN=(
  '.env'
  '.pem'
  '.key'
  'service-account'
  'assets/premium/'
  'assets/answers/'
  'assets/question-bank/'
  'assets/private/'
  '.db'
  '.sqlite'
  '.sqlite3'
  'mapping.txt'
  '.dSYM'
  'app.dill'
  'snapshot_blob'
  'vm_snapshot'
  'isolate_snapshot'
)

echo "Scanning $(basename "$ARTIFACT") ($(du -h "$ARTIFACT" | cut -f1)) for forbidden content…"

VIOLATIONS=$(unzip -Z1 "$ARTIFACT" 2>/dev/null | while IFS= read -r entry; do
  lower="$(echo "$entry" | tr '[:upper:]' '[:lower:]')"
  for pattern in "${FORBIDDEN[@]}"; do
    if [[ "$pattern" == .* ]]; then
      # Extension-style pattern (starts with '.'): must END the entry name.
      # Prevents false positives like androidx.sqlite_sqlite-framework.version,
      # whose name merely contains 'sqlite'.
      if [[ "$lower" == *"$pattern" ]]; then
        echo "$entry [matches: $pattern]"
        break
      fi
    elif [[ "$lower" == *"$pattern"* ]]; then
      # Substring pattern (paths like assets/premium/).
      echo "$entry [matches: $pattern]"
      break
    fi
  done
done)

if [[ -n "$VIOLATIONS" ]]; then
  echo ""
  echo "FORBIDDEN CONTENT FOUND in $ARTIFACT:" >&2
  echo "$VIOLATIONS" >&2
  echo "" >&2
  echo "The release artifact must not ship credentials, premium/answer assets," >&2
  echo "local databases, or de-obfuscation material. Fix the build inputs —" >&2
  echo "do NOT add these files to an ignore list here." >&2
  exit 1
fi

echo "Artifact scan clean: no forbidden content found."
exit 0

# Localisation — CivilCal

The app ships **English, Nepali and Hindi**. This document says exactly
what is translated, what is not, and how the gap is kept honest.

---

## 1. The rule the app follows

> A language picker is a promise.

A user who cannot read English picks their own language and gets an
English interface back. They do not conclude "this screen is not
translated yet" — they conclude **the app is broken**. That is strictly
worse than the language not being offered at all.

So the rule is: **the app offers a language whose interface it can
actually deliver.** The registry in
`lib/app/localization/app_languages.dart` is seeded with exactly the
languages that have an ARB file, and
`test/app/language_honesty_test.dart` asserts that the registry and the
ARB directory agree in both directions. Adding a language is a two-step
change — write the ARB, then add the registry entry — and cannot silently
half-happen.

---

## 2. What is translated today

**The core journey** — the path from install to a finished quiz — is
translated into all three languages:

| Area | Files |
|---|---|
| Sign-up, sign-in, password reset, email verification | `lib/features/auth/presentation/` |
| Onboarding (target exam, daily goal, current level) | `lib/features/onboarding/` |
| Quiz browse, intro, attempt, result, review, guest funnel | `lib/features/quiz/presentation/` |
| Calculator browse, detail, history, assistant, worked solution | `lib/features/calculator/presentation/` |
| Home dashboard | `lib/features/home/` |
| Privacy choices and the stored-data screen | `lib/core/consent/`, `lib/features/privacy/` |
| The daily study reminder notification | `lib/core/notifications/` |
| Force-update, maintenance, unsupported version, unknown route | `lib/app/` |

247 messages, each written in English, Nepali and Hindi.

**Everything else** — the tutor, the coaching dashboard, live events,
the leaderboard, the economy and store, the library, the syllabus tree,
the AI settings, the book reader, the game worlds — is still English.

That is **893 user-facing strings** out of 1140.

---

## 3. How the gap is kept honest

Three tools, all checked in:

| Tool | What it does |
|---|---|
| `tool/localization_coverage.dart` | Parses every file under `lib/` with the Dart analyzer, finds the string literals that reach the user, and reports which come from the ARB and which are hardcoded English. |
| `tool/apply_localization.py` | Rewrites the hardcoded literals to `l10n.<key>`, mapping each English string to its ARB key. |
| `tool/apply_localization_plumbing.py` | Adds the import and the `l10n` binding the rewritten strings need. |
| `tool/generate_arb.py` | The master copy table. English, Nepali and Hindi live side by side in one file, and the script writes the three ARB files from it — so the three locales cannot drift apart. |

And the test that holds the line:

**`test/app/localization_coverage_test.dart`** asserts that the core
journey contains **zero** hardcoded user-facing strings, and that the
number outside it does not grow (a ratchet at 893). Adding a screen in
English changes that number in the diff, so it is a decision rather than
an invisible drift.

Run the measurement by hand:

```bash
dart run tool/localization_coverage.dart            # summary per file
dart run tool/localization_coverage.dart --verbose  # every string, with a line number
dart run tool/localization_coverage.dart --keys     # the distinct strings
```

---

## 4. Writing a new translation

1. Add the key to `tool/generate_arb.py` — English, Nepali and Hindi on
   one line each, with the placeholder names.
2. Run `python tool/generate_arb.py` and `flutter gen-l10n`.
3. Replace the literal in the code with `l10n.<key>`. Inside a widget,
   bind it once:

   ```dart
   final l10n = AppLocalizations.of(context)!;
   ```

   Outside a widget — a service, a controller, a data source — use
   `appL10n()` from `lib/app/localization/l10n.dart`, which looks the
   locale up without a `BuildContext`.

4. If the message has placeholders, the generated member is a **method**,
   not a getter: `l10n.quizResultCorrectOf(correct, total)`.

---

## 5. The bits that are not translated, and why

| String | Why |
|---|---|
| `support@bisaas.com`, `privacy@bisaas.com` | An address, not copy. Translating it would break it. |
| The debug auto-login button | Only exists in a `kDebugMode` build. It never reaches a user. |
| Numbers, separators, counters (`12/20`, `•`, `+50 XP`) | A literal with no word in it cannot be translated. The measurement skips them, so a screen full of counters is not counted as untranslated copy. |

---

## 6. Known gaps

- **The rest of the app is English.** 893 strings across 30-odd screens.
  The tutor and the coaching dashboard are the largest, and both are
  secondary to the study loop.
- **`hi` is offered but thinner than `ne`.** Both have the same 247
  messages, so the coverage is identical — but the Hindi copy has had
  less review. If the launch market is Nepal, `hi` could be dropped from
  the picker until someone has checked it.
- **The `zh` locale is deliberately absent.** The server has no `zh`
  row, so offering it would promise translated questions that do not
  exist.
- **The server drives the question language**, not the client. The
  `Accept-Language` header carries the user's choice, so the *content*
  is localised even where the *chrome* is not. That is why the picker is
  worth having even before the chrome is finished.

# Localisation — CivilCal

The app ships **English, Nepali and Hindi**. This document says exactly
what is translated, how the copy is kept honest, and where the boundary
is.

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

**Everything.** 993 messages, in English, Nepali and Hindi, covering
every screen in the app:

| Area | Screens |
|---|---|
| First run | onboarding, target exam, daily goal, current level |
| Auth | sign-up, sign-in, forgot password, reset password, email verification, social sign-in |
| The study loop | quiz browse, intro, attempt, result, review, guest funnel, practice drill, self-challenge, numericals |
| The AI | tutor chat, tutor onboarding, study plan, insights, revisions, weekly report, AI usage, AI keys |
| Content | library browser and detail, books and the reader, syllabus tree and blueprints, courses, learning tracks, today plan, reviews due, goals, downloads |
| Progress | home dashboard, profile, streak (freeze, repair, insurance, wager), rewards, achievements, leaderboard, gamification |
| Competition | contests, live events, battle, coaching, EICE, game worlds, missions |
| Money | wallet, ledger, coin shop, inventory, donations, premium store, wardrobe, referral |
| Social | invite friends, referral codes, shared challenges, notifications, search |
| The app itself | privacy choices, stored data, settings, force update, maintenance, offline banner, error and empty states |

**Four strings in the whole of `lib/` are not translated**, and all four
are correct:

| String | Why |
|---|---|
| `support@bisaas.com` | An email address, not copy. Translating it would break it. |
| `OK (cached)` | A synthetic HTTP status message. It is never shown to a user. |
| The debug auto-login button | It only exists in a `kDebugMode` build, so it is compiled out of a release. |
| `C` | The avatar fallback: the first letter of the display name. |

---

## 3. How it is kept honest

Four tools, all checked in:

| Tool | What it does |
|---|---|
| `tool/generate_arb.py` | The master copy table. English, Nepali and Hindi sit side by side in one file and the script writes the three ARB files from it, so the locales cannot drift apart. It also **validates** that every `{placeholder}` in a message is declared — a mismatch is a build-time error, not a screen that quietly stayed English. |
| `tool/localization_coverage.dart` | Parses every file under `lib/` with the Dart analyzer and reports the string literals that reach the user. A literal with no letter in it — a counter, a separator — is skipped, because a screen full of numbers is not untranslated copy. |
| `tool/apply_localization.py` | Rewrites those literals to `l10n.<key>`. It removes the `const` chain the literal sat in (a getter call is not a constant expression) and calls the generated member with the original interpolated expressions, because a message with placeholders is a method and not a getter. |
| `tool/apply_localization_plumbing.py` | Adds the import and the `l10n` binding the rewritten strings need. |

And the test that holds the line:

**`test/app/localization_coverage_test.dart`** asserts that **the whole
app** contains no hardcoded user-facing string, apart from the four
documented exceptions. There is no ratchet to widen and no tier to
finish: the boundary is the edge of the app.

Run the measurement by hand:

```bash
dart run tool/localization_coverage.dart            # summary per file
dart run tool/localization_coverage.dart --verbose  # every string, with a line number
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
   `appL10n()` from `lib/app/localization/l10n.dart`, which resolves the
   locale without a `BuildContext` and cannot throw.

4. If the message has placeholders, the generated member is a **method**,
   not a getter: `l10n.quizResultCorrectOf(correct, total)`.

5. The placeholder types are all `Object`. A narrower type makes the
   *client* the place where a mismatch is found, and the mismatch is a
   compile error in a screen that was correct the moment the server
   changed a field from a count to a label. `Object` accepts whatever
   the caller has; a nullable value is coalesced at the call site, where
   the screen knows what to show.

---

## 5. Known gaps

- **`hi` has had less review than `ne`.** Both have the same 993
  messages, so the coverage is identical, but the launch market is
  Nepal and the Hindi copy has not been read by a Hindi speaker. If the
  launch is Nepal-only, dropping `hi` from the picker until someone has
  checked it is the honest option.
- **The `zh` locale is deliberately absent.** The server has no `zh`
  row, so offering it would promise translated questions that do not
  exist.
- **The server drives the question language**, not the client. The
  `Accept-Language` header carries the user's choice, so the *content*
  is localised independently of the chrome.

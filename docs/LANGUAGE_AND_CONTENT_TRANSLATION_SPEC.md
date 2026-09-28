# Language & Content Translation Specification

> **Status:** canonical. This document exists so the multilingual model does not
> have to be re-explained in conversation again.
> **Scope:** the whole Bisaas product (web, admin, API, Flutter client). Business
> logic is server-authoritative; the Flutter client renders and localises only.
> **Last verified against code + live dev DB:** 2026-09-28.

---

## 1. Why this document exists

Bisaas is a **worldwide, enterprise-grade** product, not a Nepal-only app. Language
is therefore a first-class product dimension, not a Nepali convenience feature.

The previous failure mode was answering "which languages?" with a hardcoded list.
That is the wrong question: a **language** is a locale, a **font** is a **script**,
and a user can read an English interface and still type a Nepali note. This spec
separates the two and makes both open-ended.

---

## 2. Vocabulary — the four distinct concepts

These are conflated in the current codebase and must stay distinct.

| Term | Meaning | Stored where (today) |
|---|---|---|
| **UI locale** | Language of buttons, labels, navigation. Never content. | `users.locale`, `user_language_preferences.ui_locale` |
| **Canonical locale** | The pivot language content flows *through*. English by default, configurable per tenant. | `config('localization.canonical_locale')` → `CONTENT_CANONICAL_LOCALE` |
| **Source language** | The language a specific piece of content was *authored* in. | `quiz_questions.canonical_locale` (per question — note: this column name is misleading, see §8) |
| **Target language** | A language content may be *translated into*. | `translation_directions.target_locale` (per pair) |

> **`quiz_questions.canonical_locale` is misnamed.** It holds the question's
> authored language, not the global canonical locale. All 10,629 live questions
> have it set to `en`. Renaming it is on the migration list (§7).

---

## 3. The core rule

```
Content flows  source → canonical  AUTOMATICALLY.
Content flows  canonical → any target  ONLY for pairs the admin explicitly enables.
Nothing is ever served to a user before it is human-verified.
```

Three consequences, stated as rules:

- **R1** — A question authored in Nepali is **stored in Nepali**, always. The
  original is never overwritten or discarded.
- **R2** — If the `(ne → en)` direction is `auto`, an English translation is
  produced. If it is `off`, the question simply has no English translation and
  **stays Nepali**. This is the "admin set content to English" case.
- **R3** — A translation only becomes visible to learners after a human approves
  it. AI output is a *candidate*, never served content.

---

## 4. The scenario, encoded

This is the founder's model, stated precisely enough to implement.

### 4.1 Default: English is canonical

| Author writes in | Stored as | `ne→en` mode | Learner in Nepal sees |
|---|---|---|---|
| English | `en` | n/a (is canonical) | English |
| Nepali | `ne` | `auto` | English **after** English translation is verified |

### 4.2 Admin authors Nepali, translation to other languages is OFF

| Step | Result |
|---|---|
| Admin writes a Nepali question | Row saved with source `ne`, text in Nepali |
| `ne→en` is `off` | No English translation generated |
| `ne→zh` is `off` | No Chinese translation generated |
| Learner opens it | **Nepali**, unmodified. Nothing lost. |

This is the "save in Nepali and English but do not translate further" case — and
it is correct: the content simply has one language, its own.

### 4.3 Admin enables "translate all → English and Chinese"

| Step | Result |
|---|---|
| Admin writes a Nepali question | Row saved with source `ne` |
| Admin sets `ne→en` = `auto`, `ne→zh` = `auto` | Both queued for AI translation |
| AI produces candidates | Rows written with `status = auto_translated`, `reviewed_by = NULL` |
| **Not served yet** | `translationFor()` serves only `verified` / `human_reviewed` |
| Admin reviews in Filament → `verify` | `status = human_reviewed`, `reviewed_by` set |
| Learners now see | English or Chinese per their own preference |

### 4.4 Admin authors Nepali but the *global canonical* is English

Unchanged by admin intent — `canonical_locale` is per-question, and the direction
matrix decides. A tenant can set `CONTENT_CANONICAL_LOCALE=ne` and the whole
matrix adapts with no code change (`TranslationDirectionService.php:10-14`).

### 4.5 Learner in another country

Country → locale mapping already works via `GET /api/v1/country-languages`
(62 countries seeded). `IN`→`hi`, `BD`→`bn`, `LK`→`ta`, `SA`/`EG`/`QA`→`ar`,
`ES`/`MX`→`es`, `FR`/`BE`/`CH`→`fr`. **All others default to `en`, including `CN`,
`JP`, `KR`, `DE`, `RU`.** Adding Chinese means adding a `zh` row and a `CN`
mapping, not changing code.

### 4.6 A learner types in their own language

Notes, search, free-text answers, and AI-tutor chat are **rendered, never
translated**, in whatever script the user typed. This is already handled — see §6.

---

## 5. What the learner sees — `question_view_mode`

`user_language_preferences.question_view_mode` already models this. Validated
values: `native | bilingual | canonical`. **It is stored but never used to serve
anything** (§7, gap G1).

| Mode | Behaviour | Requires |
|---|---|---|
| `native` | Show the question in its authored language | nothing |
| `canonical` | Show the canonical-language (English) version | a verified canonical translation, else fall back to native |
| `bilingual` | Native primary + canonical secondary | both |

Per-user switches that already exist in the schema and must be honoured:

- `auto_translate_questions` (default `true`) — request translation automatically
- `show_original_toggle` (default `true`) — offer an "original" / "translation"
  switch on the question
- `primary_locale` — the language this learner wants content in
- `spoken_locales` — what they actually read, used for auto-translate decisions

---

## 6. Client rendering — all scripts, always

**Status: DONE (`d938dd5`).** Recorded here because it is a permanent property,
not a feature to re-implement.

- Script is detected from **Unicode codepoint ranges of the actual text**, not
  from a language list. A language nobody registered still renders.
- Fonts resolve as a **per-glyph fallback chain** ending in a generic family, so
  a script missing from the chain falls through to the platform's own Noto face
  rather than rendering as tofu.
- All 15 text styles carry the chain. Previously 14 forced `InstrumentSans` with
  no fallback, and that face has no Devanagari/CJK/Arabic/Tamil/Telugu glyphs.
- Negative tracking is dropped for joining scripts. Only `displayLarge` tightens
  (`-0.25`); every other style uses positive tracking, which is safe everywhere.
- Tests cover Khmer, Sinhala, Thai, Lao, Hebrew, Georgian, Armenian, Ethiopic,
  Myanmar, Tibetan, Malayalam, Kannada, Oriya, Gujarati, Gurmukhi — none of which
  are in the app's language registry. That is the point.
- The **language registry is server-driven** (`49c7145`): `AppLanguages.adopt()`
  installs a registry from `GET /api/v1/languages` and the seeded list is only
  the fallback, so adding a language worldwide is a server change rather than a
  client release. English is always retained and sorted first, because it is the
  canonical fallback — a server that omits it, or an empty response, must not
  leave the app with no language. Direction is derived from the **script**, not
  from the server's `direction` field, so a server that wrongly reports Arabic
  as `ltr` cannot make Arabic lay out left-to-right.
- **ARB coverage is gated in CI** (`49c7145`): `tool/arb_coverage.dart` reports
  per-locale coverage, untranslated keys, dead keys and placeholder drift, and
  exits non-zero when a locale is incomplete. This is necessary because
  generated l10n classes compile fine with a missing key and fall back to
  English at runtime, so a 90%-translated locale otherwise ships a
  mixed-language UI that no check notices.

**Remaining client gap:** the ARB catalogue has **21 keys against ~266 English
source files**. Rendering is solved; *interface strings* are not. See §9.

---

## 7. Server gaps — the handoff

Verified 2026-09-28 against source and the live dev database. These are ordered by
severity. The backend is owned by another agent; this section is the contract that
work must satisfy.

### G1 — There is no working translated-content read path. **Blocking.**

`quiz_question_translations` has **0 rows**. `QuestionTranslationService::resolve()`
is **never called from any controller**. No API resource returns a `translations`
key. Consequence: even with 100% translated content, every learner would see
English. The write side is built and reviewed; the read side does not exist.

Required: resolve a translation on the question-serving path
(`GET /api/v1/quiz/questions`, `/courses/{course}/questions`, `/quiz/daily`,
`/concepts/{concept}/questions`, `/questions/{question}/content`) using
`QuestionTranslationService::translationFor()` with the caller's locale and
`question_view_mode`, honouring the verified-only rule, and fall back to the
authored text when no verified translation exists.

### G2 — No `locale` parameter on question retrieval. **Blocking.**

Only `GET /api/v1/quiz/questions?filter[language]` exists, and it is a **corpus
filter** (`WHERE canonical_locale = ?` — narrows results to questions *authored*
in that language) that returns **untranslated** base text. None of the other
question routes accept a locale at all. A client cannot request a translated
question set.

Required: a `locale` (or `view_locale`) parameter meaning "render this in this
language", distinct from the existing `language` corpus filter, on every
question-serving route.

### G3 — Six divergent locale lists. **Correctness risk.**

| List | Contents |
|---|---|
| `config('app.supported_locales')` | `en, es, fr, ar, ne, hi, bn, ta, te` — **the only validated list** |
| `UserLocaleResolver::SUPPORTED_LOCALES` | 7 codes — **missing `ta`, `te`** |
| `TranslationCorpusReadinessService::SouthAsianTargetLocales` | `ne, hi, bn, ta, te` |
| `AiTranslationService::SUPPORTED_LANGUAGES` | 11 codes incl. `zh`, `de`, `ja`, `ko`, `pt` — **disconnected from `languages`** |
| `country_language_map.default_locale` values | 62 rows |
| Client `AppLanguages.all` | 10 codes incl. `zh` — **disconnected from `languages`** |

Required: one source of truth. Either `languages` becomes the registry that
validates, or `config('app.supported_locales')` is generated from it. `zh` must be
added to both `languages` and `translation_directions` if Chinese is in scope.

### G4 — No `GET /languages` route.

`languages` (`code`, `label_en`, `native_name`, `direction`, `is_question_target`,
`is_ui_locale`, `sort_order`) is **only** consumed by the Filament Localization
Studio dropdown. It is never served over the API, so the client duplicates it.

Required: `GET /api/v1/languages` returning the registry. The client
`AppLanguages` list is already keyed on `code` and can be swapped for a fetch with
no other change.

### G5 — `direction`, `is_ui_locale`, `is_question_target` are never read.

All three columns are declared and seeded but have **zero readers**. The web
chrome uses a separate hardcoded `config('app.supported_locale_options')` array.
Required: either read these columns everywhere or delete them.

### G6 — No question export; no question translation import.

- Import exists: `quiz:question-bank-import` (**JSONL only**),
  `quiz:import-source-file` (`.txt`/`.md`). Neither targets
  `quiz_question_translations`.
- **Export does not exist** for questions. `app/Filament/Exports` does not exist.
- `LocalizationStudio` has CSV/JSON import/export, but only for the `translations`
  table (UI strings), not questions.

Required: export/import for question translations, so a translator can work in a
spreadsheet and hand results back. This is a hard requirement for the
"admin will write or import/export that question" scenario.

### G7 — Dead and misleading code.

| Item | Status |
|---|---|
| `translation_cache` table | **0 rows, model referenced nowhere.** The real cache is the Laravel `Cache` facade in `OpenAiQuestionTranslationClient`. Only read by a `pairCosts()` aggregate that always returns `[]`. |
| `AiTranslationService` (AiPipeline) | Legacy. 11 hardcoded languages incl. `zh`, **writes nothing to the DB**, its `QuestionsTranslated` event has **no listener**, and it is not reached in production. Do not build on it. |
| `TranslationQuestionsJob` | Dispatches into a void for the same reason. |
| `config('ai.autonomy.translation.locales')` | Both config keys it reads **do not exist**, so it resolves to `[]` and the loop never runs. |
| `config('ai.features.translation.enabled')` | Key does not exist → always `false` → `QuizQuestionAutonomyObserver` returns early. |
| `LocalePreferenceController` | Fully implemented, registered in **no route file**. |
| `quiz_languages` table | 0 rows, model orphaned. |
| `QuizQuestionTranslation.option_a..d` | Vestigial text columns shadowed by the JSON `options` column. |
| `user_language_preferences.curriculum_scope` | Defaults to `'loksewa_nepal'` — a **Nepal-specific default on a worldwide table**. |

### G8 — Validation gaps.

`preferred_question_locale`, `ui_locale`, `spoken_locales.*` and
`StoreQuizTranslationFeedbackRequest.locale` are validated by **length only**, not
against any language list. `?filter[language]` is passed straight into
`WHERE canonical_locale = ?`. `filter[translated]` *is* strictly validated, so the
inconsistency is within the same controller. A junk locale silently returns an
empty set instead of a 422.

### G9 — `char()` blank padding.

`languages.code` is `char(5)`, `country_language_map` and
`translation_directions` use `char(5)`. Values come back space-padded and must be
`trim()`ed at the serialization boundary — currently done in 4 places, easy to
forget in a 5th.

---

## 8. Naming and migration debt

| Item | Problem | Action |
|---|---|---|
| `quiz_questions.canonical_locale` | holds the *authored* language, not the global canonical | rename to `source_locale` |
| `quiz_questions.language` | legacy free text; only ever `'english'`/`'nepali'`; 10,623 rows are `'en'`. Never used as a filter. | drop after `source_locale` lands |
| `translation_directions` | 16 flat rows, **no cross-native pairs** (`ne→hi` is absent). "Pivot through English" is a *policy convention expressed as rows*, not code that chains hops. | if a `ne→hi` request ever occurs, an explicit `(ne,hi)` row is required |

---

## 9. Interface translation status (client)

| Item | Status |
|---|---|
| Font/script rendering, all scripts | **DONE** (`d938dd5`) |
| RTL layout (Arabic, Hebrew, Urdu, Persian) | **DONE** — direction derived from script, not from the server |
| Language picker, native-name labels | **DONE** |
| Language registry server-driven | **DONE** (`49c7145`) — awaits `GET /languages` (G4) |
| ARB coverage gate in CI | **DONE** (`49c7145`) |
| `Accept-Language` sent on every request | **DONE** |
| `PATCH /api/v1/me/locale` persistence | **DONE** (writes `users.locale` only) |
| ARB catalogue | **21 keys / ~266 English files** — `app_en`, `app_ne`, `app_hi` only |
| Interface translations for `es fr ar bn ta te zh` | **absent** |

Nepali and Hindi are both at **100% of the 21-key template**, verified by the CI
gate. `CivilCal` is byte-identical to English in both, which is correct — it is a
brand name, and the coverage tool reports it as the only untranslated key.

Interface strings are **not** machine-written. Generating them without a human or
MT review would be fabricating translations. Adding a language is one ARB file
plus a registry entry once the catalogue is complete.

Note: `LocalizationStudio` on the server already provides single-key AI
translation, batch AI translation, and CSV/JSON import/export **for UI strings** —
that is the intended production path for finishing the ARB catalogue, not ad-hoc
work in the client.

---

## 10. Non-goals

- Flutter never grades, ranks, mints, or validates. Content language is a server
  decision; the client only renders.
- The client does not translate user content. Notes typed in Nepali are stored and
  displayed in Nepali.
- `is_ui_locale`, `is_question_target`, `direction` are **content*-
  administration** concepts, not client concerns.

---

## 11. Definition of done

1. A Nepali-authored question is stored in Nepali, is translated to English and
   Chinese when those directions are `auto`, and is invisible until a human
   verifies it. **Blocked by G1, G2.**
2. A learner in any country gets questions in their `primary_locale`, falling
   back to the authored language when no verified translation exists. **G1, G2, G4.**
3. Adding a language requires a `languages` row plus an ARB file — no code change.
   **G3, G4.**
4. A translator can export, edit, and re-import question translations. **G6.**
5. Every script renders on every platform. **Done.**

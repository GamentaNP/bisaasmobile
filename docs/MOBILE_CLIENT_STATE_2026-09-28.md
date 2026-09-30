# Mobile client — build log and current state

> **Last updated:** 2026-09-29
> **HEAD at time of writing:** `aea5069`
> **Gates:** `flutter analyze` 0 issues · `flutter test` 886 passing · debug APK builds ·
> release AAB 113.2 MB, signed `CN=CivilCal Upload Key` · ARB coverage gate green ·
> **verified running on a physical Redmi 6A (Android 9, API 28, armeabi-v7a)**

This replaces the older ad-hoc "remaining work" notes. It records what is built,
what is deliberately not built, and the server-side work the client is blocked
on. Read `LANGUAGE_AND_CONTENT_TRANSLATION_SPEC.md` for the language model.

---

## 1. The headline finding

The app was never a shell. It had 29 feature modules and ~90 live API paths
against a **433-route** `/api/v1` surface. What made it *feel* thin was that
**23 of the server's 39 feature flags are off**:

```
ON (16): 13 AI Control Plane gateways (admin_chat, blog, campaign, embeddings,
          learning_tutor, quiz, image, tts, stt, reranking, vector_store,
          file_store, seo) + ai_prefer_free_models, book_quiz_answer_vision,
          personalization_v1
OFF (23): economy, ads, changelog, developers, syllabus_gateway, seo_pages,
          the 7 social/referral/sharing flags, all 8 book_engine/* flags,
          user_material_uploads, material_author_royalties
```

**Count these at runtime, not from the config file.** `config/features.php` is
only the compile-time default. `SettingsHydrationServiceProvider::configureFeatureFlagSettings()`
overlays every flag from the `settings` table (`feature_flag_<name>`) at boot,
so the 13 AI gateways that read `false` in the config file are actually **on**
in the database. The comments in that file also refer to a "Pennant DB store"
that is not installed — there is no `pennant_features` table, and
`feature_flag_<name>` in `settings` is the only override that exists.

Most of the product is built and switched off. The client gaps that did exist
have been closed (below), but **turning the flags on is a business decision, not
a code change** — and shipping a UI for a dark feature produces an app that
looks broken rather than minimal.

---

## 2. What was built in this pass

| Area | Server routes | State |
|---|---|---|
| **Syllabus Engine** | 22 | version list, nested tree, node detail, blueprint, own plans |
| **Book Engine** | 25 | catalog, detail + chapters, reader, highlights, notes, coin unlock |
| **Social / referral** | 16 | dashboard, deferred claim, share moments, proofs, share links |
| **Numericals** | 4 | randomised practice, server-side grading, worked solutions |
| **Content quizzes** | 3 | generation request, status, chapter recommended test |
| **Personalization / privacy** | 5 | Art. 15 access, Art. 17 erasure, visitor consent |
| **Cookie consent** | 1 | local consent state gating all analytics |
| **Multilingual rendering** | — | per-glyph font resolution for all scripts |

Feature count went from 29 to 36 modules; tests from 567 to **825**.

### Bugs the tests found

Writing controller and screen tests after the features were built turned up four
real defects that the DTO tests could not reach. Each is fixed and now pinned:

| Bug | Symptom | Fix |
|---|---|---|
| Syllabus controllers started in an empty, not-loading state | First frame rendered "No syllabus has been published yet" before the request was made | Start in the loading state |
| Their re-entrancy guard read `state.isLoading` | Once loading started in `build()`, the initial load refused to run — the screen would have spun forever | Private `_inFlight` flag, released in `finally` |
| `ConsentController.build()` is async | A `decide` issued before it landed was overwritten when it did | `decide`/`revoke` await the in-progress build |
| `_report` reached for `DioClient.instance` unguarded | Null dereference before bootstrap | Check `DioClient.isInitialized` |

The last two were latent: the app happened to avoid them because the consent sheet
awaits `consentProvider.future` first. Safety by coincidence is not safety.

---

## 3. Invariants the new code holds

These are the properties worth not breaking. Each is pinned by a test.

**Never claim a reward the server did not award.**
- Book reading credit can be **voided** with a reason; a voided session is
  displayed as voided, and the award amounts are not rendered.
- Numerical `final_answer` is returned **only when correct**. It is nullable,
  only ever populated from a correct response, and never recomputed.
- Referral attribution and reward amounts come from the dashboard payload.

**Never present unfinished work as finished.**
- A content quiz is `pending`/`generating` until the server says `ready` **and**
  returns question ids. An unrecognised status defaults to pending, never ready.
- Depth-scoped syllabus counts say "topics loaded", not "topics", because the
  version resource reports 542 while `/tree?depth=2` reports 33.
- A null dashboard says the information is unavailable — not "you have no
  referrals".

**Never fabricate a value the server withheld or omitted.**
- `marks_hint` is advisory; the blueprint is the authority.
- Share moments show a coin figure only when the server attached one.
- A deleted referred account renders as "A learner", not a blank row.
- A book with no real-currency price reports null, not 0.

**Never let a stale value sit above fresh data.**
- Randomising a numerical clears the previous verdict.
- A new randomisation in the reader clears the last credit message.
- A claim outcome snackbar is shown once and cleared.

**Fail closed on anything consent-related.**
- An absent, partial or corrupt consent record grants nothing.
- An unknown visitor consent mode reads as the restrictive default, never opt-in.
- A non-true stored boolean is never read as granted.

**Grammar the server freezes.**
- `PUT /numericals/{id}/randomizations`, `PUT /social/referral-code/claim`,
  `PUT /book/chapters/{id}/access`, `PUT /book/progress` — never
  `POST /unlock`-style verbs. The money- and credit-adjacent ones carry
  `Idempotency-Key`; `DELETE /visitor-data` deliberately does not, because erasure
  is idempotent by construction.

---

## 4. Verified against the live backend

Verified on a physical Redmi 6A (Android 9, API 28, armeabi-v7a) over an
`adb reverse tcp:8443 tcp:443` tunnel to Laragon, authenticated with the debug
auto-login account:

- `POST /api/v1/auth/login` returns a working Sanctum PAT, and every screen
  below renders live data behind it.
- `GET /api/v1/syllabi` and `GET /syllabi/{id}/tree?depth=2` return real data.
  This surfaced the empty-string `children` field and the 542-vs-33 count skew,
  neither of which unit tests would have caught.
- `GET /api/v1/library/categories`, `/library/files` and `/library/trending`
  return 200 for an authenticated user.
- `GET /api/v1/social/*` returns 401 unauthenticated, as the route group requires.

### The three corpora are separate resources, not three names for one thing

This was verified against the server source, because the client had been
collapsing three distinct things into one "Library" label:

| Client label | Server resource | Routes |
| --- | --- | --- |
| **Library** | `LibraryFile` — PDFs, notes and study files in soft form | `/api/v1/library/*` |
| **Books** | Book Engine — authored books, chapters, topics, highlights | `/api/v1/books/*` |
| **Syllabus** | The exam tree for the user's target exam | `/api/v1/syllabi/*` |
| *(not an entry point)* | Arcade — a quiz **game mode** under `app/Domains/Quiz/Arcade` | `/api/v1/quiz/*` |

Two separate bugs came out of this. The bottom-nav branch that routes to
`/courses` was labelled "Library", so a user hunting for the PDF library landed
on a course list with no route to it. And a course card's "View syllabus" button
actually pushed `/quiz/browse`, so the label lied. Both are fixed, and
`test/app/corpus_entry_point_test.dart` now guards all three entry points plus
the nav label, so the mistake cannot silently come back.

`Library` and `Books` both render correct empty states today because the server
has no published files or books. That is honest server state, not a client
failure, and the empty states say so rather than showing an error.

### A dead token looks like a broken feature

While verifying the above, Library returned 401 on every call and appeared
broken. It was not: the device held Sanctum token `83`, but
`personal_access_tokens` had no such row (max id 70, newest row 2026-09-22) —
the dev database had been reseeded after that login. Every *authenticated*
route 401'd with that token, including `/api/v1/me`, while public routes still
returned 200. Clearing app data and logging in again minted token `84` and
Library, Books and Courses all worked immediately.

Worth remembering: other screens can look healthy while showing cached or
locally-held data, so the first authenticated 401 is worth chasing on the
server side before suspecting the client.

### What "instant" actually means here, measured

Two interceptors on the single `Dio`, verified on the Redmi 6A:

**`RequestCoalescer`** collapses identical concurrent GETs. `GET /me` fired
twice per cold start, `GET /quiz/courses` has six call sites, `GET /learning/today`
has three, the missions dashboard two. After: every startup endpoint completes
exactly once. GET only, because coalescing a POST would drop an order.

**`ResponseCacheInterceptor`** serves a cached body first and revalidates behind
the user, for an allowlist of public catalog reads. Measured on the second
launch:

| Endpoint | Network requests on a warm run |
|---|---|
| `/syllabi` (catalog + probe) | 0 |
| `/quiz/courses` | 0 |
| `/calculators` | 0 |
| `/library/categories` | 0 |
| `/books` | 0 |

The nine calls that remain are exactly the ones that must not be cached —
`/me`, `/learning/today`, `/quiz/streak`, `/quiz/game/*`, `/rewards/*` — and
with wifi and mobile data both switched off the full 12-track syllabus tree
still renders.

**Conditional requests: the server honours 304 and this client does not yet use
them.** An earlier version of this document recorded the opposite — that "the
server advertises an ETag on every hot endpoint but answers a matching
`If-None-Match` with **200, not 304** — checked on `/syllabi`, `/quiz/courses`,
`/calculators` and `/library/categories`". **That was a measurement error and it
is retracted.** The server answers 304:

```
/syllabi       If-None-Match: "018e15ad…"  ->  304 Not Modified
/quiz/courses  If-None-Match: "d5b1c6ee…"  ->  304 Not Modified
/app/config    If-None-Match: "fefdf0a1…"  ->  304 Not Modified
```

`ApiCacheHeaders` implements it and `tests/Feature/Api/V1/ApiCacheHeadersTest.php`
now pins 304 for all four launch endpoints. The ETag carries its quote
characters, and **any client that strips them sends a header that can never
match** — which looks indistinguishable from a server that ignores it. Two ways
of losing the quotes, both observed while re-checking this: PowerShell mangles
embedded `"` in a native `curl -H` argument, and `$cfg | curl -K -` pipes
UTF-16 so no header is sent at all. Use a `curl --config` file on disk.

So the client TTL below stands on its own merits and not on a server defect: a
TTL is what serves a student with no connection, and a 304 cannot. Conditional
revalidation is available as a byte-saving addition, not as the thing the cache
depends on.

**Response compression was the bigger miss.** With `Accept-Encoding: gzip,
deflate, br` offered the API returned no `Content-Encoding` at all — 796 B,
2 338 B, 578 B, uncompressed. `public/.htaccess` already carried the correct
`AddOutputFilterByType` rule and it was inert because the module was not loaded.
`CompressApiResponse` now does it in the application, so it holds on Apache,
nginx and php-fpm and is covered by a test. `/quiz/courses` went 2 338 B → 912 B
live. That is worth more than the entire disk cache below, on the requests the
cache deliberately does not touch.

| Case | Network | User sees |
|---|---|---|
| fresh | any | cache, no request |
| stale | reachable | cache immediately, one background refresh |
| stale | unreachable | cache, no request, no error |
| absent | any | a real request |

The device database is unencrypted, so the allowlist is a **privacy boundary,
not a performance setting**. Two mechanisms, and both are required:

1. An **allowlist**. `/me`, `/economy`, `/store`, `/quiz/attempts`, `/social`,
   `/rewards`, `/donations` and every mutation are excluded, and a second
   denylist sits in front of it so a future entry cannot capture a wallet.
2. A **credential-scoped key**. SHA-256 of the `Authorization` header, truncated
   — a hash, because the key is persisted and a bearer token on disk is a
   credential at rest.

The second was not there originally, and the allowlist is **not purely public**.
`/library/categories` counts files through `applyVisibleTo($query, $user)` and
`/library/trending` ranks through the same visibility, so both are functions of
the signed-in principal. They are declared `user-scoped` in
`ResponseCachePolicy`, they get a 5-minute TTL rather than hours so an unlock
shows up promptly, and `filter[exclude_seen]` is refused by name because it makes
`/syllabi/{v}/nodes/{n}/questions` per-principal while the path stays under a
public 12-hour prefix. A test asserts every allow-listed path is either
user-invariant on the server or declared user-scoped, so the docblock can no
longer be the only thing asserting it.

`AuthInterceptor` must therefore run **before** the cache — it is what sets the
header the key hashes. The cache sits after it and before the coalescer. (An
earlier version claimed the cache "must be first"; Dio gives each interceptor
its own handler, so a later one may resolve it. The one-shot rule is per
handler, not per chain.)

**`GET /app/config` is no longer on the first-frame path.** It used to be awaited
inside `bootstrap()`, before `runApp`, so a 578-byte request and its 15-second
connect timeout stood between process start and the first pixel — and
`ResponseCachePolicy` forbids caching that path, so the cache could never have
covered the one call that gated the launch. It is now fetched by
`appConfigProvider` from a post-frame callback; `applyAppConfig` latches the
version floor into `AppUpdateGate`, which `ForceUpdateGate` already listens to.

The cache is drained and cleared on sign-out, though the credential-scoped key
means a missed drain is no longer a disclosure — it is only stale bytes.
Server images get the same host treatment: `RemoteImagePolicy` refuses any host
but the API host, because a database row naming a third-party host would turn
every app launch into a beacon to it.

### Tables that are empty on purpose

Five of the seven Drift tables have no producer. `attempts` and `quiz_attempts`
**must** stay empty — the latter has a `provisionalScore` column, and filling it
would mean grading on the device, which the architecture forbids.
`unwired_tables_test.dart` asserts no code path can insert into either, so the
gap cannot be closed by accident.

`SyncQueueDao` writes `sync_queue`, but `SyncQueueService.enqueue` has no
production caller: the calculator-snapshot path that fed it was unwired without
the method being removed. The queue therefore drains zero rows every 30 seconds
forever, which is worse than not having one because it looks like it works.
That is a real gap, and the test fails if anything starts calling `enqueue`.

---

## 5. Open work, and who owns it

### Server — blocking

| Ref | Gap | Impact |
|---|---|---|
| G1 | `QuestionTranslationService::resolve()` is never called from a controller; no resource returns translations; `quiz_question_translations` has 0 rows | **Every learner sees English regardless of translation coverage** |
| G2 | No question route accepts a display locale (`?filter[language]` is a corpus filter returning untranslated text) | Cannot request a translated question set |
| G3 | Six divergent locale lists that disagree on membership; `zh` absent from `languages` and all 16 direction rows | Chinese has no translated questions |
| G4 | No `GET /languages` route | Client duplicates the registry (already built to be swapped) |
| G5 | `direction`, `is_ui_locale`, `is_question_target` have zero readers | Column contract is undefined |
| G6 | No question export, no translation import | The "admin imports/exports questions" path cannot run |
| G7 | Dead code presented as live: `translation_cache`, `AiTranslationService`, `TranslationQuestionsJob`, an unrouted controller | Misleads the next agent |
| G8 | Locale fields validated by length only; `?filter[language]` unvalidated | Junk locale silently returns empty |
| G9 | `char()` blank padding, trimmed in 4 places | Fifth caller will forget |
| C1 | `quiz_question_syllabus_node` has **0 rows** across **1,279** syllabus nodes, while `quiz_questions` holds **10,629** questions | The syllabus tree renders but almost nothing is practiseable. **Fully diagnosed 2026-09-30** — see `docs/SYLLABUS_QUESTION_MAPPING_GAP_2026-09-30.md` for the four root causes, the exact `category.name = node.title` join that works, and the fuzzy-matching rules that look better but are wrong. |
| C2 | `library_files` and books are both empty | Both readers are now gated off the entry points, so this is honest rather than broken — but the features stay dark until content is seeded. |
| — | 23 of 39 feature flags off (16 on) | Whole subsystems are dark |

### Client — genuinely open

| Item | Notes |
|---|---|
| ARB catalogue: 21 keys vs ~266 English files | **Not machine-written on purpose** — fabricated translations. The CI gate (`tool/arb_coverage.dart`) now fails the build on a partial locale, so this cannot regress silently. Use the server's `LocalizationStudio` (AI batch translate + CSV/JSON import/export) — that is the intended path. |
| Bundle actual OFL Noto fonts | **Done 2026-09-30.** The chain named 24 Noto families but only InstrumentSans was declared in `pubspec.yaml`, so every non-Latin script silently fell through to the platform font. Bundled Devanagari, Bengali, Tamil, Telugu, Arabic and Han (+6.4 MB, AAB 112.3 → 118.7 MB). `test/app/font_coverage_test.dart` now fails the build if the chain names a family that is not bundled. Verified on device: नेपाली and हिन्दी render from the bundle. Scripts we do not ship resolve to `sans-serif` honestly rather than naming a face we do not have. |
| Device smoke test | **Done 2026-09-30** on a Redmi 6A (Android 9, API 28) over `adb reverse tcp:8443 tcp:443`. |
| Release AAB at current HEAD | **Rebuilt 2026-09-30 at `8a6d0b7`.** 118.7 MB, signature verified (`jar verified`). `android/key.properties` and the keystore are gitignored. **Still not uploaded to Play, and the signing key still has no confirmed off-repo backup.** |
| Play listing, `assetlinks.json` | Not published. |
| Per-level world map | Backend has no attempt-question retrieval. |
| AAB size | 112 MB, dominated by the ~21 MB `libts.so` in each ABI. Legal, but worth a look before a real upload. |
| Widget tests for the remaining ~60 screens | The new features have controller and screen tests; the pre-existing screens (quiz attempt, economy, library, tutor) still have none. Lower value than the state logic was, but it is the largest remaining gap. |

### Content, not code

The live syllabus has **542 topics with `question_count: 0` across all of them**.
The tree is real; there is no question coverage behind it yet. The "Practice"
button correctly never appears. That is a data-seeding task.

---

## 6. Runbook additions

```powershell
dart run tool/arb_coverage.dart   # locale coverage report; non-zero exit on a partial locale
```

The `router_reachability_test` guard is worth knowing about: it failed on a new
screen during this pass because the screen had no route. It scans the router's
transitive import closure and fails on any public `*Screen`/`*Page` that no user
can reach. Three screens shipped orphaned before it existed.

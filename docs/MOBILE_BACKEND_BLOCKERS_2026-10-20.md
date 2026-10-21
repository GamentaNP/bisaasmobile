# Mobile → Backend blocker list (2026-10-20)

Everything on this list is a **server-side** gap. The Flutter client at
`C:\laragon\www\bisaasmobile` is correct and ready for each of these; until
the server changes, the corresponding mobile surface is degraded or blocked.

Each item states the evidence (file:line in `C:\laragon\www\bisaas`), the
mobile symptom, and the smallest change that unblocks it.

---

## P0 — blocks a feature outright

### 1. The calculator assistant 403s on every call

**Evidence**

- `app/Http/Controllers/Api/V1/AiCalculatorAssistantController.php:24-28`
  returns `403 AI_ABILITY_REQUIRED` unless `$user->tokenCan('ai:chat')`.
- `app/Support/Api/AbilityRegistry.php:107-118` — `firstParty()` is a read of
  `config('api.first_party_abilities')`.
- `config/api.php:176-192` — the first-party list has 15 entries and
  **`ai:chat` is not one of them**:
  `quiz:read, quiz:play, quiz:write, economy:read, economy:spend,
  learning:read, learning:write, profile:read, profile:write, social:read,
  social:write, library:read, library:unlock, calculators:read,
  calculators:compute`.
- `app/Support/Api/AbilityRegistry.php:27-49` lists `ai:chat` as a **legacy
  alias** that is "never handed out by the first-party set".
- `vendor/laravel/sanctum/src/PersonalAccessToken.php:77-81` — `can()` is an
  exact string match, so the alias map is **not** consulted at check time.
- Every mobile token is minted with that list
  (`app/Http/Controllers/Api/MobileAuthController.php:237-239`, used by
  login, register, refresh and both social flows).

**Second, independent gate**

- `app/Domains/Quiz/AI/Services/OpenAiCalculatorAssistantClient.php:48-50`
  returns `control_plane_not_enabled` when `Feature::active('quiz_gateway')`
  is false.
- `config/features.php:60` — `quiz_gateway` ships **false**.
- That reason maps to `503 AI_FEATURE_DISABLED`
  (`AiCalculatorAssistantController.php:101`).

**Mobile symptom** — the "Ask the assistant" panel calls
`POST /api/v1/ai/calculator-assist` and receives a hard 403 on every message.
(The panel is hidden for signed-out users, because the endpoint is inside the
`auth:sanctum` group.)

**Smallest change**

1. Add a canonical `ai:chat` (or `ai:read`) to
   `config('api.first_party_abilities')` — **or** change the controller's
   check to a canonical ability that first-party tokens actually carry.
2. Turn `quiz_gateway` on per environment.

No client change is needed.

---

### 2. Bookmarks publish no answer options

**Evidence**

- `app/Http/Controllers/Api/Quiz/QuizBookmarkApiController.php:53-58`:
  ```php
  ->select(['id', 'quiz_category_id', 'question_text', 'type', 'difficulty', 'points'])
  ```
  `options` is not selected. The column exists and is cast
  (`app/Domains/Quiz/Catalog/Models/QuizQuestion.php:499, 559`).
- Compare `app/Http/Controllers/Api/Quiz/QuizQuestionApiController.php:75-92`,
  which **does** select `options`.

**Mobile symptom** — the client cannot render a drill over the user's own
bookmarks, because there are no options to offer. It works around this by
re-fetching the same questions through `/quiz/questions?category_id=…` and
matching the bookmarked ids, which is correct but costs a request per
category and cannot cover a bookmark with no category.

**Smallest change** — add `'options'` to that `select()`.

---

### 3. No endpoint returns the questions of an existing attempt

**Evidence** — every attempt route in `routes/api/v1/quiz.php`:

| Route | Line | Returns questions? |
|---|---|---|
| `POST /attempts` (start) | 178-181 | No — `attempt_id`, `mode`, `status`, `question_count` only (`QuizAttemptApiController.php:101-106`) |
| `POST /attempts/{attempt}/answers` | 185 | No |
| `PUT /attempts/{attempt}/completion` | 191 | No |
| `GET /attempts/{attempt}/results` | 216 | Only after completion (`:347-349` returns 422 otherwise); returns question **text**, no options (`:481-489`) |
| `GET /attempts/{attempt}/analysis` | 537 | `question_id` only |

There is no `GET /api/v1/quiz/attempts/{attempt}`.

**Mobile symptom** — the client cannot **resume** a drill from an
`attempt_id` after an app restart. It re-derives the question set from
`GET /quiz/questions` before starting the attempt, which works but is not
resume, and it means the question order can drift between the attempt and
what the user is shown.

**Smallest change** — add `GET /api/v1/quiz/attempts/{attempt}` returning the
attempt's questions (with options), owner-scoped, allowed while in progress.

---

### 4. The guest sandbox publishes no questions

**Evidence**

- `app/Http/Controllers/Api/Social/GrowthController.php` — `sandboxStart`
  returns `data.sandbox_attempt = {attempt_id, guest_session_id, questions}`,
  where `questions` is a **count**
  (`app/Http/Controllers/Api/Social/GrowthController.php`, sandbox payload).
- `sandboxAnswer` takes `{question_id, answer}` — the client must know the
  question ids, and the start payload does not give them.
- `routes/api/v1/social.php:50-69` — the three sandbox routes.

**Mobile symptom** — the client can start a sandbox attempt and can answer
and complete one, but it cannot **show the questions**, because the server
never publishes them. The mobile screen says exactly that rather than
pretending the challenge is playable.

**Smallest change** — include the question ids, text and options in the
`sandbox_attempt` payload (`questions` as an array rather than a count).

---

## P1 — silently degrades a feature

### 5. `guest_sandbox_enabled` is off

- `config/features.php:83` — `'guest_sandbox_enabled' => false`.
- `app/Http/Controllers/Api/Social/GrowthController.php` (share payload) —
  publishes `sandbox_available: (bool) config('features.flags.guest_sandbox_enabled', false)`.
- The sandbox **routes** are gated only by `social_engine_enabled`
  (`routes/api/v1/social.php:43-46`), not by this flag.

**Mobile symptom** — the server tells the client the sandbox is unavailable
and the client hides the play button, even though the endpoint would serve it.

**Smallest change** — one flag flip, once item 4 is done.

### 6. `/quiz/questions` has no `topic_id` filter, and a bare one is ignored

- `app/Http/Controllers/Api/Quiz/QuizQuestionApiController.php:34-39` — the
  allow-list has no `topic_id`.
- `app/Http/Concerns/RejectsUnknownListParams.php:36-48` — the guard polices
  only the `filter[...]` bag and the `sort` / `include` CSVs. A **bare**
  `?topic_id=5` is never inspected.

**Mobile symptom** — a topic drill sends `?search=<topic name>` and gets
**text-matched** questions, which can include off-topic ones. There is no
error to notice: the filter is simply not applied.

**Smallest change** — add `topic_id` to `$allowedFilters` and apply it in
the controller (the same way `course_id` and `category_id` are applied).

### 7. The AI usage summary is a nightly rollup

- `app/Domains/AI/Analytics/Services/AiUsageQueryService.php:397-412` reads
  `ai_usage_daily_rollups`.
- `app/Domains/AI/Analytics/Jobs/AggregateAiUsageRollupsJob.php:40-68`
  writes it; `routes/console.php:1393-1397` schedules it at 01:50 UTC daily.
- The only mobile-reachable flow that populates it is
  `POST /api/v1/learning/tutor`
  (`app/Http/Controllers/Api/V1/Learning/LearningTutorController.php:96-103`).
- The calculator assistant cannot populate it (item 1).

**Mobile symptom** — "Your AI usage" shows zero requests for up to ~24 hours
after the first tutor call, and forever if the user only uses the calculator
assistant.

**Smallest change** — none required for correctness; if the team wants the
screen to be immediately meaningful, expose the raw `ai_invocations` rollup
(or a live aggregate) for the "last 7 days" window.

### 8. `tutor_conversations` is not period-scoped

- `app/Http/Controllers/Api/V1/Me/AiUsageController.php:71-73` counts
  `QuizTutorConversation` with **no** date filter, while the two neighbouring
  totals are period-scoped.

**Mobile symptom** — the mobile screen renders it next to a "7 days" period
chip, so the number is a lifetime total presented as a period total. The
client can label it, but the server is the inconsistent one.

**Smallest change** — apply the same period filter, or publish it under a
name that says what it is.

### 9. Weekly report cards are a weekly job, capped per run

- `routes/console.php:1317-1322` — `WeeklySummaryGenerationJob` runs
  Sunday 06:00 UTC.
- `app/Domains/Analytics/Jobs/WeeklySummaryGenerationJob.php:46, 59-77` —
  at most 250 users per run, with a rotating cursor.

**Mobile symptom** — the first weekly card appears only after the next
Sunday, and on a large install some users are deferred by a week.

**Smallest change** — none required; the mobile screen should say the card
appears on Sundays (it now labels the section as a weekly trend).

### 10. Three of the five share kinds are flag-off

- `app/Domains/Social/Enums/ShareMomentKind.php:26-32` maps each kind to a
  Pennant flag.
- `config/features.php:76-86` — `achievement_sharing_enabled`,
  `calculator_sharing_enabled` and `challenge_sharing_enabled` are all
  `false`.
- `app/Domains/Social/Services/ShareMomentService.php:53-60` filters on
  them.

**Mobile symptom** — `GET /api/v1/social/moments` only ever returns
`quiz_result` or `streak`, with no error and no indication that three kinds
are switched off.

**Smallest change** — flip the flags, or publish which kinds are currently
available so the client can hide the ones that are not.

---

## P2 — contract friction the client works around

### 11. `POST /api/v1/share` is unusable from mobile

- `app/Http/Controllers/Api/ShareController.php:101-116` validates
  `calculable_id` + `calculable_type`.
- `calculable_type` is the **PHP class name** of the calculable model stored
  on `calculation_snapshots`
  (`app/Support/Calculators/CalculationSnapshotService.php:72-76`).
- `app/Support/Calculators/Permalink/Services/SnapshotOwnershipProbe.php:39-56`
  resolves it, and a miss is `403 SHARE_NOT_OWNED`.

**Mobile symptom** — the client cannot mint a share link for a calculator
result without a snapshot id it has no way to obtain.

**Smallest change** — none strictly required: the client can use
`POST /api/v1/calculator/permalinks` with the **inline** payload
(`domain`, `calculator_slug`, `inputs`, `results`), which is the documented
canonical route (`routes/api/v1.php:257-277`) and needs no id. It would help
to document `POST /api/v1/share` as snapshot-only, or let it accept the same
inline payload.

### 12. The two funnel endpoints share one tight corpus bucket

- `routes/api/v1/quiz.php:127-130, 289-291` — both funnel routes use
  `throttle:quiz-content-read`.
- `app/Providers/RateLimiterServiceProvider.php:169-177` — 30/min,
  300/hr, 1500/day, shared with the question collections.
- Every route also sits on the 60/min `api-default` bucket
  (`app/Providers/RateLimiterServiceProvider.php:404-411`).

**Mobile symptom** — none today, but a home screen that pre-fetches the
funnel, the guest funnel and the question collection in one pass shares
30/min across all three. Worth knowing before a prefetcher is added.

### 13. `POST /api/v1/share` and the share links are two different systems

- `POST /api/v1/share` mints a **signed** permalink (calculator results).
- `POST /api/v1/social/links` mints a **tracked** share link (the social
  growth loop) and `GET /api/v1/public/social/share/{token}` resolves it.

They are unrelated surfaces with confusingly similar names. The client uses
the second one for social sharing and the first one is not used at all.

---

## What the mobile client already does, so nothing here is double-handled

- The practice drill **seeds the attempt with the exact question ids it
  shows**, so the server grades what the user saw. It works today because
  `POST /quiz/attempts` accepts `question_ids` with `mode: practice` — no
  mode restriction exists in `StartAttemptRequest`
  (`app/Http/Requests/Quiz/Api/StartAttemptRequest.php:22-33`), in
  `QuizAttemptMode`, or in `AttemptService::start`.
- The client never grades anything locally, never mints a coin, and never
  invents a share claim — it asks the server for the copy it publishes.
- Every list surface the client touches is walked with the server's
  `next_cursor`; no client sends `page` to a cursor endpoint.
- Every data source **throws** on a transport error, a non-2xx status or a
  body it does not understand. A failure is never rendered as "you have
  nothing" — so an endpoint that returns a 200 with an unexpected shape will
  surface as an error on the device rather than as an empty screen.

# Backend phase plan — mobile parity (bisaas)

> **Status: EXECUTED 2026-10-20.** Every phase below was closed by the
> `bisaas` agent and the client work that was waiting on them has been
> finished. This document is kept as the record of *what was asked for and
> why*, so the reasoning survives even though the plan is done.
>
> What the server changes enabled on the client:
>
> | Phase | Client work it unblocked |
> |---|---|
> | 0.1 `ai:chat` + 0.2 `quiz_gateway` | the calculator assistant panel now gets answers instead of a 403 |
> | 1.1 sandbox questions + 1.2 the flag | the guest share challenge is **playable** — questions, answers, verdicts, result |
> | 2 bookmark `options` | a bookmark drill grades **the user's own bookmarks** |
> | 3 `GET /quiz/attempts/{attempt}` | a drill can be resumed from an attempt id |
> | 4 `topic_id` filter | a topic drill returns topic-scoped questions, not text-matched ones |
> | 5.1 hourly rollup | "Your AI usage" is meaningful within the hour, not the next day |
> | 5.2 `tutor_conversations` scope | the stat is labelled for what it is |
> | 5.3 daily report card | the weekly card exists within a day |
> | 6 the three share kinds | the client can render achievement, calculator and challenge moments |
> | 7.1 the permalink route | a calculator result shares through the canonical route |

**Audience:** the `bisaas` (Laravel) agent.
**Requester:** the Flutter client at `C:\laragon\www\bisaasmobile`.
**Date:** 2026-10-20.

The mobile client is finished with everything that does not need a server
change. This document is the remaining server work, **ordered so each phase
unblocks the next**, with the exact evidence and the acceptance test for
every item.

Read the phases in order. Phase 0 is a prerequisite for Phase 2; Phase 1 is
independent and can run in parallel.

---

## Phase 0 — Unblock the AI features (2 changes, ~15 minutes)

**Why first:** these two changes turn two shipped-but-dead mobile features
into working ones. They are the cheapest fixes on the list and the most
visible.

### 0.1 — Issue `ai:chat` to first-party tokens

**Evidence**

- `app/Http/Controllers/Api/V1/AiCalculatorAssistantController.php:24-28`
  returns `403 AI_ABILITY_REQUIRED` unless `$user->tokenCan('ai:chat')`.
- `app/Support/Api/AbilityRegistry.php:107-118` — `firstParty()` reads
  `config('api.first_party_abilities')`.
- `config/api.php:176-192` — the list has 15 entries and **`ai:chat` is not
  one of them**:
  `quiz:read, quiz:play, quiz:write, economy:read, economy:spend,
  learning:read, learning:write, profile:read, profile:write, social:read,
  social:write, library:read, library:unlock, calculators:read,
  calculators:compute`.
- `app/Support/Api/AbilityRegistry.php:27-49` — `ai:chat` is a **legacy
  alias** that is "never handed out by the first-party set".
- `vendor/laravel/sanctum/src/PersonalAccessToken.php:77-81` — `can()` is an
  exact string match, so the alias map is **not** consulted at check time.
- Every mobile token is minted with that list
  (`app/Http/Controllers/Api/MobileAuthController.php:237-239`, used by
  login, register, refresh and both social flows).

**Change** — either:

- **(a)** add `'ai:chat'` to `config('api.first_party_abilities')`; **or**
- **(b)** add a canonical ability (e.g. `ai:read`) to the list **and**
  change `AiCalculatorAssistantController::hasAiAbility` to check that
  canonical name.

(b) is preferred: `ai:chat` is already documented as a deprecated alias, and
giving a deprecated name a fresh meaning re-creates the confusion the alias
map was written to remove.

**Acceptance**

```php
$this->assertTrue($user->fresh()->tokenCan('ai:chat'));
// and
POST /api/v1/ai/calculator-assist  →  not 403 AI_ABILITY_REQUIRED
```

**Mobile symptom fixed:** the "Ask the assistant" panel on every calculator
currently gets a hard 403 on every message.

### 0.2 — Turn on the `quiz_gateway` feature

**Evidence**

- `app/Domains/Quiz/AI/Services/OpenAiCalculatorAssistantClient.php:48-50`
  returns `control_plane_not_enabled` when `Feature::active('quiz_gateway')`
  is false.
- `config/features.php:60` — `quiz_gateway` ships **false**.
- That reason maps to `503 AI_FEATURE_DISABLED`
  (`AiCalculatorAssistantController.php:101`).

**Change** — enable `quiz_gateway` per environment (or seed the control
plane so the flag can be turned on).

**Acceptance** — `POST /api/v1/ai/calculator-assist` returns `200` with a
`data.assistant` object instead of `403`/`503`.

---

## Phase 1 — Make the guest share flow playable (2 changes)

**Why:** a user who receives a share link today gets a screen that says
"the questions are not published yet" and is asked to sign up. The wiring is
already in the mobile client; the payload is what is missing.

### 1.1 — Publish the sandbox questions

**Evidence**

- `app/Http/Controllers/Api/Social/GrowthController.php` — `sandboxStart`
  returns `data.sandbox_attempt = {attempt_id, guest_session_id, questions}`,
  where `questions` is a **count**.
- `sandboxAnswer` takes `{question_id, answer}` — so the client must know
  the question ids, and the start payload does not give them.
- `routes/api/v1/social.php:50-69` — the three sandbox routes.

**Change** — make `questions` an **array of question objects** (id, text,
options, type, points) rather than a count. If a count must stay for
compatibility, publish the questions under a sibling key.

**Acceptance**

```json
{
  "data": {
    "sandbox_attempt": {
      "attempt_id": 321,
      "guest_session_id": "guest-…",
      "questions": [
        { "id": 11, "question_text": "…", "options": [ { "key": "A", "text": "…" } ] }
      ]
    }
  }
}
```

and a guest can then run
`POST /public/social/sandbox/{token}` → `PUT …/answer` → `PUT …/completion`
without a bearer token.

**Mobile symptom fixed:** the guest sandbox is currently unplayable, and the
mobile screen says so.

### 1.2 — Flip `guest_sandbox_enabled`

- `config/features.php:83` — `'guest_sandbox_enabled' => false`.
- `GrowthController` (share payload) publishes
  `sandbox_available: (bool) config('features.flags.guest_sandbox_enabled', false)`.
- The sandbox **routes** are gated only by `social_engine_enabled`
  (`routes/api/v1/social.php:43-46`), not by this flag — so the endpoint
  already serves; the client is simply told not to offer it.

**Change** — one flag flip, **after 1.1 ships**.

**Acceptance** — `GET /api/v1/public/social/share/{token}` returns
`sandbox_available: true` and the mobile share screen offers "Play the
challenge".

---

## Phase 2 — Let the client drill the user's own bookmarks (1 change)

**Evidence**

- `app/Http/Controllers/Api/Quiz/QuizBookmarkApiController.php:53-58`:
  ```php
  ->select(['id', 'quiz_category_id', 'question_text', 'type', 'difficulty', 'points'])
  ```
  `options` is not selected. The column exists and is cast
  (`app/Domains/Quiz/Catalog/Models/QuizQuestion.php:499, 559`).
- Compare `app/Http/Controllers/Api/Quiz/QuizQuestionApiController.php:75-92`,
  which **does** select `options`.

**Change** — add `'options'` to that `select()`.

**Acceptance** — `GET /api/v1/quiz/bookmarks` rows carry the same
`options` array the question collection publishes.

**Mobile symptom fixed:** the mobile drill currently has to re-fetch each
bookmarked question through `/quiz/questions?category_id=…` and match ids —
a request per category, and impossible for a bookmark with no category. With
the options published, the drill can be built from the bookmarks
themselves.

**Depends on:** nothing. Can run in parallel with Phase 0.

---

## Phase 3 — Let a client resume an attempt (1 new route)

**Evidence** — every attempt route in `routes/api/v1/quiz.php`:

| Route | Line | Returns the questions? |
|---|---|---|
| `POST /attempts` (start) | 178-181 | No — `attempt_id`, `mode`, `status`, `question_count` only (`QuizAttemptApiController.php:101-106`) |
| `POST /attempts/{attempt}/answers` | 185 | No |
| `PUT /attempts/{attempt}/completion` | 191 | No |
| `GET /attempts/{attempt}/results` | 216 | Only after completion (`:347-349` returns 422 otherwise); question **text**, no options (`:481-489`) |
| `GET /attempts/{attempt}/analysis` | 537 | `question_id` only |

There is **no** `GET /api/v1/quiz/attempts/{attempt}`.

**Change** — add `GET /api/v1/quiz/attempts/{attempt}` returning the
attempt's questions (id, text, options), owner-scoped, allowed while the
attempt is in progress.

**Acceptance** — a client holding only an `attempt_id` can rehydrate the
questions it must grade.

**Mobile symptom fixed:** the mobile drill re-derives its question set
before starting the attempt, so an interrupted drill cannot be resumed and
the question order can drift between the attempt and what the user saw.

---

## Phase 4 — Scope the question collection properly (1 change)

**Evidence**

- `app/Http/Controllers/Api/Quiz/QuizQuestionApiController.php:34-39` — the
  filter allow-list has **no `topic_id`**.
- `app/Http/Concerns/RejectsUnknownListParams.php:36-48` — the guard
  polices only the `filter[...]` bag and the `sort` / `include` CSVs. A
  **bare** `?topic_id=5` is never inspected, so it is **silently ignored**
  (and `?filter[topic_id]=5` is a hard 400).

**Change** — add `topic_id` to `$allowedFilters` and apply it in the
controller, the way `course_id` and `category_id` are applied.

**Acceptance** — `GET /api/v1/quiz/questions?filter[topic_id]=7` returns
only that topic's questions, and a bare `?topic_id=7` behaves the same
rather than being ignored.

**Mobile symptom fixed:** a topic drill currently sends
`?search=<topic name>` and gets **text-matched** questions, which can
include off-topic ones. There is no error to notice — the filter simply is
not applied.

---

## Phase 5 — Make the usage analytics tell the truth (3 changes)

### 5.1 — Publish `ai:usage` without the overnight lag

**Evidence**

- `app/Domains/AI/Analytics/Services/AiUsageQueryService.php:397-412` reads
  the **`ai_usage_daily_rollups`** table.
- `app/Domains/AI/Analytics/Jobs/AggregateAiUsageRollupsJob.php:40-68`
  writes it; `routes/console.php:1393-1397` schedules it at **01:50 UTC
  daily**.
- The only mobile-reachable route that writes the raw ledger is
  `POST /api/v1/learning/tutor`
  (`app/Http/Controllers/Api/V1/Learning/LearningTutorController.php:96-103`).
  The `/learning/ai-tutor/*` family answers with the same content but never
  reaches the usage ledger.

**The mobile client has already been changed** to post its tutor chat to
`POST /learning/tutor` (the route that is recorded), so this is the server
half of one fix.

**Change** — either aggregate the rollup more often (e.g. hourly), or expose
a live aggregate over `ai_invocations` for the "last 7 days" window.

**Acceptance** — after one tutor message, `GET /api/v1/me/ai-usage` shows
one request without waiting for the nightly job.

### 5.2 — Scope `tutor_conversations` to the period, or rename it

**Evidence**

- `app/Http/Controllers/Api/V1/Me/AiUsageController.php:71-73` counts
  `QuizTutorConversation` with **no** date filter, while `requests`,
  `prompt_tokens` and `completion_tokens` in the same payload **are**
  period-scoped.

**Change** — apply the same period filter, or publish it under a name that
says what it is (`tutor_conversations_all_time`).

**Acceptance** — every number in `data.totals` describes the same window,
or the un-scoped one is named for what it is.

**Mobile symptom fixed:** the mobile screen renders it next to a "7 days"
chip. The client now labels it "all time" as a stopgap, but the server is
the inconsistent one.

### 5.3 — Give the weekly report card a schedule the user can predict

**Evidence**

- `routes/console.php:1317-1322` — `WeeklySummaryGenerationJob` runs
  **Sunday 06:00 UTC**.
- `app/Domains/Analytics/Jobs/WeeklySummaryGenerationJob.php:46, 59-77` —
  at most **250 users per run**, with a rotating cursor.

**Change** — none required for correctness. If the mobile screen should
promise a weekly card, either run the job more often, or publish the
"next refresh" date so the client can say "your card appears on Sundays".

**Acceptance** — a mobile user sees their weekly card within a week of
their first attempt, and the screen can state when to expect it.

---

## Phase 6 — Turn on the share kinds (3 flags)

**Evidence**

- `app/Domains/Social/Enums/ShareMomentKind.php:26-32` maps each kind to a
  Pennant flag.
- `config/features.php:76-86` — `achievement_sharing_enabled`,
  `calculator_sharing_enabled` and `challenge_sharing_enabled` are all
  **false**.
- `app/Domains/Social/Services/ShareMomentService.php:53-60` filters on
  them.

**Change** — flip the flags, or publish which kinds are currently available
so the client can hide the ones that are not.

**Acceptance** — `GET /api/v1/social/moments` can return `achievement`,
`calculator` and `challenge`, or publishes the available set.

**Mobile symptom fixed:** the client only ever receives `quiz_result` and
`streak`, with no error and no indication that three kinds are switched
off.

---

## Phase 7 — Remove the contract friction (2 changes, optional)

These need no change to unblock anything; they remove workarounds the
mobile client currently carries.

### 7.1 — Let `POST /api/v1/share` accept the inline payload

**Evidence**

- `app/Http/Controllers/Api/ShareController.php:101-116` validates
  `calculable_id` + `calculable_type`.
- `calculable_type` is the **PHP class name** of the calculable model stored
  on `calculation_snapshots`
  (`app/Support/Calculators/CalculationSnapshotService.php:72-76`), and
  `app/Support/Calculators/Permalink/Services/SnapshotOwnershipProbe.php:39-56`
  resolves it — a miss is `403 SHARE_NOT_OWNED`.
- The canonical sibling `POST /api/v1/calculator/permalinks`
  (`routes/api/v1.php:257-277`) already accepts the inline payload
  (`domain`, `calculator_slug`, `inputs`, `results`) and needs no id.

**Change** — either let `/share` accept the same inline payload, or
document it as snapshot-only so the next client does not try it.

**Acceptance** — a client can mint a share link for a calculator result it
just computed, without first creating a server-side snapshot.

### 7.2 — Note the shared corpus rate limit

- `routes/api/v1/quiz.php:127-130, 289-291` — both funnel routes use
  `throttle:quiz-content-read`.
- `app/Providers/RateLimiterServiceProvider.php:169-177` — 30/min,
  300/hr, 1500/day, **shared** with the question collections.
- Every route also sits on the 60/min `api-default` bucket
  (`app/Providers/RateLimiterServiceProvider.php:404-411`).

**No change needed** — a note for the team: a mobile home screen that
pre-fetches the funnel, the guest funnel and the question collection shares
30/min across all three. The client is careful here today, but a
prefetcher would trip it.

---

## What the mobile client already does (so nothing is double-handled)

- The practice drill **seeds the attempt with the exact question ids it
  shows**, so the server grades what the user saw. This works today because
  `POST /quiz/attempts` accepts `question_ids` with `mode: practice` —
  there is no mode restriction in `StartAttemptRequest`, in `QuizAttemptMode`
  or in `AttemptService::start`.
- The client never grades anything locally, never mints a coin, and never
  composes its own claim about what the user achieved — it asks the server
  for the copy it publishes.
- Every list surface the client touches is walked with the server's
  `next_cursor`; **no client sends `page` to a cursor endpoint**.
- Every data source **throws** on a transport error, a non-2xx status or a
  body it does not understand. A failure is never rendered as "you have
  nothing" — so an endpoint that returns a 200 with an unexpected shape
  surfaces as an error on the device rather than as an empty screen.

## The one thing that is **not** a backend task

The **guest sandbox UI** is written and wired
(`answerSandbox` / `completeSandbox` are implemented end to end). It becomes
playable the moment Phase 1.1 publishes the questions. No client work is
outstanding for it.

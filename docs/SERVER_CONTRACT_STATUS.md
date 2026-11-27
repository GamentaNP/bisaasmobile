# Server contract status — what the client relies on, and what is still owed

**Server facts verified 2026-11-04 against `C:\laragon\www\bisaas` at its
current HEAD; client adoptions re-audited 2026-11-27.** This is the client
repo's record of the `/api/v1` contract. The server repo
remains the source of truth; if the two disagree, the server wins and this
file is the thing to correct.

**Release posture (reconciled 2026-11-26).** The founder's 2026-09-11 PERMANENT
directive
(`C:\laragon\www\bisaas\docs\mobileapp\MOBILE_RELEASE_DECISION_2026-09-11.md`)
makes this client an internal development/test artifact, never a store
submission. The adoption gaps, "what to do" rows and server debts below are
contract hygiene for that test instrument — **not store-launch blockers**.
`GENERIC_CHECKOUT_DISABLED` in the error registry is a server fact, not a
billing plan: there is no billing library and no IAP, coins are earned, and
subscription state is display-only.

It replaces `MOBILE_BACKEND_PHASE_PLAN_2026-10-20.md`,
`MOBILE_BACKEND_BLOCKERS_2026-10-20.md`, and the two dated diagnosis notes
(`CALCULATOR_ENUM_FIELD_GAP_2026-10-01.md`,
`SYLLABUS_QUESTION_MAPPING_GAP_2026-09-30.md`), all of which described work
that has since landed or been superseded.

## 1. Delivered and adopted

Every item below is live on the server and exercised by the client (host
integration tests plus the on-device run against Laragon):

| Area | Contract |
|---|---|
| Guest funnel | `guest_sandbox_enabled` true; sandbox publishes `question_items`; the guest can play |
| Bookmarks | `GET /quiz/questions?bookmark=1` includes `options`, so a bookmark drill is answerable |
| Attempt resume | `GET /quiz/attempts/{attempt}` (`routes/api/v1/quiz.php:187`) returns the attempt with its questions |
| Attempt lifecycle | `POST /quiz/attempts` (canonical; `/attempts/start` remains as a transition alias), `POST …/answers`, `PUT …/completion` |
| AI access | First-party tokens carry `ai:chat`; `quiz_gateway` flag on; assistant and calculator-assist answer |
| AI usage | Hourly rollup, so `GET /me/ai-usage` is not a day behind |
| Report card | Weekly summary scheduled daily, so the card is predictable |
| Share | Three share kinds enabled; permalink route serves a shared calculation |
| Tenancy | `GET /me/tenants` outside the tenant-scoped group, active tenants only, ordered by `name`,`id` — see [TENANT_SWITCHER_CONTRACT.md](TENANT_SWITCHER_CONTRACT.md) |
| Calculator schemas | Enum fields are `select` with `options`; 18 fields that advertised free text were fixed server-side and the client renders them generically |
| Arcade runs | `POST /quiz/survival/start`, `/quiz/lightning/start`, `/quiz/true-false/start` (optional `category_id`, idempotency required; a category short of the mode's minimum answers 422 and the client says so in the user's language); questions from `GET /quiz/attempts/{attempt}`; answers, `PUT …/completion`, `GET …/results`, `PUT …/abandonment` — the five other arcade values in the server enum have no mobile start route and are deliberately not offered |
| Leaderboard submission | `POST /quiz/leaderboard` is server-authoritative: the client sends `mode` + `attempt_id` only, with an `Idempotency-Key`; score/correct/total/streak are recomputed from the completed attempt server-side (client commit `fafbbad`). The legacy score fields are accepted but never sent. |
| Error registry | `ApiErrorCode` mirrors the server registry, now including `NO_ACTIVE_EXAM`, `NO_REPORT`, `NO_PREDICTION`, `GENERIC_CHECKOUT_DISABLED`, `EXAM_SECTION_LOCKED` and `WEBHOOK_MISCONFIGURED`; `TENANT_INACTIVE` additionally carries `error.details.tenant_id` (a display diagnostic, never re-asserted). Unknown codes still degrade to generic copy. |

## 2. Client-side adoption gaps — both adopted 2026-11-26 (closed)

These two items were recorded here while the server was ahead of the client.
Both are now closed by commits `6143f2b` and `334538a`; the rows are kept as a
record of what changed.

| # | Former gap | Adoption — client evidence |
|---|---|---|
| A1 | `GET /quiz/attempts/{attempt}` was adopted by the arcade only; an interrupted *study* attempt could not be resumed | Both study paths now read the server's snapshot: `lib/features/quiz/data/datasources/quiz_remote_data_source.dart:597-636` and `lib/features/practice/data/datasources/practice_remote_data_source.dart:298-329`. Resume is wired in `lib/features/quiz/presentation/controllers/quiz_controller.dart:677-730`, `lib/features/practice/presentation/controllers/practice_controller.dart:344-362`, and the screen accepts a resume id at `lib/features/quiz/presentation/screens/quiz_attempt_screen.dart:36-37`. |
| A2 | Topic drills matched on `GET /quiz/questions?search=` because the client had no `topic_id` filter | `topic_id` is an allowed server filter and the client sends it: `lib/features/practice/data/datasources/practice_remote_data_source.dart:144-175`; the weak-topic screen passes the id at `lib/features/practice/presentation/screens/practice_browser_screen.dart:118-131`. `search` remains only for analyses that publish a topic name, not an id. |

## 3. Still owed by the server

| # | Item | Consequence for the client |
|---|---|---|
| S1 | `tutor_conversations` in `GET /me/ai-usage` counts **all-time**, not the requested period | The tutor-sessions figure on the usage screen disagrees with the period label. Either scope it to the period or rename the field; the client currently shows it as a lifetime count. |
| S2 | `POST /share` requires `calculable_id` + `calculable_type`; it does not accept an inline payload | Saving an unsaved calculation as a share needs a server-side row first. Worked around by sharing only persisted calculations. |
| S3 | Two share systems coexist (the `/share` endpoint and the legacy snapshot path) with a shared rate limit | Not user-visible yet, but any rate-limit tuning must change both. |

## 4. Resolved diagnoses — kept as a record, no action

**Calculator enum fields (diagnosed 2026-10-01).** Eighteen schema fields
advertised `type: string` for values that were really enums, so the app
showed a free-text box that the server then rejected as invalid. Fixed
server-side: the schemas now emit `select` with `options`
(`DerivedCalculatorSchemas`, `FireSchemaRegistry`). The client already parsed
`type`/`options` and renders a dropdown generically — no client workaround was
ever added, which was the point of writing the note. The suggested generic gate
("every `Rule::enum` field must advertise options") was never added and now
belongs in the server repo, where 53 such fields live.

**Syllabus → question mapping (diagnosed 2026-09-30).** Syllabus nodes had no
bridge to questions, so every node reported zero and the client hid its
Practice action. Fixed server-side by a `quiz_syllabus_node_topic` bridge at
topic/sub-category/category tier, with a scheduled repair command. The client
fix that accompanied it (blueprint list parsing, commit `772f758`) is live and
covered by tests.

**Residual, content not code:** some topics still have no questions mapped.
That is an editorial task (`quiz:questions:ai-map-topics`, needs gateway
credentials), tracked in the server repo. The client's behaviour is correct:
a topic with zero questions shows no Practice action rather than an empty
drill.

## 5. How to re-check this file

```bash
# server
cd C:/laragon/www/bisaas && php artisan route:list --path=api/v1 | grep -E "attempts|tenants|ai-usage"
php artisan test --filter=MeTenantsTest
# client
cd C:/laragon/www/bisaasmobile && flutter test test/integration
```

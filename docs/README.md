# Documentation index

One page that says what each document is for, which one is authoritative, and
what was retired. If two files disagree, the authoritative one wins; if none
is authoritative for the question, that is a gap to close here, not a tie to
break by preference.

**Last full audit: 2026-11-04, at `0cee095`.** Every claim in the surviving
documents was checked against the tree (and, for the API, against
`C:\laragon\www\bisaas`) on that date. Numbers that could not be measured were
removed rather than repeated.

## Read in this order

| # | Document | Answers |
|---|---|---|
| 1 | [PROJECT_STATE.md](PROJECT_STATE.md) | What the client is, what is shipped, what is measured, which invariants must not regress, and the six open client items. |
| 2 | [LAUNCH_READINESS.md](LAUNCH_READINESS.md) | What stands between this build and the Play Store, in order, including the blocker nobody can code around (the domain). |
| 3 | [release_checklist.md](release_checklist.md) | The mechanical pre-release gate: commands, founder-supplied values, and the platform steps. |
| 4 | [SERVER_CONTRACT_STATUS.md](SERVER_CONTRACT_STATUS.md) | What `/api/v1` delivers, what is still owed, and which client adoptions are behind. |
| 5 | [../AGENTS.md](../AGENTS.md) | The rules for changing this repo: boundary, API contract, l10n, release posture. |

## Authority — one source per question

| Question | Authoritative file |
|---|---|
| Is feature X shipped? What is the test count? | `PROJECT_STATE.md` |
| Can we publish? What is blocking? | `LAUNCH_READINESS.md` |
| What exactly must be true before a release? | `release_checklist.md` |
| What does the server do, and what does it owe? | `SERVER_CONTRACT_STATUS.md` |
| What are the tenancy rules and the switcher wire shape? | `TENANT_SWITCHER_CONTRACT.md` |
| How does the translation pipeline work, and how many keys? | `localization.md` |
| What is the multilingual *model* (scripts, content translation)? | `LANGUAGE_AND_CONTENT_TRANSLATION_SPEC.md` |
| What store copy is uploaded? | `android/fastlane/metadata/**`, `ios/fastlane/metadata/**` |
| Why is the store copy true? | `store_listing.md` — the per-claim provenance |
| What must the privacy policy say? | `legal/privacy-policy-{en,ne,hi}.md` |
| What do I answer on the Data Safety form? | `data_safety_inventory.md` |
| Which third-party asset is under which licence? | `../assets/LICENSES.md` |
| How do I deploy the API? | `BACKEND_DEPLOYMENT_RUNBOOK.md` |
| How do I serve the App Links file? | `APP_LINKS_DEPLOYMENT.md` |
| How is Firebase actually wired? | `FIREBASE_SETUP.md` |
| How do I run the manual release smoke pass? | `GOLDEN_PATH_RUNBOOK.md` |
| How do I build and run anything? | `../README.md` |

## Conventions

- **Undated names are current** (`PROJECT_STATE`, `LAUNCH_READINESS`,
  `SERVER_CONTRACT_STATUS`). **Dated names are history** and, after this
  audit, none survive — a document that describes a past state belongs in git
  history, not in the tree where it can be mistaken for the present.
- **Numbers are measured or absent.** A count that cannot be verified from the
  tree is not written down. This is why so many stale counts were removed
  rather than updated.
- **Every doc names its date and commit.** If you change behaviour the doc
  describes, change the doc in the same commit.

## Retired on 2026-11-04, and why

Each of these was either a completed plan, a one-off dated report, a resolved
diagnosis, or a duplicate that contradicted a surviving document. Nothing was
deleted without its still-true content moving somewhere above.

| Retired file | Why | Content now lives in |
|---|---|---|
| `MOBILE_CLIENT_STATE_2026-09-28.md` | Dated build log; every count in it (886 tests, 36 modules, AAB 118 MB, 21 ARB keys) was stale | `PROJECT_STATE.md` |
| `MOBILE_REMAINING_WORK_2026-09-27.md` | Claimed to be the live backlog, described a smaller app, contradicted itself on test counts | `PROJECT_STATE.md` §5 |
| `MOBILE_BACKEND_PHASE_PLAN_2026-10-20.md` | Server work it ordered has landed; status banner said "all closed" while two client adoptions never happened | `SERVER_CONTRACT_STATUS.md` |
| `MOBILE_BACKEND_BLOCKERS_2026-10-20.md` | 10 of 13 items fixed with no record; three survive | `SERVER_CONTRACT_STATUS.md` §3 |
| `CALCULATOR_ENUM_FIELD_GAP_2026-10-01.md` | Diagnosis fixed server-side (schemas now emit `select`/`options`); client never needed the prohibited workaround | `SERVER_CONTRACT_STATUS.md` §4 |
| `SYLLABUS_QUESTION_MAPPING_GAP_2026-09-30.md` | Root cause fixed by the syllabus↔topic bridge; residual is editorial, tracked in the server repo | `SERVER_CONTRACT_STATUS.md` §4 |
| `PLAY_STORE_READINESS.md` + `LAUNCH_ROADMAP.md` | Two launch plans, disagreeing about whether `bisaas.com` was ours | `LAUNCH_READINESS.md` |
| `PLAY_STORE_LISTING.md` | A second listing draft whose fields contradicted the fastlane metadata that actually uploads | `store_listing.md` |
| `privacy_policy.md` | Older, longer duplicate of the legal policy, with a false claim that the client keeps the password in the keystore and that deletion is by email | `legal/privacy-policy-en.md` |
| `implementation_plan.md`, `walkthrough.md`, `superpowers/plans/…` | August build plans and a Phase-1 completion report; every item shipped or contradicted | — (git history) |
| `MOBILE_MASTER_PLAN_DUILONGO_V2_2026-09-06.md` | Strategy doc superseded by its own successor and by the shipped UI | `PROJECT_STATE.md` |
| `FLUTTER_SENIOR_REVIEW_2026-08-30.md` | 2,183-line audit of a 52-test app that no longer exists | — (git history) |
| `FLUTTER_APP_DETAIL_PLAN_V2_5000_2026-08-30.md` (2.1 MB) | Pre-build blueprint; nothing in it is operative | — (git history) |
| `reports/BISAAS_5000_LINE_FOUNDER_MARKET_REPORT_2026-08-30.md` (2.1 MB) | Companion market report with the same expired premise | — (git history) |
| `generate_5000_report.py` (repo root) | The generator that emitted those two 2 MB files, with a hardcoded Windows path | — (git history) |
| `ANDROID_SDK_SETUP.md` | Duplicated `README.md` and `AGENTS.md`, and taught API 34 + HAXM for a `compileSdk 37` project | `README.md` §"Emulator and device" |
| `fastlane.metadata.md` | Nine-line scratch note with ASO placeholders and a "232 calculators" claim | `store_listing.md` |
| `references/quizix-reference.txt` | Unreferenced notes with plaintext demo credentials and `D:\` paths | — |
| `assets/translations/` | A dead drop-folder for a translation mechanism the app does not use; also registered in `pubspec.yaml`, so it shipped as bundle surface | `lib/l10n/*.arb` |

Net effect: ~4.2 MB of superseded planning and dated reports left the tree, and
the surviving documents either measured their claims or cite the file that
proves them.

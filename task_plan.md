# Task Plan: CivilCal Flutter Complete

## Goal
Build the market-dominating CivilCal Flutter client (Android+iOS) over bisaas Laravel `/api/v1` — 100% per FLUTTER_APP_MASTER_PLAN_2026.md + mobileapp-design-reserch-flutter.md, zero stubs, server-authoritative, 60fps on Redmi Note 12.

## Next Step
Task 1: Audit & Freeze API Contract — run `GET /api/v1/openapi.json` against `https://bisaas.test` and lock `ApiErrorCode` + envelope.

## Current Phase
Phase 0 — Reading & Planning (complete, plan saved)

## Phases

### Phase 0: Reading & Planning
- [x] Read PWA_MASTER_PLAN_2026.md (13 lines stub)
- [x] Read FLUTTER_APP_MASTER_PLAN_2026.md (3512 lines)
- [x] Read mobileapp-design-reserch-flutter.md (3927 lines)
- [x] Map every module/feature/architecture decision
- [x] Write `docs/superpowers/plans/2026-08-29-civilcal-flutter-complete.md` with 21 tasks
- **Status:** complete

### Phase 1: Foundation Slice (Weeks 1-3)
- [ ] Task 1 — API contract freeze
- [ ] Task 2 — Env & Dio hardening (X-Request-Id, 429, pinning)
- [ ] Task 3 — Secure storage + biometric
- [ ] Task 4 — Bootstrap + Shell router + Splash
- [ ] Task 5 — Auth complete (email/Google/biometric)
- [ ] Task 6 — Design system + l10n
- **Status:** pending

### Phase 2: Home + Quiz Flagship (Weeks 3-5)
- [ ] Task 7 — Onboarding 3 screens
- [ ] Task 8 — Home dashboard real data
- [ ] Task 9 — Quiz data layer (DTO/domain, AnswersTable)
- [ ] Task 10 — Quiz state machine + timer isolation
- [ ] Task 11 — Quiz attempt UI (0ms select → server → green/red + XP + combo)
- [ ] Task 12 — Result + share + review
- **Status:** pending

### Phase 3: Calculators + Gamification (Weeks 4-6)
- [ ] Task 13 — Calculator suite (232, metadata 80/20)
- [ ] Task 14 — Gamification HUD + achievements (Lottie)
- **Status:** pending

### Phase 4: Battle + Social + Courses (Weeks 6-8)
- [ ] Task 15 — Battle Firebase RTDB
- [ ] Task 16 — Profile/courses/downloads + glassmorphic
- **Status:** pending

### Phase 5: Notifications + Offline + Perf (Weeks 7-10)
- [ ] Task 17 — FCM/local + analytics 20 events
- [ ] Task 18 — Offline queue + background fetch 00:00 + crash recovery
- [ ] Task 19 — a11y + adaptive + perf (60fps, <150MB, <2s)
- **Status:** pending

### Phase 6: Testing + Security + Store (Weeks 11-12)
- [ ] Task 20 — Testing pyramid (90% domain) + security matrix
- [ ] Task 21 — CI/CD Fastlane + store ASO + rating prompt
- **Status:** pending

## Key Questions
1. OpenAPI新增 codes? — diff `GET /api/v1/openapi.json` vs `ApiErrorCode` before Task 1.
2. Calculator 232 slugs single source? — Confirm `CalculatorRegistry` is SSOT before Task 13.
3. Firebase project IDs for dev/staging/prod? — Need from bisaas `storage/app/firebase/*-adminsdk.json` before Task 15/17.

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Riverpod + go_router + Dio + Drift + secure_storage | Master plan 2.1 + research #5/#7 — testable, interceptors, reactive, keychain |
| Very_good_analysis strict, flavor via dart-defines | Spec 10.4 + 27.1 startup <2s |
| Server-authoritative grading/coins/achievements | Plan law 1 + AGENTS.md boundary — prevents tamper |
| BasePath `/api/v1` only via ApiConfig | AGENTS.md — no drift, versioned contract |
| 21 tasks, 5 steps each (test fail→impl→pass→commit) | writing-plans skill — bite-sized, TDD |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| PWA_MASTER_PLAN stub 13 lines | 1 | Treat as canonical location note; defer PWA to after Flutter Phase 2 |
| flutter_markdown discontinued | 1 | Kept 0.7.7+1 (works) but noted replacement `flutter_markdown_plus` for Task 6 |

## Notes
- All planning files in project root per planning-with-files v3.9.0
- Plan SHA attested? Run `sh scripts/attest-plan.sh` after approval to block tamper
- Next: choose execution mode — subagent-driven vs inline

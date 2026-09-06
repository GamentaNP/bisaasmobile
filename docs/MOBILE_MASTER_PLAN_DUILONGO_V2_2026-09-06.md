# MOBILE MASTER PLAN — Duilongo v2 (2026-09-06)

> **Goal (user directive):** the best Duolingo-like, animated, Material 3 civil-engineering
> learning app. Everything from the API — **nothing hardcoded in Flutter except the shell**
> (routing, theme, animations, local cache). Web first, then Android, feature by feature,
> ordered by user benefit. All business logic stays server-authoritative in bisaas.
>
> **Method of this plan:** every claim below was verified against reality — a full route
> catalog of `routes/api/v1/*` (200+ routes, 94 controllers), a file-by-file wiring inventory
> of all 27 Flutter feature folders (180 dart files), and **live curl probes against
> `https://bisaas.test/api/v1`** with the QA token. Nothing here is assumed from docs alone.

---

## 1. WHERE WE STAND (verified 2026-09-06)

### 1.1 Working and verified live (do not re-do)

| Surface | Proof |
|---|---|
| Auth (login/register/refresh/logout, secure storage) | E2E login in headless Chrome |
| Quiz core loop: courses → categories → questions → attempt → answers → complete → results | Full 20-question attempt E2E, server-graded review rendered |
| Streak (GET /quiz/streak) | 200, home card live |
| Daily quiz metadata (GET /quiz/daily) | 200, home card live |
| Missions dashboard (GET /quiz/game/missions/dashboard) | 200 — 18 live missions with rewards |
| Contests (list/detail/join/enter/leaderboard/recap) | 200, contest 13 fully shaped |
| Battles REST (POST /quiz/battles, history) | 200 — created battle 11 live with Firebase token |
| Economy wallet/shop | 200 (balance 15 → 25 after check-in test) |
| Skill radar (GET /profile/skills) | 200, renders on Profile |
| Daily check-in (POST /rewards/daily-checkin) | 200 — credited +10 coins live |
| Spin wheel (GET /rewards/spin/status) | 200 — canSpin:true, prizes shaped |
| Achievements (economy/achievements, me/achievements/progress+recent) | 200 — real catalog + progress |
| Game worlds (GET /quiz/game/worlds, /world/{slug}/map) | 200 — 2 worlds, 16 chapters, 8 levels each, stars/bosses/rewards |
| Mobile daily pack (GET /mobile/daily-quiz-pack) | 200 — full question bundle inline (offline-ready) |
| Game engine (worlds→levels), leagues, report-card, lifelines, streak repair/insurance/wager, library, learning, tutor, PSC | **Live on server; wired in client data layers; blocked at UI level** |

### 1.2 The core insight

**The backend is already a finished Duolingo engine.** World map with star-gated
chapters, boss levels, XP/coin rewards per level, leagues, missions, ghost rival,
achievements, daily check-in streak, spin wheel — all serving 200s today. The Flutter
client currently shows a fraction of it and hand-paints fake data where real endpoints
exist. **Our build order is therefore "wire what exists", not "wait for backend".**

### 1.3 Client defects found in inventory (the debt list)

**A. Fake UIs showing hardcoded data (highest shame, user-visible):**
1. `courses_screen.dart:12-23` — 10 fake courses ("10 syllabus tracks", fake %) — subtitle claims "server-authoritative". **Real API exists** (`/syllabi`, public) and the Library tab duplicates this screen's job.
2. `gamification/achievements_screen.dart:20-27` — 6 fake badges, while 3 real achievement endpoints return 200.
3. `profile_screen.dart:205-229` — generated "Badge 1..6" gallery, fake unlock states; also a leaked dev-note string at :245 and streak-mislabeled-as-quizzes stat at :181.
4. `practice_session_screen.dart:189-217` — placeholder A/B/C/D options, local-only answers (whole provisional screen).

**B. Fabricated fallbacks (violates "never invent numbers"):**
- `home_remote_data_source.dart:23-36` — `_fallback` dashboard: fake XP 150, coins 50, fake course "Structural Analysis & Design (RCC) 0.35".
- `dashboard_dto.dart:28-37` — defaults fake XP/coins/daily values when keys missing.
- `economy_repository_impl.dart:52-68` — 5 mock coin packs (pack_100…pack_3500) when shop is empty.
- `store_dto.dart:75-82` — mock asset catalog + wardrobe.

**C. Implemented-but-UI-blocked (wire-up gaps, not backend gaps):**
- Streak repair / insurance / wager — client data layer complete, UI shows "WO-6 coming soon" chips.
- Store Market tab — `GET /store/market` implemented client-side, screen says "coming soon".
- Calculator history — server endpoint exists (`GET /{domain}/{slug}/history`), controller TODOs it and uses in-memory list.
- Lifelines (50/50, hint, skip) — full REST surface exists (`/quiz/attempts/{a}/lifelines/*` incl. purchase/use/ad-unlock); client shows "coming soon" SnackBars.
- Notifications mark-as-read — endpoints exist, client GET-only.
- PSC exam start — endpoint live, UI is a SnackBar.

**D. 34 push-style navigation sites that silently no-op on web** (go_router 18 shell):
auth login ×2, calculator ×3, coaching ×7, contests ×2, economy ×1, learning ×6,
library ×3, live_events ×1, practice ×3, profile ×2, tutor ×4, plus 2 Navigator-style.
Every one must become `context.go` (the pattern already proven in the quiz flow).

**E. Battle is Firebase-dependent and fragile:** `demo` match fallback, result screen
defaults "me = player1", timer uses `DateTime.now()` when `started_at` missing.
Real Firebase project (google-services.json) is a hard prerequisite for battles.

### 1.4 Backend bugs to file (found by live probes; bisaas side)

| Issue | Evidence | Ask |
|---|---|---|
| `GET /quiz/leaderboards/{leaderboard}` 500s for slug values | `where id = 'global'` → PG invalid-input error in laravel-2026-09-06.log | Route should accept a leaderboard **id** (numeric) or resolve slugs; client currently only uses `my-rank` (which works and returns the 4 boards with entries). |
| Daily Quiz has **no API start route** | Web-only `POST /web/quiz/daily/start` (Inertia redirect); API has read-only `GET /quiz/daily` | **REQUEST: `POST /api/v1/quiz/daily/start`** — mint attempt from `DailyQuizService::selectTodaysQuestions` with `mode=daily`, return `{attempt_id, questions[]}` like attempts/start. The client has `GET /mobile/daily-quiz-pack` as a partial workaround (bundle incl. questions) but nothing to open a *graded daily attempt* from mobile. |
| Portal/level play has **no API start route** | Web-only `POST /web/quiz/portal/levels/{level}/start` (PortalQuestService::startLevel); API serves worlds/map/read-only | **REQUEST: `POST /api/v1/quiz/game/levels/{level}/start`** (idempotent, returns attempt) + ensure `GET results` includes star awarding (`stars_earned`, `best_score`). Without it the world map can display but never *play*. |
| Guess-the-word & audio-questions are web-only | `routes/web/quiz.php:163-170` | REQUEST API wrappers when we build those modes (P3+, not urgent). |
| Lifetime XP display: `quiz/game/report-card` returns `currentXp:0` | Probe 200 but zeros while player_hud shows 600 | Verify report-card reads same ledger as player_hud (minor). |

**Rule for backend asks:** file them, don't build around them. The backend is ours
(same founder); the correct fix is a small API controller wrapping the existing
service — NOT duplicating game logic on-device.

---

## 2. TARGET EXPERIENCE (what "best Duilongo" means concretely)

1. **Home = game hub**: real player HUD (XP/coins/streak already live), daily-quiz
   path with one-tap play, missions row (18 live), check-in + spin rewards, streak flame.
2. **Play = world map path** (the Duolingo spine): worlds → chapters → zig-zag node path
   (ChunkyPathNode already built & tap-fixed) with star ratings, boss nodes with crowns,
   lock icons → level intro → the (already proven) attempt screen → star celebration.
3. **Every answer moment feels alive**: chunky buttons with press physics, correct/wrong
   micro-animations, combo flames, XP showers, confetti on level complete (celebration kit).
4. **Progression everywhere**: league standing, achievements with real progress bars,
   report card, ghost rival.
5. **All of it from `/api/v1`** — zero hardcoded content, Material 3 + chunky kit only.

---

## 3. PHASED ROADMAP (each phase = build → E2E in CDP → commit → push)

### P0 — Honesty pass (kill every fake) · ~1 session
*Small diffs, massive credibility gain. Everything else builds on this.*
1. Home `_fallback` + `DashboardDto` fake defaults → show zeros + offline banner (honest), never fabricated XP/course.
2. Courses screen → real `GET /syllabi` (public) or redirect to Browse; delete `_demoCourses`.
3. Profile badge gallery → real `GET /me/achievements/progress` + `recent`; remove dev-note string; fix "Quizzes" stat label.
4. Gamification screen → real achievements catalog (`GET /economy/achievements`).
5. Economy mock coin packs + store mocks → empty-state with real CTA instead of fake catalog.
6. Accept: analyzer 0, tests green, CDP screenshots per screen.

### P1 — Navigation repair (34 push→go) · ~half session
Convert every push-style nav to `context.go` (route names already exist for most);
verify each target screen loads via CDP tap-through. Unblocks all deeper work.

### P2 — Game spine: World Map (THE Duilongo core) · 2-3 sessions
The centerpiece. Data all live:
1. **Backend ask first:** file `POST /quiz/game/levels/{level}/start` request (§1.4) — until it lands, levels play via the proven course-question attempt path using the level's `questionCount` + chapter course mapping (works today, real grading, real XP; stars/level-completion sync server-side via attempt complete on the same course).
2. New `game` feature folder: worlds list (2 live) → world map (16 chapters × 8 levels, star thresholds, boss flags) rendered on the ChunkyPathNode path.
3. Level intro reuses QuizIntroScreen pattern (real xpReward/coinReward/questionCount from map payload).
4. Level complete → celebration overlay (stars animate, XP shower) using real `results` payload.
5. Wire existing `report-card` + `league` endpoints onto Profile/progress surfaces.

### P3 — Rewards loop (retention core) · 1-2 sessions
All endpoints verified live today:
1. Daily check-in card (status + claim, streakDay ladder) — POST verified crediting coins.
2. Spin wheel (status + spin) — prizes shaped (`coins/xp/lifelineSlug`), claymorphism wheel.
3. Missions: dashboard is live (18 missions) → missions sheet + `POST /missions/{id}/claim`.
4. Streak economy: unblock the already-built client calls for repair/insurance/wager (remove WO-6 gates).

### P4 — Lifelines in the attempt screen · 1 session
REST surface exists incl. purchase/use/ad-unlock (`GET /attempts/{a}/lifelines` returns
state). Wire 50/50, Hint (`GET /quiz/questions/{id}/hint`), Skip. Remove the three
"coming soon" SnackBars. Also send `time_taken_seconds` per answer (integrity engine feed).

### P5 — Daily Quiz playable · 1 session (needs backend ask from §1.4)
`POST /quiz/daily/start` (requested) → daily card one-tap play → same attempt UI →
streak credit visible. Until shipped, daily card deep-links to Browse with the day's
category spotlight.

### P6 — Battles for real · 1-2 sessions (needs Firebase project)
1. Prereq: founder supplies `google-services.json` (FIREBASE_SETUP.md steps; plugin already conditional).
2. Wire join/end/results/history endpoints (already documented in the client's datasource).
3. Fix `demo` fallback, wire result screen "me" via Firebase auth uid, timer from server `started_at`.
4. Matchmaking UX: chunky VS screen, live opponent progress bar via RTDB `current_idx` (already subscribed).

### P7 — Social + notifications polish · 1 session
Social screen tiles → real referral dashboard (`/social/referral-dashboard`) and
leaderboard routes; notifications mark-read + deep-link execution.

### P8 — Offline premium + PSC exam + guess-word/audio · later
Needs backend decisions (pack issuance UX, exam-taking UI, API wrappers for web-only
modes). Explicitly deferred — no user benefit until P0-P6 shine.

---

## 4. BACKEND REQUEST LIST (hand to bisaas — copy verbatim)

1. **`POST /api/v1/quiz/daily/start`** — start today's daily quiz (wraps `DailyQuizService::selectTodaysQuestions` + `AttemptService::start(mode=daily)`); response shape = attempts/start (`attempt_id`); idempotent; respects `has_completed`.
2. **`POST /api/v1/quiz/game/levels/{level}/start`** — wrap `PortalQuestService::startLevel` for API clients; idempotent; return attempt_id + level snapshot. (Without it mobile can render the world map but not open a level.)
3. **Leaderboard route fix** — `GET /quiz/leaderboards/{leaderboard}` 500s on non-numeric ids; accept ids or add slug resolution.
4. **Star awarding exposure** — ensure attempt `results` for level attempts include `stars_earned` (or add to report-card) so mobile can celebrate correctly.
5. *(Later, P8)* API wrappers for guess-the-word / audio-questions; PSC exam-taking payload guidance.

Everything else mobile needs is **already served** — verified 200 in §1.1.

---

## 5. WORKING AGREEMENT (how each phase runs)

- **Reality-first:** before building any surface, curl the endpoint with the QA token; paste the observed shape into the data source's doc comment. No endpoint, no feature (file ask instead).
- **Envelope rules:** `{success,data,...}`; offset vs cursor pagination per guide §4; `Idempotency-Key` on every money/progress POST (start/answer/complete/purchase/claim/spin); `time_taken_seconds` on answers.
- **Nothing hardcoded:** shell (routes/theme/animations/cache) in Flutter; every number, title, reward from API. Fallbacks show honest zeros + offline UI, never invented data.
- **Verification gate per phase:** `flutter analyze` 0 issues → `flutter test` green → `flutter build web --release --dart-define=ENV=dev` → CDP drive the new surface headless-Chrome (screenshots into /tmp/cdp) → phase commit(s) with the proof in the message → push.
- **Respect the parallel agent** in bisaas/bisaasmobile: re-read files before editing, never commit their mid-write files.
- **QA account:** qa.tester@bisaas.test / QaTest2026! (device_name required on login).

## 6. IMMEDIATE NEXT ACTION

Start **P0 (honesty pass)** — six small fixes, all data endpoints already verified live.

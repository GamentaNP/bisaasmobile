# Asset licenses

The source and licence of every third-party visual asset bundled with
CivilCal. **Rule:** only OFL / CC0 / "free for commercial use" assets may be
bundled. Update this file whenever an asset is added or replaced.

Verified against the tree on 2026-11-04.

## Fonts — all OFL 1.1

| File (under `assets/fonts/`) | Source | Licence |
|---|---|---|
| `InstrumentSans-Regular.ttf`, `-Medium`, `-SemiBold`, `-Bold` | https://fonts.google.com/specimen/Instrument+Sans | OFL 1.1 |
| `noto/NotoSansDevanagari-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari | OFL 1.1 |
| `noto/NotoSansArabic-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Arabic | OFL 1.1 |
| `noto/NotoSansBengali-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Bengali | OFL 1.1 |
| `noto/NotoSansTamil-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Tamil | OFL 1.1 |
| `noto/NotoSansTelugu-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Telugu | OFL 1.1 |

The Noto faces are the per-glyph fallbacks behind `lib/app/theme/script_fonts.dart`:
a script the Instrument/Devanagari pair cannot draw falls through to the
matching Noto face, so a Bengali or Tamil string renders instead of showing
boxes. They ship so the fallback works offline.

## Animations — project placeholders

All nine files under `assets/animations/` are **minimal valid Lottie schemas
written for this project**, not downloaded artwork:

| File | Intended production asset |
|---|---|
| `level_up.json` | "level up stars" |
| `achievement_unlock.json` | "trophy unlock" |
| `confetti.json` | "confetti celebration" |
| `correct_answer.json` | "checkmark success" |
| `wrong_answer.json` | "incorrect x" |
| `streak_fire.json` | "fire flame loop" |
| `battle_win.json` | "victory crown" |
| `battle_lose.json` | "game over" |
| `loading_engineering.json` | "engineering gear" |

Because they are original placeholders, there is **no third-party licence to
record** — and nothing to attribute. If one is replaced with a downloaded
LottieFiles asset, add its source URL and licence to this table **in the same
commit**, and confirm the licence permits commercial use (LottieFiles hosts
both free and paid licences; the file itself does not tell you which).

## Brand SVGs — custom, project-owned

`logo.svg`, `logo_dark.svg`, `logo_icon.svg`, `onboarding_{1,2,3}.svg`,
`empty_quiz.svg`, `empty_calculator.svg`, `offline.svg`, `battle_vs.svg` —
created for Bisaas. All rights reserved by the project.

## Compliance notes

- Play review does not audit font licences line by line, but a takedown
  request is the real risk; OFL requires attribution, which this file
  provides. Keep the licence text available if the fonts are redistributed
  outside the APK.
- An asset whose licence changes must be replaced or removed at the same time
  as this file is updated.

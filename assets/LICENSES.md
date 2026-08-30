# Asset Licenses

This file tracks the source URL and license of every third-party visual asset bundled with Bisaasmobile (CivilCal).

> **Rule:** Only assets with a "Free for commercial use" / OFL / CC0 / similar permissive license may be bundled. Update this file when adding or replacing any asset.

## Fonts (OFL — Open Font License)
| File | Source | License |
|---|---|---|
| `assets/fonts/InstrumentSans-Regular.ttf` | https://fonts.google.com/specimen/Instrument+Sans | OFL 1.1 |
| `assets/fonts/InstrumentSans-Medium.ttf` | https://fonts.google.com/specimen/Instrument+Sans | OFL 1.1 |
| `assets/fonts/InstrumentSans-SemiBold.ttf` | https://fonts.google.com/specimen/Instrument+Sans | OFL 1.1 |
| `assets/fonts/InstrumentSans-Bold.ttf` | https://fonts.google.com/specimen/Instrument+Sans | OFL 1.1 |
| `assets/fonts/NotoSansDevanagari-Regular.ttf` | https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari | OFL 1.1 |

## Lottie Animations (LottieFiles)
> **Status (2026-08-30):** Placeholders shipped (`*.json` minimal valid Lottie schema). Replace each with the production file downloaded from lottiefiles.com — search terms per `docs/mobileapp/STATUS_2026-08-30.md` §Block 1.

| File | Search term on lottiefiles.com | Required license | Source URL | Downloaded |
|---|---|---|---|---|
| `level_up.json` | "level up stars" | Free for commercial use | _fill in_ | ☐ |
| `achievement_unlock.json` | "trophy unlock" | Free for commercial use | _fill in_ | ☐ |
| `confetti.json` | "confetti celebration" | Free for commercial use | _fill in_ | ☐ |
| `correct_answer.json` | "checkmark success" | Free for commercial use | _fill in_ | ☐ |
| `wrong_answer.json` | "incorrect x" | Free for commercial use | _fill in_ | ☐ |
| `streak_fire.json` | "fire flame loop" | Free for commercial use | _fill in_ | ☐ |
| `battle_win.json` | "victory crown" | Free for commercial use | _fill in_ | ☐ |
| `battle_lose.json` | "game over" | Free for commercial use | _fill in_ | ☐ |
| `loading_engineering.json` | "engineering gear" | Free for commercial use | _fill in_ | ☐ |

## Brand SVGs (custom)
| File | Source | License |
|---|---|---|
| `logo.svg`, `logo_dark.svg`, `logo_icon.svg` | Custom — Bisaas team | All rights reserved (project) |
| `onboarding_{1,2,3}.svg` | Custom — Bisaas team | All rights reserved (project) |
| `empty_quiz.svg`, `empty_calculator.svg`, `offline.svg`, `battle_vs.svg` | Custom — Bisaas team | All rights reserved (project) |

## Compliance Notes
- Play Store review checks that fonts are OFL-licensed and animations are commercially usable.
- All third-party assets are replaced at the source URL listed above; if a license changes, the asset must be replaced or removed.
- This file is referenced in `MOBILE_API_INTEGRATION_GUIDE.md` mobile section and audited during the W0 governance gate.

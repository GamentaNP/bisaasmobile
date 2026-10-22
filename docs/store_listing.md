# Store listing — CivilCal

The canonical source for both store listings. The text that fastlane
uploads lives in `android/fastlane/metadata/android/` and
`ios/fastlane/metadata/`; this document is the reviewable version, with
the character limits and the facts behind each claim.

Every factual claim in the listing is checked against the code or the
database before it is written. Where a number could go stale, the copy
uses a floor (`170+`) rather than an exact count.

---

## 1. Product name

| Store | Value | Limit |
|---|---|---|
| Play | `CivilCal: Engineering Prep` | 30 — **26** |
| App Store | `CivilCal: Engineering Prep` | 30 — **26** |
| App Store (Nepali) | `CivilCal: इन्जिनियरिङ तयारी` | 30 — **27** |

`CFBundleDisplayName` in `ios/Runner/Info.plist` and the `android:label`
in `android/app/src/main/AndroidManifest.xml` are both `CivilCal`. The
stores show the store listing name, not the launcher label, so the
launcher still reads `CivilCal` while the listing reads
`CivilCal: Engineering Prep`.

---

## 2. Short description

| Store | Value | Limit |
|---|---|---|
| Play (en) | `Quiz, calculate and rank — prep for Loksewa, PSC and engineering exams.` | 80 — **71** |
| Play (ne) | `लोकसेवा, PSC र इन्जिनियरिङ परीक्षाको लागि प्रश्न, क्यालकुलेटर र रैंक।` | 80 — **69** |
| App Store subtitle (en) | `Loksewa, PSC & engineering` | 30 — **26** |
| App Store subtitle (ne) | `लोकसेवा, PSC र इन्जिनियरिङ` | 30 — **26** |

---

## 3. Keywords (App Store only, 100 characters)

```
loksewa,psc,engineering,quiz,calculator,notes,exam prep,nepal,streak,battle,offline,study
```

89 characters. The Nepali listing uses the same English keywords plus
`परीक्षा` and `नेपाल`, because Nepali users search for the English
transliterations as often as the Devanagari forms.

---

## 4. Claims, and where each one comes from

| Claim | Verified against |
|---|---|
| "170+ engineering calculators" | `calculator_catalog_entries` — **173** published rows, all free: hvac 42, civil 36, estimation 27, plumbing 21, electrical 14, structural 10, fire 9, medical-gas 9, plus 5 cross-discipline `shared` entries. (The "232" figure in earlier planning documents is stale.) |
| "8 disciplines" in the description | The published catalog spans **9** domains; the description names the 8 engineering ones and the 9th (`shared`) holds cross-discipline entries that are not a discipline of their own. The wording is accurate as written. |
| "Every result comes with a step-by-step solution" | `steps_in_response` on the calculator DTO (`lib/features/calculator/data/models/calculator_dto.dart:99`). |
| "Ask the AI assistant … then apply it to any field with one tap" | `CalculatorAssistantPanel` + the apply callback (`lib/features/calculator/presentation/screens/calculator_detail_screen.dart:277`, `:180`). |
| "AI tutor in Nepali, Hindi or English" | The app's language seed is `en`, `ne`, `hi` (`lib/app/localization/app_languages.dart:124`). |
| "Bring your own AI key" | `GET/POST /ai-keys` — the AI settings screen (`lib/features/ai_settings/`). |
| "Daily streaks, XP, coins and achievements" | `lib/features/streak/`, `lib/features/gamification/`, `lib/features/economy/`. |
| "Live battle" | `lib/features/battle/`. |
| "Weekly contests" | `lib/features/contests/`. |
| "repair your streak with the coins you earn" | `POST /quiz/streak/repair` costs **50 coins** to bridge a missed day; `POST /quiz/streak/insurance` banks an auto-repair token for **200 coins** each, up to three (`lib/features/streak/data/datasources/streak_remote_data_source.dart:12`). |
| "freeze it for a month" | `POST /donations/freeze-streak` freezes the streak for **30 days** for **50 coins**, and additionally requires a donor badge. The copy says "with the coins you earn" for the repair and mentions the month for the freeze; the donor-badge condition is a niche detail that the store copy does not need, but it must not claim the freeze is *earned by playing* — that was the earlier wording and it was wrong. |
| "Download course packs, notes and question sets … work offline" | `lib/features/downloads/`, `lib/features/library/`, plus the Drift database and the offline sync queue (`lib/core/sync/`). |
| "When you get back online, your answers sync automatically" | `lib/core/sync/sync_worker.dart`, driven by the app lifecycle (`lib/app/app.dart:85`). |
| "Android 9 and up" | `minSdk = 28` in `android/app/build.gradle.kts`. |
| "Light on battery and data" | A qualitative claim — reasonable for a Flutter client with a Drift cache, but it is not measured. Keep it. |
| "Analytics are opt-in" | `lib/core/consent/consent_gate.dart` — every event is dropped unless consent is granted. |
| "We never sell your information" | There is no advertising SDK in the dependency tree and no ad id in the manifest. |
| "Your sign-in token is kept in the device's secure keystore, and the app's data is excluded from backups" | `flutter_secure_storage` + `android:allowBackup="false"` + `res/xml/backup_rules.xml` + `res/xml/data_extraction_rules.xml`. |
| "no in-app purchases" | The store sells **cosmetic assets bought with in-app coins** — avatar frames, badges, themes, titles — priced in coins (`StoreAsset.priceCoins`), with a player-to-player trading market (`lib/features/store/domain/entities/store.dart:30`). There is **no real-money purchase**: no billing library is in the dependency tree. The earlier wording ("some study packs and AI usage are optional extras") was wrong on both counts and has been removed. |
| "trade them with other students" | The market listing on the store screen — `MarketListing` (`lib/features/store/domain/entities/store.dart:67`). |
| "Nepali, Hindi and English" | The **whole interface** is translated into all three — 1087 messages, every screen, including the error messages a user reads when something fails. `test/app/localization_coverage_test.dart` asserts that the app contains no hardcoded user-facing string, so the promise cannot quietly narrow. The *question content* is localised separately by the server through `Accept-Language`. See `docs/localization.md`. |

---

## 5. Assets still missing

- [ ] **Screenshots.** Play requires at least two phone screenshots;
      the App Store requires one per device family. The metadata trees
      have no `images/` folder because a screenshot has to be taken on a
      real device.
- [ ] **Feature graphic / promo images** for the Play listing.
- [ ] **App icon** — done. `assets/images/logo_icon.png` is the source,
      regenerated by `tool/generate_launcher_icon.py`.
- [ ] **Privacy policy URL** — `docs/privacy_policy.md` is the source;
      it has to be published at a live URL that
      `https://bisaas.com/privacy` resolves to.

---

## 6. Locales

The app ships `en`, `ne` and `hi`. The store listings are published in
`en-US` and `ne`.

`hi` is **not** published yet, deliberately: the Hindi UI exists, but a
Hindi store listing in the first release would promise support the team
is not yet staffed to answer. Publish it when the Hindi question bank is
ready and the support desk can take Hindi.

---

## 7. Updating a listing

The metadata files are plain text and are uploaded by fastlane:

```bash
# Play
cd android && fastlane supply --package_name com.bisaas.bisaasmobile \
  --metadata_path fastlane/metadata/android --skip_upload_apk --skip_upload_images

# App Store
cd ios && fastlane deliver --skip_screenshots --skip_binary_upload
```

Both lanes read the metadata from the committed tree, so the listing
lives in version control next to the code that it describes.

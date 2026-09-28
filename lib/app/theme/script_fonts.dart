import 'package:flutter/widgets.dart';

/// Which writing system a piece of text is written in.
///
/// This exists because the app's base family (InstrumentSans) is Latin-only.
/// Before this, 14 of 15 text styles set `fontFamily: 'InstrumentSans'` with
/// no fallback, so a Nepali or Chinese string had no glyph source at all and
/// rendered as tofu boxes — the "multilingual" claim was true only for English.
enum AppScript {
  /// Latin, Greek, Cyrillic — covered by the bundled InstrumentSans.
  latin,

  /// नेपाली / हिन्दी
  devanagari,

  /// 中文
  han,

  /// العربية
  arabic,

  /// বাংলা
  bengali,

  /// தமிழ்
  tamil,

  /// తెలుగు
  telugu,

  /// An unknown script: fall back to whatever the platform provides.
  unknown,
}

/// Maps a language code (or a BCP-47 script subtag) to the font family that
/// can actually draw it, and to the writing direction.
///
/// Family names match Google Fonts so they resolve through `google_fonts`
/// (runtime fetch + cache) and fall back to the platform's own Noto faces when
/// that is unavailable or the device is offline.
abstract final class ScriptFonts {
  const ScriptFonts._();

  /// Bundled family. Latin only — fine for English, useless for the rest.
  static const latinFamily = 'InstrumentSans';

  /// Ordered so the first family that has the glyph wins. Flutter walks this
  /// list per character, so a mixed string (e.g. "Beam Beam Moment") keeps the
  /// branded Latin face while the Devanagari run renders correctly.
  static const Map<AppScript, List<String>> families = {
    AppScript.latin: [latinFamily],
    AppScript.devanagari: ['NotoSansDevanagari', 'NotoSansDevanagariUI', 'Nirmala UI', 'sans-serif'],
    AppScript.han: ['NotoSansSC', 'NotoSansCJKsc', 'SourceHanSansSC', 'sans-serif'],
    AppScript.arabic: ['NotoNaskhArabic', 'NotoSansArabic', 'Geeza Pro', 'sans-serif'],
    AppScript.bengali: ['NotoSansBengali', 'NotoSansBengaliUI', 'Shonar Bangla', 'sans-serif'],
    AppScript.tamil: ['NotoSansTamil', 'NotoSansTamilUI', 'Latha', 'sans-serif'],
    AppScript.telugu: ['NotoSansTelugu', 'NotoSansTeluguUI', 'Gautami', 'sans-serif'],
    AppScript.unknown: [latinFamily, 'sans-serif'],
  };

  static List<String> forScript(AppScript script) =>
      families[script] ?? families[AppScript.unknown]!;

  /// Resolves the script for a BCP-47 language code.
  ///
  /// Falls back to the *script* subtag when present (`zh-Hans`, `zh-Hant`) so
  /// simplified and traditional Chinese can be distinguished, then to the
  /// language, then to [AppScript.unknown].
  static AppScript forLanguage(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) return AppScript.unknown;
    final lower = languageCode.toLowerCase();

    // BCP-47 script subtags are 4 letters (Hans, Hant, Arab, Beng, Deva...).
    final parts = lower.split(RegExp('[-_]'));
    if (parts.length > 1 && parts[1].length == 4) {
      final byScript = _byScriptSubtag[parts[1]];
      if (byScript != null) return byScript;
    }

    return _byLanguage[parts.first] ?? AppScript.unknown;
  }

  static const Map<String, AppScript> _byScriptSubtag = {
    'latn': AppScript.latin,
    'deva': AppScript.devanagari,
    'hans': AppScript.han,
    'hant': AppScript.han,
    'arab': AppScript.arabic,
    'beng': AppScript.bengali,
    'taml': AppScript.tamil,
    'telu': AppScript.telugu,
  };

  static const Map<String, AppScript> _byLanguage = {
    'en': AppScript.latin,
    'es': AppScript.latin,
    'fr': AppScript.latin,
    'de': AppScript.latin,
    'pt': AppScript.latin,
    'ne': AppScript.devanagari,
    'hi': AppScript.devanagari,
    'mr': AppScript.devanagari,
    'sa': AppScript.devanagari,
    'zh': AppScript.han,
    'yue': AppScript.han,
    'ar': AppScript.arabic,
    'fa': AppScript.arabic,
    'ur': AppScript.arabic,
    'bn': AppScript.bengali,
    'ta': AppScript.tamil,
    'te': AppScript.telugu,
  };

  /// Writing direction, matching the server's `languages.direction` column.
  static TextDirection directionFor(AppScript script) =>
      script == AppScript.arabic ? TextDirection.rtl : TextDirection.ltr;
}

/// Applies the right font family, fallback chain and tracking to a text style.
///
/// Two things this fixes that a plain `fontFamily` swap does not:
///
/// * **Negative letter spacing is destructive for non-Latin scripts.** The
///   display styles use `letterSpacing: -0.25` to tighten the big Latin numbers.
///   Devanagari and Arabic join across letter boundaries (conjuncts, cursive
///   joining), so the same tracking visually pulls joined glyphs apart and can
///   break the shaping. Tracking is therefore only kept for Latin.
/// * **A single `fontFamily` cannot render mixed runs.** Flutter picks one
///   family per run unless a `fontFamilyFallback` chain is given, so the base
///   family has to be the *first* candidate and the script face a fallback —
///   not the other way round.
TextStyle withScriptFallback(TextStyle style, AppScript script) {
  final families = ScriptFonts.forScript(script);
  final isLatin = script == AppScript.latin || script == AppScript.unknown;

  return style.copyWith(
    fontFamily: families.first,
    fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
    // Only the Latin display tracking is safe.
    letterSpacing: isLatin ? style.letterSpacing : 0,
  );
}

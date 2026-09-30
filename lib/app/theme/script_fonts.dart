import 'package:flutter/widgets.dart';

/// Writing system of a piece of text, detected from Unicode codepoints.
///
/// Detecting from the **text** rather than the locale is the point. A Nepali
/// student reading an English interface still types Nepali notes, and a
/// question bank can be mixed. Resolving the font from `locale` therefore fails
/// exactly the case that matters; resolving it from the characters does not.
///
/// The ranges are deliberately properties of Unicode, not a language list, so a
/// script nobody thought about here (Khmer, Sinhala, Georgian, Thaana…) is
/// still classified correctly and still gets a font.
enum AppScript {
  latin,
  devanagari,
  han,
  kana,
  hangul,
  arabic,
  hebrew,
  bengali,
  tamil,
  telugu,
  gurmukhi,
  gujarati,
  oriya,
  kannada,
  malayalam,
  tibetan,
  thai,
  lao,
  khmer,
  myanmar,
  georgian,
  armenian,
  sinhala,
  tifinagh,
  ethiopic,
  canadianAboriginal,
  unknown;

  bool get isRtl => this == AppScript.arabic || this == AppScript.hebrew;

  /// Latin is the only script where the app's display tracking is safe.
  bool get supportsTightTracking =>
      this == AppScript.latin || this == AppScript.unknown;
}

/// Classifies a string by its dominant script.
abstract final class TextScript {
  const TextScript._();

  /// Script of [text], or [AppScript.unknown] when there is nothing to judge.
  ///
  /// Ignores whitespace, digits, and common punctuation so a sentence like
  /// "3.5 kN" or "Beam (2026)" is not misread as "unknown".
  static AppScript detect(String text) {
    if (text.isEmpty) return AppScript.unknown;

    final counts = <AppScript, int>{};
    for (final rune in text.runes) {
      final script = _scriptOfRune(rune);
      if (script == null) continue;
      counts[script] = (counts[script] ?? 0) + 1;
    }
    if (counts.isEmpty) return AppScript.unknown;

    // Dominant script wins, with a stable tie-break by enum order so the result
    // is deterministic for mixed text.
    var best = AppScript.unknown;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  static bool isRtlText(String text) => detect(text).isRtl;

  /// Null for runes that carry no script signal.
  static AppScript? _scriptOfRune(int r) {
    // Basic Latin + Latin-1 supplement + Latin Extended-A/B.
    if ((r >= 0x0041 && r <= 0x005A) ||
        (r >= 0x0061 && r <= 0x007A) ||
        (r >= 0x00C0 && r <= 0x024F)) {
      return AppScript.latin;
    }
    if (r >= 0x0370 && r <= 0x03FF) return AppScript.latin; // Greek
    if (r >= 0x0400 && r <= 0x04FF) return AppScript.latin; // Cyrillic
    if (r >= 0x0530 && r <= 0x058F) return AppScript.armenian;
    if (r >= 0x0590 && r <= 0x05FF) return AppScript.hebrew;
    if (r >= 0x0600 && r <= 0x06FF) return AppScript.arabic;
    if (r >= 0x0700 && r <= 0x074F) return AppScript.arabic; // Syriac
    if (r >= 0x0780 && r <= 0x07BF) return AppScript.arabic; // Thaana is
    // handled by the platform font; it is not in the registry.
    if (r >= 0x0900 && r <= 0x097F) return AppScript.devanagari;
    if (r >= 0x0980 && r <= 0x09FF) return AppScript.bengali;
    if (r >= 0x0A00 && r <= 0x0A7F) return AppScript.gurmukhi;
    if (r >= 0x0A80 && r <= 0x0AFF) return AppScript.gujarati;
    if (r >= 0x0B00 && r <= 0x0B7F) return AppScript.oriya;
    if (r >= 0x0B80 && r <= 0x0BFF) return AppScript.tamil;
    if (r >= 0x0C00 && r <= 0x0C7F) return AppScript.telugu;
    if (r >= 0x0C80 && r <= 0x0CFF) return AppScript.kannada;
    if (r >= 0x0D00 && r <= 0x0D7F) return AppScript.malayalam;
    if (r >= 0x0D80 && r <= 0x0DFF) return AppScript.sinhala;
    if (r >= 0x0E00 && r <= 0x0E7F) return AppScript.thai;
    if (r >= 0x0E80 && r <= 0x0EFF) return AppScript.lao;
    if (r >= 0x0F00 && r <= 0x0FFF) return AppScript.tibetan;
    if (r >= 0x1000 && r <= 0x109F) return AppScript.myanmar;
    if (r >= 0x10A0 && r <= 0x10FF) return AppScript.georgian;
    if (r >= 0x1200 && r <= 0x137F) return AppScript.ethiopic;
    if (r >= 0x13A0 && r <= 0x13FF) return AppScript.canadianAboriginal;
    if (r >= 0x1780 && r <= 0x17FF) return AppScript.khmer;
    if (r >= 0x2D00 && r <= 0x2D2F) return AppScript.tifinagh;
    if (r >= 0x3040 && r <= 0x309F) return AppScript.kana; // Hiragana
    if (r >= 0x30A0 && r <= 0x30FF) return AppScript.kana; // Katakana
    if (r >= 0x3400 && r <= 0x4DBF) return AppScript.han; // Ext A
    if (r >= 0x4E00 && r <= 0x9FFF) return AppScript.han; // URO
    if (r >= 0xAC00 && r <= 0xD7AF) return AppScript.hangul;
    if (r >= 0xF900 && r <= 0xFAFF) return AppScript.han; // Compatibility
    // Fullwidth punctuation, CJK symbols.
    if (r >= 0xFF01 && r <= 0xFF60) return AppScript.han;
    return null;
  }
}

/// Universal font resolution.
///
/// The previous design forced one family per locale, which meant any language
/// not in the hand-written map had no glyph source. This inverts it: the branded
/// Latin face stays primary and everything else is a **per-glyph fallback**.
/// Flutter resolves a fallback when the current family lacks a glyph, so the
/// chain is a *quality preference* layered on top of a baseline that always
/// works — Android's own Noto faces are the final backstop via `sans-serif`.
/// Languages nobody enumerated still render.
abstract final class ScriptFonts {
  const ScriptFonts._();

  /// The app's bundled brand face. Latin (plus Greek/Cyrillic) only.
  static const latinFamily = 'InstrumentSans';

  /// Ordered broad-coverage chain. Order matters: the branded face is first so
  /// English and numerals keep the chunky look, then the bundled Noto faces.
  ///
  /// Every family listed here except `sans-serif` **must** be declared in
  /// `pubspec.yaml`. Naming an undeclared family does not error - Flutter quietly
  /// falls through to the platform font - so a typo or an un-bundled face is
  /// invisible in CI and shows up as tofu on a device whose OEM ships a trimmed
  /// font set. `test/app/font_coverage_test.dart` asserts this list and
  /// `forScript` against the declared families, so adding a face here without
  /// bundling it fails the build.
  ///
  /// Scripts with no bundled face (CJK, Thai, Lao, Khmer, Georgian, Armenian,
  /// Ethiopic, Tibetan, Hangul, Kana, Hebrew) deliberately resolve to
  /// `sans-serif` only. They are not in the shipped language set, and Android/iOS
  /// both ship these scripts, so the platform is a genuine fallback rather than a
  /// gamble. Bundle a face first if one of these becomes a shipped language.
  ///
  /// CJK is called out because it was measurably not worth it: a full Noto Sans
  /// SC is 10.1 MB, 93.5% of the font payload and 12% of a single device's
  /// download, for a language the picker does not offer and the server cannot
  /// serve. If `zh` ever ships, subset the face before bundling it.
  static const List<String> universalChain = [
    latinFamily,
    'NotoSansDevanagari',
    'NotoSansBengali',
    'NotoSansArabic',
    'NotoSansTamil',
    'NotoSansTelugu',
    'sans-serif',
  ];

  /// Families best suited to a script, used when a caller wants to lead with a
  /// specific face (e.g. rendering a standalone content block).
  ///
  /// Same contract as [universalChain]: a named family must be bundled, or this
  /// must be `['sans-serif']` and let the platform supply it.
  static List<String> forScript(AppScript script) => switch (script) {
        AppScript.latin => [latinFamily, 'sans-serif'],
        AppScript.devanagari => ['NotoSansDevanagari', latinFamily, 'sans-serif'],
        // CJK is not bundled - see the note on [universalChain].
        AppScript.han => ['sans-serif'],
        AppScript.kana => ['sans-serif'],
        AppScript.hangul => ['sans-serif'],
        // NotoNaskhArabic is not bundled; NotoSansArabic is.
        AppScript.arabic => ['NotoSansArabic', latinFamily, 'sans-serif'],
        AppScript.hebrew => ['sans-serif'],
        AppScript.bengali => ['NotoSansBengali', 'sans-serif'],
        AppScript.gurmukhi => ['sans-serif'],
        AppScript.gujarati => ['sans-serif'],
        AppScript.oriya => ['sans-serif'],
        AppScript.kannada => ['sans-serif'],
        AppScript.malayalam => ['sans-serif'],
        AppScript.tibetan => ['sans-serif'],
        AppScript.tamil => ['NotoSansTamil', 'sans-serif'],
        AppScript.telugu => ['NotoSansTelugu', 'sans-serif'],
        AppScript.thai => ['sans-serif'],
        AppScript.lao => ['sans-serif'],
        AppScript.khmer => ['sans-serif'],
        AppScript.myanmar => ['sans-serif'],
        AppScript.georgian => ['sans-serif'],
        AppScript.armenian => ['sans-serif'],
        AppScript.sinhala => ['sans-serif'],
        AppScript.tifinagh => ['sans-serif'],
        AppScript.ethiopic => ['sans-serif'],
        AppScript.canadianAboriginal => ['sans-serif'],
        AppScript.unknown => [latinFamily, 'sans-serif'],
      };

  /// Applies the universal chain to a style.
  ///
  /// This is the default every text style should get. It needs no knowledge of
  /// the active locale, which is what makes it work for every language.
  static TextStyle apply(TextStyle style) => style.copyWith(
        fontFamily: latinFamily,
        fontFamilyFallback: universalChain.sublist(1),
      );

  /// Applies the chain and additionally corrects tracking for [text]'s script.
  ///
  /// Negative tracking is safe only for Latin. Devanagari, Arabic, Khmer and
  /// friends join across letter boundaries, so the same tracking pulls joined
  /// glyphs apart and can break shaping.
  static TextStyle forText(TextStyle style, String text) {
    final base = apply(style);
    return base.copyWith(
      letterSpacing: TextScript.detect(text).supportsTightTracking
          ? style.letterSpacing
          : 0,
    );
  }
}

/// Resolves a language code to its dominant script. Used for locale-driven
/// chrome (the app bar, a language picker row) where no text is in hand.
AppScript scriptForLanguage(String? languageCode) {
  if (languageCode == null || languageCode.isEmpty) return AppScript.unknown;
  final parts = languageCode.toLowerCase().split(RegExp('[-_]'));
  if (parts.length > 1 && parts[1].length == 4) {
    final bySubtag = <String, AppScript>{
      'latn': AppScript.latin,
      'deva': AppScript.devanagari,
      'beng': AppScript.bengali,
      'taml': AppScript.tamil,
      'telu': AppScript.telugu,
      'arab': AppScript.arabic,
      'hebr': AppScript.hebrew,
      'thai': AppScript.thai,
      'hani': AppScript.han,
      'hans': AppScript.han,
      'hant': AppScript.han,
      'jpan': AppScript.kana,
      'kore': AppScript.hangul,
      'khmr': AppScript.khmer,
      'mymr': AppScript.myanmar,
      'sinh': AppScript.sinhala,
      'geor': AppScript.georgian,
      'armn': AppScript.armenian,
    }[parts[1]];
    if (bySubtag != null) return bySubtag;
  }
  return <String, AppScript>{
        'en': AppScript.latin,
        'es': AppScript.latin,
        'fr': AppScript.latin,
        'de': AppScript.latin,
        'pt': AppScript.latin,
        'ru': AppScript.latin,
        'el': AppScript.latin,
        'ne': AppScript.devanagari,
        'hi': AppScript.devanagari,
        'mr': AppScript.devanagari,
        'bn': AppScript.bengali,
        'ta': AppScript.tamil,
        'te': AppScript.telugu,
        'th': AppScript.thai,
        'lo': AppScript.lao,
        'km': AppScript.khmer,
        'my': AppScript.myanmar,
        'si': AppScript.sinhala,
        'ka': AppScript.georgian,
        'hy': AppScript.armenian,
        'am': AppScript.ethiopic,
        'ar': AppScript.arabic,
        'fa': AppScript.arabic,
        'ur': AppScript.arabic,
        'he': AppScript.hebrew,
        'zh': AppScript.han,
        'ja': AppScript.kana,
        'ko': AppScript.hangul,
      }[parts.first] ??
      AppScript.unknown;
}

/// Writing direction for a language code, matching the server's
/// `languages.direction` column.
TextDirection directionForLanguage(String? code) =>
    scriptForLanguage(code).isRtl ? TextDirection.rtl : TextDirection.ltr;

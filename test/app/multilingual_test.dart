import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/app/theme/script_fonts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "multilingual" claim was false for every script except Latin: 14 of 15
/// text styles set `fontFamily: 'InstrumentSans'` with no fallback, and that
/// family has no Devanagari, CJK, Arabic, Tamil or Telugu glyphs — so a Nepali
/// or Chinese string had no glyph source at all.
void main() {
  group('script resolution', () {
    test('maps the languages the app offers to their scripts', () {
      expect(ScriptFonts.forLanguage('en'), AppScript.latin);
      expect(ScriptFonts.forLanguage('ne'), AppScript.devanagari);
      expect(ScriptFonts.forLanguage('hi'), AppScript.devanagari);
      expect(ScriptFonts.forLanguage('mr'), AppScript.devanagari);
      expect(ScriptFonts.forLanguage('bn'), AppScript.bengali);
      expect(ScriptFonts.forLanguage('ta'), AppScript.tamil);
      expect(ScriptFonts.forLanguage('te'), AppScript.telugu);
      expect(ScriptFonts.forLanguage('ar'), AppScript.arabic);
      expect(ScriptFonts.forLanguage('zh'), AppScript.han);
    });

    test('is case-insensitive', () {
      expect(ScriptFonts.forLanguage('NE'), AppScript.devanagari);
      expect(ScriptFonts.forLanguage('Zh'), AppScript.han);
    });

    test('honours a BCP-47 script subtag for Chinese', () {
      expect(ScriptFonts.forLanguage('zh-Hans'), AppScript.han);
      expect(ScriptFonts.forLanguage('zh_Hant'), AppScript.han);
      expect(ScriptFonts.forLanguage('zh-Hans-CN'), AppScript.han);
    });

    test('falls back rather than throwing on unknown or null input', () {
      expect(ScriptFonts.forLanguage(null), AppScript.unknown);
      expect(ScriptFonts.forLanguage(''), AppScript.unknown);
      expect(ScriptFonts.forLanguage('xx'), AppScript.unknown);
    });
  });

  group('font families have a real fallback chain', () {
    test('every script except Latin names more than one family', () {
      // One family with no glyphs is exactly the original bug. A chain lets
      // Flutter try the next face per character, so mixed runs work.
      for (final script in AppScript.values) {
        if (script == AppScript.latin) continue;
        expect(
          ScriptFonts.forScript(script).length,
          greaterThan(1),
          reason: '$script needs a fallback chain',
        );
      }
    });

    test('every chain ends in a generic family as a last resort', () {
      for (final script in AppScript.values) {
        expect(
          ScriptFonts.forScript(script).last,
          anyOf('sans-serif', ScriptFonts.latinFamily),
          reason: '$script must have a last-resort family',
        );
      }
    });

    test('Devanagari prefers a Noto Devanagari face first', () {
      expect(ScriptFonts.forScript(AppScript.devanagari).first,
          'NotoSansDevanagari');
    });

    test('Han prefers a CJK face first', () {
      expect(ScriptFonts.forScript(AppScript.han).first, 'NotoSansSC');
    });
  });

  group('direction', () {
    test('Arabic is right-to-left, matching the server registry', () {
      // Verified against the `languages` table: ar has direction 'rtl'.
      expect(ScriptFonts.directionFor(AppScript.arabic), TextDirection.rtl);
    });

    test('everything else is left-to-right', () {
      for (final script in AppScript.values) {
        if (script == AppScript.arabic) continue;
        expect(ScriptFonts.directionFor(script), TextDirection.ltr);
      }
    });
  });

  group('withScriptFallback', () {
    const latinStyle = TextStyle(
      fontFamily: 'InstrumentSans',
      fontSize: 32,
      fontWeight: FontWeight.w800,
      // The real display style uses -0.25 to tighten big Latin numbers.
      letterSpacing: -0.25,
    );

    test('keeps Latin tracking and has no fallback for Latin', () {
      final s = withScriptFallback(latinStyle, AppScript.latin);
      expect(s.letterSpacing, -0.25);
      expect(s.fontFamilyFallback, isNull);
    });

    test('drops negative tracking for Devanagari', () {
      // Devanagari joins across letter boundaries (conjuncts); negative tracking
      // pulls joined glyphs apart and can break shaping.
      final s = withScriptFallback(latinStyle, AppScript.devanagari);
      expect(s.letterSpacing, 0);
      expect(s.fontFamily, 'NotoSansDevanagari');
      expect(s.fontFamilyFallback, isNotNull);
    });

    test('drops negative tracking for Arabic too', () {
      final s = withScriptFallback(latinStyle, AppScript.arabic);
      expect(s.letterSpacing, 0);
      expect(s.fontFamily, 'NotoNaskhArabic');
    });

    test('preserves the size and weight — only family/tracking change', () {
      final s = withScriptFallback(latinStyle, AppScript.han);
      expect(s.fontSize, 32);
      expect(s.fontWeight, FontWeight.w800);
    });
  });

  group('AppLanguages registry', () {
    test('every language has a native name in its own script', () {
      for (final l in AppLanguages.all) {
        expect(l.nativeName, isNotEmpty, reason: '${l.code} needs a native name');
        expect(l.labelEn, isNotEmpty, reason: '${l.code} needs an English name');
      }
    });

    test('native names are not mojibake', () {
      // Two labels in the old hardcoded picker were literally "??????" in
      // source. Assert no replacement characters leaked in.
      for (final l in AppLanguages.all) {
        expect(l.nativeName, isNot(contains('?')));
        expect(l.labelEn, isNot(contains('?')));
      }
    });

    test('covers every script the typography layer knows', () {
      final scripts = AppLanguages.all.map((l) => l.script).toSet();
      // Latin + Devanagari + Han + Bengali + Tamil + Telugu + Arabic.
      expect(scripts.length, greaterThanOrEqualTo(7));
    });

    test('includes Chinese, which the server has no locale for', () {
      // Documented as a client-side-only addition: the server has no zh row.
      expect(AppLanguages.byCode('zh'), isNotNull);
    });

    test('resolves a device locale, falling back to English', () {
      expect(AppLanguages.resolve(const Locale('ne')).code, 'ne');
      expect(AppLanguages.resolve(const Locale('sw')).code, 'en');
      expect(AppLanguages.resolve(null).code, 'en');
    });

    test('byCode is case-insensitive and null-safe', () {
      expect(AppLanguages.byCode('NE')?.code, 'ne');
      expect(AppLanguages.byCode(null), isNull);
      expect(AppLanguages.byCode(''), isNull);
    });

    test('supportedLocales covers the registry for MaterialApp', () {
      expect(AppLanguages.supportedLocales.length, AppLanguages.all.length);
      expect(
        AppLanguages.supportedLocales.map((l) => l.languageCode).toSet(),
        AppLanguages.all.map((l) => l.code).toSet(),
      );
    });
  });
}

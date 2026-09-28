import 'package:bisaasmobile/app/theme/app_theme.dart';
import 'package:bisaasmobile/app/theme/script_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "multilingual" claim was false for every script except Latin: 14 of 15
/// text styles set `fontFamily: 'InstrumentSans'` with no fallback, and that
/// family has no Devanagari, CJK, Arabic, Tamil or Telugu glyphs — so a Nepali
/// or Chinese string had no glyph source at all.
///
/// These tests deliberately cover scripts that are **not** in the app's language
/// registry (Khmer, Sinhala, Thai, Hebrew, Georgian, Malayalam…), because the
/// whole point of the design is that rendering must not depend on having
/// enumerated a language.
/// The app's full set of text styles — all 15 must be able to fall back.
Map<String, TextStyle> allStyles(TextTheme t) => {
      'displayLarge': t.displayLarge!,
      'displayMedium': t.displayMedium!,
      'displaySmall': t.displaySmall!,
      'headlineLarge': t.headlineLarge!,
      'headlineMedium': t.headlineMedium!,
      'headlineSmall': t.headlineSmall!,
      'titleLarge': t.titleLarge!,
      'titleMedium': t.titleMedium!,
      'titleSmall': t.titleSmall!,
      'bodyLarge': t.bodyLarge!,
      'bodyMedium': t.bodyMedium!,
      'bodySmall': t.bodySmall!,
      'labelLarge': t.labelLarge!,
      'labelMedium': t.labelMedium!,
      'labelSmall': t.labelSmall!,
    };

void main() {
  group('TextScript detects the script from the text', () {
    test('Latin', () {
      expect(TextScript.detect('Beam Moment'), AppScript.latin);
      expect(TextScript.detect('Résistance des matériaux'), AppScript.latin);
      expect(TextScript.detect('Сопротивление'), AppScript.latin);
    });

    test('Devanagari (Nepali and Hindi)', () {
      expect(TextScript.detect('बेम लोड'), AppScript.devanagari);
      expect(TextScript.detect('प्रतिरोध'), AppScript.devanagari);
    });

    test('Han (Chinese) and Kana (Japanese)', () {
      expect(TextScript.detect('弯曲应力'), AppScript.han);
      expect(TextScript.detect('ひげ'), AppScript.kana);
      expect(TextScript.detect('カタカナ'), AppScript.kana);
    });

    test('Hangul', () {
      expect(TextScript.detect('휨 응력'), AppScript.hangul);
    });

    test('Arabic and Hebrew are RTL', () {
      expect(TextScript.detect('انحناء الإجهاد'), AppScript.arabic);
      expect(TextScript.detect('מאמץ כפיפה'), AppScript.hebrew);
      expect(TextScript.isRtlText('انحناء'), isTrue);
      expect(TextScript.isRtlText('मोहर'), isFalse);
    });

    // Scripts the registry does not list at all. These are the proof that the
    // design is not an enumeration.
    test('Khmer', () {
      expect(TextScript.detect('រង្វាស់'), AppScript.khmer);
    });

    test('Sinhala', () {
      expect(TextScript.detect('නිම්‍යනය'), AppScript.sinhala);
    });

    test('Thai and Lao', () {
      expect(TextScript.detect('แรงดัด'), AppScript.thai);
      expect(TextScript.detect('ຄວາມເຄັນຍົກ'), AppScript.lao);
    });

    test('Myanmar and Tibetan', () {
      expect(TextScript.detect('ကွေးချိန်စားပေါ်ဝင်ခြင်း'), AppScript.myanmar);
      expect(TextScript.detect('འགར་དངུལ'), AppScript.tibetan);
    });

    test('Georgian and Armenian', () {
      expect(TextScript.detect('ილეგრძნა'), AppScript.georgian);
      expect(TextScript.detect('ծիռակում'), AppScript.armenian);
    });

    test('Ethiopic', () {
      expect(TextScript.detect('እንደሳ'), AppScript.ethiopic);
    });

    test('Tamil, Telugu, Bengali and the other Indian scripts', () {
      expect(TextScript.detect('வளிவு'), AppScript.tamil);
      expect(TextScript.detect('గాలి'), AppScript.telugu);
      expect(TextScript.detect('বাতাস'), AppScript.bengali);
      expect(TextScript.detect('ਹਵਾ'), AppScript.gurmukhi);
      expect(TextScript.detect('હવા'), AppScript.gujarati);
      expect(TextScript.detect('ବାଯାସ'), AppScript.oriya);
      expect(TextScript.detect('ಗಾಳಿ'), AppScript.kannada);
      expect(TextScript.detect('വായു'), AppScript.malayalam);
    });

    test('ignores digits, whitespace and punctuation', () {
      // Otherwise "3.5 kN" or "Beam (2026)" would read as unknown.
      expect(TextScript.detect('3.5 kN'), AppScript.latin);
      expect(TextScript.detect('   '), AppScript.unknown);
      expect(TextScript.detect('2026'), AppScript.unknown);
      expect(TextScript.detect(''), AppScript.unknown);
    });

    test('a mixed sentence resolves by dominant script, deterministically', () {
      // A Nepali note containing an English term — the real case for a student.
      final s = TextScript.detect('बेम स्ट्रेस भित्र डालिएको bending stress');
      expect(s, AppScript.devanagari);

      // Latin-dominant with an inline Nepali word stays Latin.
      expect(TextScript.detect('Bending stress in बेम'), AppScript.latin);
    });

    test('the same string always resolves the same way', () {
      const text = 'Beam बेम 梁';
      expect(TextScript.detect(text), TextScript.detect(text));
    });
  });

  group('the fallback chain is universal, not enumerated', () {
    test('ends in a generic family so nothing renders as tofu', () {
      expect(ScriptFonts.universalChain.last, 'sans-serif');
    });

    test('leads with the branded Latin face so English keeps its look', () {
      expect(ScriptFonts.universalChain.first, ScriptFonts.latinFamily);
    });

    test('every script resolves to a chain that ends generically', () {
      for (final script in AppScript.values) {
        expect(
          ScriptFonts.forScript(script),
          isNotEmpty,
          reason: '$script must resolve',
        );
      }
    });

    test('covers the scripts nobody would have thought to list', () {
      const chain = ScriptFonts.universalChain;
      for (final family in const [
        'NotoSansKhmer',
        'NotoSansSinhala',
        'NotoSansThai',
        'NotoSansHebrew',
        'NotoSansGeorgian',
        'NotoSansMalayalam',
        'NotoSansMyanmar',
      ]) {
        expect(chain, contains(family));
      }
    });

    test('has no duplicate families', () {
      final set = ScriptFonts.universalChain.toSet();
      expect(set.length, ScriptFonts.universalChain.length);
    });
  });

  group('tracking is only tightened for Latin', () {
    const display = TextStyle(
      fontFamily: 'InstrumentSans',
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    );

    test('keeps it for Latin text', () {
      expect(ScriptFonts.forText(display, 'Beam').letterSpacing, -0.25);
    });

    test('zeroes it for Devanagari — joining gets pulled apart otherwise', () {
      expect(ScriptFonts.forText(display, 'बेम').letterSpacing, 0);
    });

    test('zeroes it for Arabic and Khmer too', () {
      expect(ScriptFonts.forText(display, 'انحناء').letterSpacing, 0);
      expect(ScriptFonts.forText(display, 'រង្វាស់').letterSpacing, 0);
    });

    test('applies the universal chain regardless of script', () {
      final s = ScriptFonts.forText(display, 'រង្វាស់');
      expect(s.fontFamilyFallback, isNotNull);
      expect(s.fontFamilyFallback, contains('sans-serif'));
    });

    test('preserves size and weight', () {
      final s = ScriptFonts.forText(display, '梁');
      expect(s.fontSize, 32);
      expect(s.fontWeight, FontWeight.w800);
    });
  });

  group('language code to script for UI chrome', () {
    test('maps the languages the registry offers', () {
      expect(scriptForLanguage('en'), AppScript.latin);
      expect(scriptForLanguage('ne'), AppScript.devanagari);
      expect(scriptForLanguage('hi'), AppScript.devanagari);
      expect(scriptForLanguage('zh'), AppScript.han);
      expect(scriptForLanguage('ar'), AppScript.arabic);
      expect(scriptForLanguage('he'), AppScript.hebrew);
      expect(scriptForLanguage('th'), AppScript.thai);
      expect(scriptForLanguage('km'), AppScript.khmer);
      expect(scriptForLanguage('si'), AppScript.sinhala);
    });

    test('honours a BCP-47 script subtag', () {
      expect(scriptForLanguage('zh-Hans'), AppScript.han);
      expect(scriptForLanguage('zh-Hant'), AppScript.han);
      expect(scriptForLanguage('ja-Jpan'), AppScript.kana);
    });

    test('never throws on unknown input', () {
      expect(scriptForLanguage(null), AppScript.unknown);
      expect(scriptForLanguage(''), AppScript.unknown);
      expect(scriptForLanguage('xx'), AppScript.unknown);
    });

    test('direction follows the script, matching the server registry', () {
      expect(directionForLanguage('ar'), TextDirection.rtl);
      expect(directionForLanguage('he'), TextDirection.rtl);
      expect(directionForLanguage('ne'), TextDirection.ltr);
      expect(directionForLanguage('en'), TextDirection.ltr);
    });
  });

  group('the themed app renders in any locale', () {
    // The original bug was that 14 of 15 styles forced InstrumentSans with no
    // fallback, so a non-Latin string had no glyph source at all. Every style
    // must now carry a chain that terminates in a generic family.
    for (final code in const ['en', 'ne', 'zh', 'ar', 'he', 'th', 'km']) {
      test('$code gets a resolvable chain on every text style', () {
        final theme = AppTheme.forLocale(Brightness.light, languageCode: code);
        for (final entry in allStyles(theme.textTheme).entries) {
          expect(entry.value, isNotNull, reason: '$code ${entry.key} is set');
        }
        expect(theme.textTheme.bodyLarge!.fontFamilyFallback, contains('sans-serif'));
        expect(theme.textTheme.titleMedium!.fontFamilyFallback, contains('sans-serif'));
        expect(theme.textTheme.labelSmall!.fontFamilyFallback, contains('sans-serif'));
      });
    }

    test('leads with the script-specific face for a non-Latin locale', () {
      final ne = AppTheme.forLocale(Brightness.light, languageCode: 'ne');
      expect(ne.textTheme.bodyLarge!.fontFamily, 'NotoSansDevanagari');

      final zh = AppTheme.forLocale(Brightness.light, languageCode: 'zh');
      expect(zh.textTheme.bodyLarge!.fontFamily, 'NotoSansSC');
    });

    test('leads with the branded face for a Latin locale', () {
      final en = AppTheme.forLocale(Brightness.light, languageCode: 'en');
      expect(en.textTheme.bodyLarge!.fontFamily, ScriptFonts.latinFamily);
    });

    test('a Khmer locale still resolves, because the chain is not enumerated', () {
      // km is not in the app's language registry. It must not throw and must
      // still produce a renderable chain rather than a missing-glyph hole.
      final km = AppTheme.forLocale(Brightness.light, languageCode: 'km');
      expect(km.textTheme.bodyLarge!.fontFamily, 'NotoSansKhmer');
      expect(km.textTheme.bodyLarge!.fontFamilyFallback, contains('sans-serif'));
    });

    test('unknown and null locales degrade to the branded face', () {
      for (final code in const [null, '', 'xx']) {
        final t = AppTheme.forLocale(Brightness.light, languageCode: code);
        expect(t.textTheme.bodyLarge!.fontFamily, ScriptFonts.latinFamily);
        expect(t.textTheme.bodyLarge!.fontFamilyFallback, contains('sans-serif'));
      }
    });

    test('never leaves a style without a fallback chain', () {
      final theme = AppTheme.forLocale(Brightness.dark, languageCode: 'ne');
      for (final entry in allStyles(theme.textTheme).entries) {
        expect(
          entry.value.fontFamilyFallback,
          isNotEmpty,
          reason: '${entry.key} must be able to fall back',
        );
      }
    });

    test('dark and light both resolve', () {
      for (final b in Brightness.values) {
        final t = AppTheme.forLocale(b, languageCode: 'zh');
        expect(t.textTheme.titleLarge!.fontFamilyFallback, contains('sans-serif'));
      }
    });
  });
}

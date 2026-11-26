import 'dart:convert';
import 'dart:io';

import 'package:bisaasmobile/l10n/app_localizations_en.dart';
import 'package:bisaasmobile/l10n/app_localizations_hi.dart';
import 'package:bisaasmobile/l10n/app_localizations_ne.dart';
import 'package:flutter_test/flutter_test.dart';

/// The last ten hardcoded strings that reached Nepali/Hindi readers sat in
/// positional helper arguments and in pure-domain defaults — places the
/// coverage scanner cannot see. This pins the translated getters themselves,
/// so a future edit cannot quietly put the English back.
void main() {
  final en = AppLocalizationsEn();
  final ne = AppLocalizationsNe();
  final hi = AppLocalizationsHi();

  group('streak self-service copy follows the locale', () {
    test('Nepali', () {
      expect(ne.streakRepairedSuccess, 'स्ट्रिक मर्मत भयो!');
      expect(ne.streakInsuranceBought, 'बीमा किनियो!');
      expect(ne.streakInsuranceUsed, 'बीमा प्रयोग भयो — स्ट्रिक पुनर्स्थापित!');
      expect(ne.streakWagerStarted, 'दाउ सुरु भयो — शुभकामना!');
      expect(
        ne.streakInsuranceBankedCount(2, 3),
        '3 मध्ये 2 बीमा टोकन जम्मा गरियो',
      );
    });

    test('Hindi', () {
      expect(hi.streakRepairedSuccess, 'स्ट्रीक ठीक हो गया!');
      expect(hi.streakInsuranceBought, 'बीमा खरीदा गया!');
      expect(hi.streakInsuranceUsed, 'बीमा इस्तेमाल हुआ — स्ट्रीक बहाल!');
      expect(hi.streakWagerStarted, 'शर्त शुरू — शुभकामनाएँ!');
      expect(
        hi.streakInsuranceBankedCount(1, 3),
        '3 में से 1 बीमा टोकन जमा किए गए',
      );
    });

    test('the banked count no longer takes an English plural suffix', () {
      // Both locales now translate the whole message; there is no `plural`
      // argument for a screen to inject `s` into.
      expect(en.streakInsuranceBankedCount(1, 3), 'Banked 1 of 3 insurance tokens');
      expect(ne.streakInsuranceBankedCount(1, 3), '3 मध्ये 1 बीमा टोकन जम्मा गरियो');
      expect(hi.streakInsuranceBankedCount(1, 3), '3 में से 1 बीमा टोकन जमा किए गए');
    });
  });

  group('battle result and player labels follow the locale', () {
    test('Nepali', () {
      expect(ne.battleResultWin, 'तपाईं जित्नुभयो!');
      expect(ne.battleResultLoss, 'राम्रो खेल!');
      expect(ne.battleResultDraw, 'बराबरी');
      expect(ne.battleResultPending, 'नतिजा पर्खाइमा');
      expect(ne.battleOpponent, 'प्रतिद्वन्द्वी');
      expect(ne.battleYou, 'तपाईं');
    });

    test('Hindi', () {
      expect(hi.battleResultWin, 'आप जीत गए!');
      expect(hi.battleResultLoss, 'शानदार खेल!');
      expect(hi.battleResultDraw, 'बराबरी');
      expect(hi.battleResultPending, 'परिणाम लंबित');
      expect(hi.battleOpponent, 'प्रतिदंद्वी');
      expect(hi.battleYou, 'आप');
    });
  });

  test('every locale declares the same placeholders for the new keys', () {
    const keys = <String>{
      'streakRepairedSuccess',
      'streakInsuranceBought',
      'streakInsuranceUsed',
      'streakWagerStarted',
      'streakInsuranceBankedCount',
      'battleResultWin',
      'battleResultLoss',
      'battleResultDraw',
      'battleResultPending',
      'battleOpponent',
    };
    for (final locale in ['en', 'ne', 'hi']) {
      final file = File('lib/l10n/app_$locale.arb');
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in keys) {
        expect(arb[key], isA<String>(), reason: '$key missing in $locale');
        final meta = arb['@$key'] as Map<String, dynamic>?;
        final declared = meta?['placeholders'] as Map<String, dynamic>?;
        if (key == 'streakInsuranceBankedCount') {
          expect(declared?.keys.toSet(), {'count', 'max'});
        } else {
          expect(declared, isNull, reason: '$key must have no placeholders');
        }
      }
    }
  });
}

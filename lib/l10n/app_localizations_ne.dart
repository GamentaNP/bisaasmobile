// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'साइन इन';

  @override
  String get register => 'दर्ता गर्नुहोस्';

  @override
  String get quiz => 'क्विज';

  @override
  String get practice => 'अभ्यास';

  @override
  String get calculators => 'क्याल्कुलेटर';

  @override
  String get courses => 'पाठ्यक्रमहरू';

  @override
  String get continueAsGuest => 'अतिथिको रूपमा जारी राख्नुहोस्';

  @override
  String get backend => 'ब्याकेन्ड';

  @override
  String get env => 'वातावरण';

  @override
  String get home => 'गृह';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिङ';

  @override
  String get offline => 'अफलाइन';

  @override
  String get retry => 'पुन: प्रयास गर्नुहोस्';

  @override
  String get error => 'केही गलत भयो';

  @override
  String streakDays(int days) {
    return 'लगातार: $days दिन';
  }

  @override
  String coinsBalance(int count) {
    return '$count सिक्काहरू';
  }

  @override
  String get appLocked => 'CivilCal लक भएको छ';

  @override
  String get unlock => 'अनलक गर्नुहोस्';

  @override
  String get unlockCivilCal => 'CivilCal अनलक गर्नुहोस्';
}

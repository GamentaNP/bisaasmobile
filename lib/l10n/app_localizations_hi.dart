// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get register => 'रजिस्टर करें';

  @override
  String get quiz => 'क्विज़';

  @override
  String get practice => 'अभ्यास';

  @override
  String get calculators => 'कैलकुलेटर';

  @override
  String get courses => 'पाठ्यक्रम';

  @override
  String get continueAsGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get backend => 'बैकएंड';

  @override
  String get env => 'पर्यावरण';

  @override
  String get home => 'होम';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get error => 'कुछ गलत हो गया';

  @override
  String streakDays(int days) {
    return 'लगातार: $days दिन';
  }

  @override
  String coinsBalance(int count) {
    return '$count सिक्के';
  }

  @override
  String get appLocked => 'CivilCal लॉक है';

  @override
  String get unlock => 'अनलॉक करें';

  @override
  String get unlockCivilCal => 'CivilCal अनलॉक करें';
}

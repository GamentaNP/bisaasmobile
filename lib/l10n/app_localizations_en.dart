// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'Sign in';

  @override
  String get register => 'Register';

  @override
  String get quiz => 'Quiz';

  @override
  String get practice => 'Practice';

  @override
  String get calculators => 'Calculators';

  @override
  String get courses => 'Courses';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get backend => 'Backend';

  @override
  String get env => 'Env';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get offline => 'Offline';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Something went wrong';

  @override
  String streakDays(int days) {
    return 'Streak: $days days';
  }

  @override
  String coinsBalance(int count) {
    return '$count coins';
  }

  @override
  String get appLocked => 'CivilCal is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockCivilCal => 'Unlock CivilCal';
}

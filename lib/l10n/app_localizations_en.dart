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
  String get quiz => 'Quiz';

  @override
  String get continueAsGuest => 'Continue as guest ? Quiz';

  @override
  String get backend => 'Backend';

  @override
  String get env => 'Env';
}

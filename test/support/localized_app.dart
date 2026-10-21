import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wraps [child] in a `MaterialApp` that carries the app's localisation
/// delegates.
///
/// A widget that calls `AppLocalizations.of(context)` gets `null` in a bare
/// `MaterialApp`, because the generated delegates are not registered. The
/// app registers them in `lib/app/app.dart`; a test that pumps the same
/// widget has to do the same, or it tests a tree the user never sees.
Widget localizedApp({
  required Widget child,
  Locale? locale,
  ThemeData? theme,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLanguages.supportedLocales,
    locale: locale,
    theme: theme,
    home: child,
  );
}

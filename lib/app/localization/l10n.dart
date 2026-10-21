import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../../core/storage/preferences.dart';
import '../../l10n/app_localizations.dart';

/// The localisations for the active app locale, without a `BuildContext`.
///
/// Widgets use `AppLocalizations.of(context)`. Services, controllers and data
/// sources have no context, but they still produce text a user reads — a
/// notification title, an error message on a screen. Those call this
/// instead.
///
/// The locale is the one the user chose, falling back to the device locale
/// when they have not chosen one — the same rule the widget tree follows,
/// because the locale controller writes the choice to the preferences store
/// and the device locale is what Material falls back to.
AppLocalizations appL10n() {
  // A copy lookup must never be able to fail. The preferences store is
  // initialised by the bootstrap, but a service can be reached before it —
  // or in a test that never calls it — and a `StateError` from here would
  // take down whatever the caller was doing.
  String? saved;
  try {
    saved = Preferences.instance.locale;
  } catch (_) {
    saved = null;
  }

  final code = saved ?? PlatformDispatcher.instance.locale.languageCode;
  if (!AppLocalizations.supportedLocales
      .any((locale) => locale.languageCode == code)) {
    return lookupAppLocalizations(const Locale('en'));
  }
  return lookupAppLocalizations(Locale(code));
}

/// Appearance mode — settings-driven and persisted, mirroring the server's
/// `users.appearance` field (`light` / `dark` / `system`).
///
/// The theme is a local decision first: preferences are initialized in
/// bootstrap before `runApp`, so the first frame already has the right mode.
/// The server is consulted opportunistically on sign-in, and only a *valid*
/// server value may overwrite a local choice — a null/unknown field means the
/// server has no opinion, not "forget what the user picked here".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';

class AppearanceController extends Notifier<ThemeMode> {
  static const light = 'light';
  static const dark = 'dark';
  static const system = 'system';

  @override
  ThemeMode build() => decode(Preferences.instance.appearance);

  /// Wire value → theme mode. Anything unrecognized (including null) is a
  /// system-following choice; an old build can never pin a user to a mode by
  /// writing a value this build does not know.
  static ThemeMode decode(String? value) => switch (value) {
        light => ThemeMode.light,
        dark => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Theme mode → wire value. Shared with the settings screen so the PATCH
  /// body can never drift from what was persisted locally.
  static String encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => light,
        ThemeMode.dark => dark,
        ThemeMode.system => system,
      };

  /// Applies and persists a user choice.
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await Preferences.instance.setAppearance(encode(mode));
  }

  /// Applies the server's choice on sign-in, when the server actually has one.
  /// A null or unknown field is ignored so a server that has never heard of
  /// this preference cannot undo an explicit local selection.
  Future<void> adoptFromServer(String? value) async {
    if (value != light && value != dark && value != system) return;
    await set(decode(value));
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, ThemeMode>(AppearanceController.new);

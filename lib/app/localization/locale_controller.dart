/// Locale selection — settings-driven, persisted, and mirrored onto the
/// network layer as `Accept-Language` per AGENTS.md contract.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/preferences.dart';

/// Active locale; null means follow the system (Material falls back through
/// supported locales).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final saved = Preferences.instance.locale;
    return saved != null ? Locale(saved) : null;
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final code = locale?.languageCode ?? 'en';
    await Preferences.instance.setLocale(code);
    if (DioClient.isInitialized) DioClient.instance.setLocale(code);
    AppLogger.i('Locale → $code');
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

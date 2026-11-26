import 'package:bisaasmobile/app/theme/appearance_controller.dart';
import 'package:bisaasmobile/core/storage/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appearance is a local-first choice: the first frame reads it from
/// Preferences (initialized in bootstrap), and the server is only allowed to
/// adopt it when it actually publishes a value it understands.
void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUpAll(() async {
    // Preferences caches its instance for the whole isolate, so the in-memory
    // store is installed exactly once and every test seeds the same object the
    // controller reads from.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    await Preferences.init();
  });

  Future<void> seed(String? value) async {
    if (value == null) {
      await prefs.remove('appearance');
    } else {
      await prefs.setString('appearance', value);
    }
  }

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('stored wire values map to the right ThemeMode', () async {
    // A provider reads prefs once in build(), so each wire value needs a
    // fresh container — just like a cold start reads what was persisted.
    for (final entry in <MapEntry<String?, ThemeMode>>[
      MapEntry(null, ThemeMode.system),
      const MapEntry('light', ThemeMode.light),
      const MapEntry('dark', ThemeMode.dark),
      const MapEntry('system', ThemeMode.system),
    ]) {
      await seed(entry.key);
      container.dispose();
      container = ProviderContainer();
      expect(container.read(appearanceProvider), entry.value);
    }
  });

  test('an unknown stored value falls back to system', () async {
    await seed('high-contrast');
    expect(container.read(appearanceProvider), ThemeMode.system);
  });

  test('set notifies and persists the wire value', () async {
    await seed(null);
    await container.read(appearanceProvider.notifier).set(ThemeMode.dark);

    expect(container.read(appearanceProvider), ThemeMode.dark);
    expect(Preferences.instance.appearance, 'dark');
  });

  test('adoptFromServer applies a valid server value and persists it', () async {
    await seed(null);
    await container
        .read(appearanceProvider.notifier)
        .adoptFromServer('light');

    expect(container.read(appearanceProvider), ThemeMode.light);
    expect(Preferences.instance.appearance, 'light');
  });

  test('a null or unknown server value never clears a local choice', () async {
    await seed('dark');
    // Rebuild the provider so it starts from the seeded value.
    container.dispose();
    container = ProviderContainer();

    await container.read(appearanceProvider.notifier).adoptFromServer(null);
    expect(container.read(appearanceProvider), ThemeMode.dark);
    expect(Preferences.instance.appearance, 'dark');

    await container
        .read(appearanceProvider.notifier)
        .adoptFromServer('midnight');
    expect(container.read(appearanceProvider), ThemeMode.dark);
    expect(Preferences.instance.appearance, 'dark');
  });

  test('encode and decode round-trip every mode', () {
    for (final mode in ThemeMode.values) {
      expect(
        AppearanceController.decode(AppearanceController.encode(mode)),
        mode,
      );
    }
  });
}

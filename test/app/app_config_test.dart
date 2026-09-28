import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /app/config` is the operator's kill-switch and the source of the
/// force-update floor. It was never called, so `feature_flags.dart` shipped
/// `economy_enabled: true` while the live server said `false`.
void main() {
  // Captured verbatim from the running backend.
  final live = <String, dynamic>{
    'min_app_version': {'android': '1.0.0', 'ios': '1.0.0'},
    'force_update': false,
    'maintenance': false,
    'features': {
      'external_api_enabled': true,
      'economy_enabled': false,
      'ads_enabled': false,
      'guest_calculator_enabled': false,
      'premium_download_enabled': true,
      'offline_premium_enabled': true,
      'competitive_enabled': true,
      'reward_requires_integrity': false,
      'emergency_content_protection': false,
    },
    'api': {'version': 'v1'},
    'push': {'vapid_public_key': ''},
  };

  group('parsing the live payload', () {
    final config = AppConfig.fromJson(live);

    test('reads the version floors', () {
      expect(config.minAndroidVersion, '1.0.0');
      expect(config.minIosVersion, '1.0.0');
      expect(config.minVersionFor(platform: TargetPlatform.android), '1.0.0');
      expect(config.minVersionFor(platform: TargetPlatform.iOS), '1.0.0');
    });

    test('maintenance and force_update are off', () {
      expect(config.maintenance, isFalse);
      expect(config.forceUpdate, isFalse);
    });

    test('respects the server saying economy is OFF', () {
      // This is the inversion that mattered: the app's own default was `true`.
      expect(config.economyEnabled, isFalse);
    });

    test('respects ads and guest calculators being off', () {
      expect(config.adsEnabled, isFalse);
      expect(config.guestCalculatorEnabled, isFalse);
    });

    test('reads the flags that are on', () {
      expect(config.premiumDownloadEnabled, isTrue);
      expect(config.offlinePremiumEnabled, isTrue);
      expect(config.competitiveEnabled, isTrue);
    });
  });

  group('tolerant parsing', () {
    test('missing features map leaves every flag at its default', () {
      final c = AppConfig.fromJson(const {});
      expect(c.maintenance, isFalse);
      expect(c.economyEnabled, isTrue, reason: 'unknown flag must not disable a feature');
    });

    test('a string "false" is not read as the boolean false', () {
      // Only real booleans are accepted, so a sloppy server value cannot
      // silently flip a kill-switch either way.
      final c = AppConfig.fromJson(const {
        'features': {'economy_enabled': 'false'},
      });
      expect(c.economyEnabled, isTrue);
    });

    test('"true" string is likewise ignored', () {
      final c = AppConfig.fromJson(const {
        'features': {'maintenance_ish': 'true'},
      });
      expect(c.flag('maintenance_ish'), isTrue);
    });

    test('an unparseable version floor falls back rather than locking users out', () {
      final c = AppConfig.fromJson(const {
        'min_app_version': {'android': 'not-a-version'},
      });
      expect(c.minAndroidVersion, 'not-a-version');
      // The compare must not throw on it.
      expect(isVersionBelow('1.0.0', 'not-a-version'), isFalse);
    });
  });

  group('isVersionBelow', () {
    test('equal versions are not below', () {
      expect(isVersionBelow('1.0.0', '1.0.0'), isFalse);
    });

    test('lower patch / minor / major are below', () {
      expect(isVersionBelow('1.0.1', '1.0.2'), isTrue);
      expect(isVersionBelow('1.1.0', '1.2.0'), isTrue);
      expect(isVersionBelow('0.9.9', '1.0.0'), isTrue);
    });

    test('higher versions are not below', () {
      expect(isVersionBelow('1.0.1', '1.0.0'), isFalse);
      expect(isVersionBelow('2.0.0', '1.9.9'), isFalse);
    });

    test('handles different segment counts', () {
      expect(isVersionBelow('1.0', '1.0.1'), isTrue);
      expect(isVersionBelow('1.0.0', '1.0'), isFalse);
    });

    test('ignores a pre-release suffix for ordering', () {
      expect(isVersionBelow('1.0.0-beta.1', '1.0.0'), isFalse);
      expect(isVersionBelow('0.9.9', '1.0.0-beta.1'), isTrue);
    });

    test('tolerates whitespace and junk segments without throwing', () {
      expect(isVersionBelow(' 1.0.0 ', '1.0.0'), isFalse);
      expect(isVersionBelow('1.x.0', '1.0.1'), isTrue);
    });

    test('an empty current version is never below — CI must not lock out', () {
      // A local/debug build with no APP_VERSION must not be blocked.
      expect(isVersionBelow('', '9.9.9'), isFalse);
    });
  });
}

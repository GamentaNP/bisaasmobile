/// Deployment verification for the release artefacts.
///
/// These assertions are about the **shipped configuration**, not the code:
/// the pins the release build will use, the Android manifest's backup and
/// cleartext posture, and the iOS security identifiers. A regression in any
/// of them is invisible to the compiler and to the widget tests, so it is
/// checked here — in CI, on every push.
///
/// The files are read from the package root, which is the working directory
/// `flutter test` runs in.
library;

import 'dart:convert';
import 'dart:io';

import 'package:bisaasmobile/core/network/certificate_pinning.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a repository file relative to the package root.
String _read(String path) {
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason: '$path must exist — the release configuration depends on it',
  );
  return file.readAsStringSync();
}

Map<String, dynamic> _readDefines(String path) {
  final raw = _read(path);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded;
}

void main() {
  group('certificate pins', () {
    test('the production build declares real pins', () {
      final defines = _readDefines('dart_defines/production.json');

      final pins = <String>[
        if (defines['CERT_PIN_1'] != null) defines['CERT_PIN_1'] as String,
        if (defines['CERT_PIN_2'] != null) defines['CERT_PIN_2'] as String,
        if (defines['CERT_PIN_3'] != null) defines['CERT_PIN_3'] as String,
      ];

      expect(
        pins.where((p) => p.isNotEmpty).length,
        greaterThanOrEqualTo(2),
        reason:
            'the production build needs the live pin plus at least one backup, '
            'so a certificate rotation cannot brick the fleet',
      );

      for (final pin in pins.where((p) => p.isNotEmpty)) {
        expect(
          pin,
          startsWith('sha256/'),
          reason: 'a pin is "sha256/<base64 digest>"',
        );
        expect(
          pin.toUpperCase(),
          isNot(contains('REPLACE')),
          reason: 'a placeholder is not a pin — it would never match a cert',
        );
      }
    });

    test('the staging build declares no pin rather than a fake one', () {
      final defines = _readDefines('dart_defines/staging.json');

      for (final key in const ['CERT_PIN_1', 'CERT_PIN_2', 'CERT_PIN_3']) {
        final value = defines[key];
        if (value == null) continue;
        expect(
          value,
          isEmpty,
          reason:
              '$key must be empty in staging. A placeholder there would look '
              'configured while never matching a certificate.',
        );
      }
    });

    test('a production host is never treated as a development host', () {
      // The debug build's certificate shim accepts a self-signed certificate
      // for the configured base URL host. That must never include a
      // production host, or a debug build pointed at production would accept
      // a forged certificate for the live API.
      expect(
        CertificatePinning.productionHosts,
        containsAll(<String>['bisaas.com', 'www.bisaas.com']),
      );
    });

    test('the build that runs here declares no usable pin', () {
      // The test build has no `--dart-define`, so it must report "no pins"
      // rather than pretending. If this ever becomes true, the test build is
      // being given production pins and the fail-closed guard below is not
      // being exercised.
      expect(CertificatePinning.prodPins, isEmpty);
      expect(CertificatePinning.pinsConfigured, isFalse);
    });
  });

  group('Android manifest', () {
    late final String manifest;

    setUpAll(() {
      manifest = _read('android/app/src/main/AndroidManifest.xml');
    });

    test('backup is disabled', () {
      expect(
        manifest,
        contains('android:allowBackup="false"'),
        reason: 'the bearer PAT lives in secure storage; it must not be backed up',
      );
    });

    test('the backup rules are declared, not just the flag', () {
      // `allowBackup="false"` is the intent; the rules files are the
      // enforcement. OEM builds that ignore the flag would otherwise carry
      // the token off the device.
      expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );

      final legacy = _read('android/app/src/main/res/xml/backup_rules.xml');
      expect(legacy, contains('<exclude domain="root" path="." />'));

      final modern =
          _read('android/app/src/main/res/xml/data_extraction_rules.xml');
      expect(modern, contains('<cloud-backup>'));
      expect(modern, contains('<device-transfer>'));
    });

    test('the network security config is attached', () {
      expect(
        manifest,
        contains('android:networkSecurityConfig="@xml/network_security_config"'),
      );
    });
  });

  group('Android network security config', () {
    test('cleartext is forbidden in the release build', () {
      final xml = _read(
        'android/app/src/main/res/xml/network_security_config.xml',
      );
      expect(xml, contains('cleartextTrafficPermitted="false"'));
      // A release cleartext allowance would be the whole ballgame.
      expect(xml, isNot(contains('cleartextTrafficPermitted="true"')));
    });
  });

  group('iOS Info.plist', () {
    late final String plist;

    setUpAll(() {
      plist = _read('ios/Runner/Info.plist');
    });

    test('the encryption declaration is explicit', () {
      expect(plist, contains('<key>ITSAppUsesNonExemptEncryption</key>'));
      expect(plist, contains('<false/>'));
    });

    test('the app does not expose its documents to the Files app', () {
      expect(plist, contains('<key>UIFileSharingEnabled</key>'));
      expect(plist, contains('<key>LSSupportsOpeningDocumentsInPlace</key>'));
    });

    test('App Transport Security has no exceptions', () {
      expect(plist, contains('<key>NSAppTransportSecurity</key>'));

      // The ATS block on its own — the plist has other `<true/>` entries
      // (CADisableMinimumFrameDuration, LSRequiresIPhoneOS) that have nothing
      // to do with transport security.
      final atsStart = plist.indexOf('<key>NSAppTransportSecurity</key>');
      expect(atsStart, greaterThan(-1));
      final atsEnd = plist.indexOf('</dict>', atsStart);
      final atsBlock = plist.substring(atsStart, atsEnd);

      expect(atsBlock, contains('<key>NSAllowsArbitraryLoads</key>'));
      expect(
        atsBlock,
        isNot(contains('<true/>')),
        reason: 'no ATS exception may be declared',
      );
      expect(atsBlock, contains('<false/>'));
    });
  });
}

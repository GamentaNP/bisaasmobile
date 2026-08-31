/// Certificate pinning for prod/staging.
///
/// Compares SHA-256 of the leaf certificate DER against configured pins.
/// Pins are injected at compile time via `--dart-define` so they never appear
/// in committed code:
///
///   flutter build appbundle \
///     --dart-define=CERT_PIN_1=sha256/AAAA... \
///     --dart-define=CERT_PIN_2=sha256/BBBB...  # (backup pin � rotate safely)
///
/// Compute a pin:
///   openssl s_client -connect bisaas.com:443 </dev/null \
///     | openssl x509 -outform DER \
///     | openssl dgst -sha256 -binary \
///     | openssl base64
/// Then prefix with `sha256/`.
///
/// Fail-safe by construction:
/// - When pins are configured, any certificate that does not match is rejected
///   (fail-closed).
/// - When pins are empty (dev / no dart-define), standard chain validation
///   applies � no pinning bypass, just no extra pinning.
/// - Laragon dev (`bisaas.test` / `10.0.2.2`) always bypasses pinning and
///   uses the permissive `badCertificateCallback` set in DioClient.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';

abstract final class CertificatePinning {
  // ---------------------------------------------------------------------------
  // Compile-time injection � populate via --dart-define in CI/CD.
  // Up to 3 pins supported (primary + 2 backup/rotation slots).
  // ---------------------------------------------------------------------------
  static const _pin1 = String.fromEnvironment('CERT_PIN_1', defaultValue: '');
  static const _pin2 = String.fromEnvironment('CERT_PIN_2', defaultValue: '');
  static const _pin3 = String.fromEnvironment('CERT_PIN_3', defaultValue: '');

  /// Resolved list of non-empty pins for the current build.
  static List<String> get prodPins => [
        if (_pin1.isNotEmpty) _pin1,
        if (_pin2.isNotEmpty) _pin2,
        if (_pin3.isNotEmpty) _pin3,
      ];

  /// Applies pinning to [adapter] for [host].
  ///
  /// - Dev hosts (`bisaas.test`, `10.0.2.2`) ? no-op (DioClient already
  ///   uses `badCertificateCallback` for those).
  /// - No pins configured ? standard chain validation only.
  /// - Pins configured ? fail-closed: reject any cert not in [prodPins].
  static void apply(IOHttpClientAdapter adapter, {required String host}) {
    if (host.contains('bisaas.test') || host.contains('10.0.2.2')) return;
    final pins = prodPins;
    if (pins.isEmpty) return; // no pins ? standard validation only

    adapter.validateCertificate = (cert, h, port) {
      final pin = pinFor(cert);
      // Unknown/uncomputable cert ? reject. Fail closed.
      return pin != null && pins.contains(pin);
    };
  }

  /// Returns `sha256/<base64 digest>` of the leaf certificate DER, or null.
  static String? pinFor(X509Certificate? cert) {
    if (cert == null) return null;
    try {
      return 'sha256/${base64.encode(sha256.convert(cert.der).bytes)}';
    } on Object {
      return null;
    }
  }
}

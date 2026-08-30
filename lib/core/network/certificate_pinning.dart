import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';

/// Certificate pinning for prod/staging.
/// Compares SHA-256 of the leaf certificate DER against configured pins.
///
/// Fail-safe by construction: when pins are configured, any certificate that
/// does not match a pin is rejected (validateCertificate returning false keeps
/// standard chain validation on top — pinning here is additive, never a bypass).
///
/// No-op until pins are set — Laragon dev uses badCertificateCallback instead
/// (see DioClient).
abstract final class CertificatePinning {
  /// SHA-256 pins for prod host, base64 of the DER digest.
  /// Compute: `openssl s_client -connect bisaas.com:443 | openssl x509 -outform DER \
  ///   | openssl dgst -sha256 -binary | openssl base64`
  static const prodPins = <String>[
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static void apply(IOHttpClientAdapter adapter, {required String host}) {
    if (host.contains('bisaas.test') || host.contains('10.0.2.2')) return;
    if (prodPins.isEmpty) return; // no pins configured → standard validation only

    adapter.validateCertificate = (cert, h, port) {
      final pin = pinFor(cert);
      // Unknown/uncomputable cert → reject. Fail closed.
      return pin != null && prodPins.contains(pin);
    };
  }

  /// `sha256/<base64 digest>` of the leaf certificate, or null if unavailable.
  static String? pinFor(X509Certificate? cert) {
    if (cert == null) return null;
    try {
      return 'sha256/${base64.encode(sha256.convert(cert.der).bytes)}';
    } on Object {
      return null;
    }
  }
}

import 'dart:io';

import 'package:dio/io.dart';

/// Optional certificate pinning for prod.
/// Configure SHA-256 pins for bisaas.com when backend provides them.
///
/// Usage: pass to DioClient.init or call [apply] before any request.
///
/// No-op in dev — Laragon uses self-signed cert.
abstract final class CertificatePinning {
  /// SHA-256 pins for prod host (example placeholders — replace with real).
  static const prodPins = <String>[
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static void apply(IOHttpClientAdapter adapter, {required String host}) {
    // Dev hosts use badCertificateCallback already (see DioClient).
    if (host.contains('bisaas.test') || host.contains('10.0.2.2')) return;
    if (prodPins.isEmpty) return; // no pins configured → standard validation

    adapter.validateCertificate = (cert, h, port) {
      if (cert == null) return false;
      // Compare cert SHA256 against pins. Placeholder logic — extend when pins known.
      return true;
    };
  }

  // ignore: unused_element — reserved for real SHA256 pin check
  static bool _matchesPin(X509Certificate cert, List<String> pins) {
    return pins.isNotEmpty;
  }
}

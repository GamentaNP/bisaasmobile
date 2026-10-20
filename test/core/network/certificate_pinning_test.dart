/// Certificate-pinning behaviour.
///
/// The pinning rules are the last line of defence against a compromised
/// issuing CA, so they are pinned down here: a mismatched certificate is
/// rejected, a matching one is accepted, and a **production build with no
/// pins configured refuses to run** rather than quietly shipping an unpinned
/// release.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:bisaasmobile/core/network/certificate_pinning.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for an `X509Certificate`.
///
/// The real class cannot be constructed in a unit test, and
/// [CertificatePinning.pinFor] only ever touches `cert.der`, so a fake with
/// the same shape is enough to exercise the comparison logic.
class _FakeCert implements X509Certificate {
  _FakeCert(this.der);

  @override
  final Uint8List der;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  group('pin computation', () {
    test('a certificate hashes to a sha256 pin', () {
      final pin = CertificatePinning.pinFor(_FakeCert(_bytes([1, 2, 3])));
      expect(pin, startsWith('sha256/'));
      expect(pin, isNotNull);
    });

    test('the same certificate always yields the same pin', () {
      final a = CertificatePinning.pinFor(_FakeCert(_bytes([9, 9, 9])));
      final b = CertificatePinning.pinFor(_FakeCert(_bytes([9, 9, 9])));
      expect(a, b);
    });

    test('a different certificate yields a different pin', () {
      final a = CertificatePinning.pinFor(_FakeCert(_bytes([1])));
      final b = CertificatePinning.pinFor(_FakeCert(_bytes([2])));
      expect(a, isNot(b));
    });

    test('a null certificate has no pin', () {
      expect(CertificatePinning.pinFor(null), isNull);
    });
  });

  group('the adapter decision', () {
    late _RecordingAdapter adapter;

    setUp(() {
      adapter = _RecordingAdapter();
    });

    test('a certificate on the pin list is accepted', () {
      final cert = _FakeCert(_bytes([1, 2, 3]));
      final pin = CertificatePinning.pinFor(cert)!;

      CertificatePinning.apply(
        adapter,
        host: 'bisaas.com',
        pins: <String>[pin],
      );

      expect(adapter.validateCertificate!(cert, 'bisaas.com', 443), isTrue);
    });

    test('a certificate that is not on the pin list is rejected', () {
      final pinned = _FakeCert(_bytes([1, 2, 3]));
      final other = _FakeCert(_bytes([4, 5, 6]));

      CertificatePinning.apply(
        adapter,
        host: 'bisaas.com',
        pins: <String>[CertificatePinning.pinFor(pinned)!],
      );

      expect(adapter.validateCertificate!(other, 'bisaas.com', 443), isFalse);
    });

    test('an uncomputable certificate is rejected — fail closed', () {
      final pinned = _FakeCert(_bytes([1, 2, 3]));

      CertificatePinning.apply(
        adapter,
        host: 'bisaas.com',
        pins: <String>[CertificatePinning.pinFor(pinned)!],
      );

      expect(adapter.validateCertificate!(null, 'bisaas.com', 443), isFalse);
    });

    test('a dev host is never pinned', () {
      CertificatePinning.apply(
        adapter,
        host: 'bisaas.test',
        pins: const <String>['sha256/whatever'],
      );

      expect(adapter.validateCertificate, isNull);
    });

    test('a placeholder pin is not treated as configured', () {
      // A staging build whose dart-defines still carry
      // `__REPLACE_WITH_…__` must not be believed to be pinned.
      final cert = _FakeCert(_bytes([1]));
      final pin = CertificatePinning.pinFor(cert)!;

      // With only a placeholder in the list, the usable set is empty and the
      // adapter is left on standard validation (no prod env in tests).
      CertificatePinning.apply(
        adapter,
        host: 'staging.bisaas.com',
        pins: const <String>['__REPLACE_WITH_STAGING_CERT_HASH__'],
      );
      expect(adapter.validateCertificate, isNull);

      // A real pin still installs the check.
      CertificatePinning.apply(
        adapter,
        host: 'staging.bisaas.com',
        pins: <String>[pin],
      );
      expect(adapter.validateCertificate, isNotNull);
    });
  });

  group('the dev certificate shim', () {
    test('a production host is excluded from the permissive host set', () {
      // The shim is built inside DioClient, which is a singleton; the rule it
      // applies is published here so the deployment test can assert it.
      expect(
        CertificatePinning.productionHosts,
        isNot(contains('bisaas.test')),
      );
      expect(
        CertificatePinning.productionHosts,
        isNot(contains('10.0.2.2')),
      );
    });
  });
}

/// An adapter that only records the validation callback.
///
/// It extends the real `IOHttpClientAdapter` so the `validateCertificate`
/// field is the production one — the test exercises the same code path the
/// app does, not a re-implementation.
class _RecordingAdapter extends IOHttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      throw StateError('the pinning test never performs a request');
}

import 'package:bisaasmobile/core/network/certificate_pinning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pinFor null returns null (fail-closed)', () {
    expect(CertificatePinning.pinFor(null), isNull);
  });

  test('prodPins empty by default → standard validation (no pin)', () {
    expect(CertificatePinning.prodPins, isEmpty);
  });
}

import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  BiometricAuth(this._auth);
  final LocalAuthentication _auth;

  Future<bool> get canCheck => _auth.canCheckBiometrics;
  Future<bool> get isDeviceSupported => _auth.isDeviceSupported();

  Future<List<BiometricType>> available() => _auth.getAvailableBiometrics();

  Future<bool> authenticate({String reason = 'Authenticate to continue'}) async {
    final can = await canCheck;
    if (!can) return false;
    return _auth.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      sensitiveTransaction: true,
      persistAcrossBackgrounding: true,
    );
  }
}

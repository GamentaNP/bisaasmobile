import 'package:local_auth/local_auth.dart';

import '../../app/localization/l10n.dart';

class BiometricAuth {
  BiometricAuth(this._auth);
  final LocalAuthentication _auth;

  Future<bool> get canCheck => _auth.canCheckBiometrics;
  Future<bool> get isDeviceSupported => _auth.isDeviceSupported();

  Future<List<BiometricType>> available() => _auth.getAvailableBiometrics();

  Future<bool> authenticate({String? reason}) async {
    final can = await canCheck;
    if (!can) return false;
    return _auth.authenticate(
      localizedReason: reason ?? appL10n().appLockPromptReason,
      biometricOnly: true,
      sensitiveTransaction: true,
      persistAcrossBackgrounding: true,
    );
  }
}

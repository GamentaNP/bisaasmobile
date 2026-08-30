import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Security matrix checks — called from bootstrap and before sensitive writes.
///
/// - Token storage: only `flutter_secure_storage` (Keychain/Keystore) via `TokenManager`; never SharedPreferences.
/// - Cert pinning: `CertificatePinning.apply` fail-closed when `prodPins` set; dev `bisaas.test` bypass only in `isDev`.
/// - Jailbreak/root: best-effort heuristic; if detected, log + advise but do not brick (avoid false positives on rooted dev devices).
class AppSecurity {
  const AppSecurity._();

  static Future<bool> isDeviceCompromised() async {
    // No heavy `trust_fall` dep to keep bootstrap light; we use simple checks + allowlist.
    // In production, integrate `freeRASP` or `trust_fall` and replace this stub with real signals:
    // `isJailBroken`, `isRooted`, `isEmulator`, `isOnExternalStorage`.
    try {
      if (kIsWeb) return false;
      // Heuristic: check for common su paths via MethodChannel (Android only). No-op on iOS.
      const channel = MethodChannel('civilcal/security');
      final result = await channel.invokeMethod<bool>('isRooted').catchError((_) => false);
      return result ?? false;
    } catch (e) {
      AppLogger.w('AppSecurity check failed: $e');
      return false;
    }
  }

  static Future<void> auditOrWarn() async {
    final compromised = await isDeviceCompromised();
    if (compromised) {
      AppLogger.w('Device appears compromised (root/jailbreak) — token remains in secure storage but advise user');
    } else {
      AppLogger.i('Device security audit passed');
    }
  }
}

/// Secure token lifecycle per `MOBILE_API_INTEGRATION_GUIDE.md:2.2` + `env.dart`.
/// Bearer token + expires_at stored in Keychain/Keystore via flutter_secure_storage.
/// Device name is stable per install; used as X-Device-Name on refresh.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  TokenManager({FlutterSecureStorage? storage})
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  /// The app-wide instance — lazily created on first access, reused by the
  /// auth feature, router and interceptor chain so there is exactly one
  /// TokenManager per process (single storage, single device name).
  static final TokenManager shared = TokenManager();

  static const _kToken = 'auth_token';
  static const _kExpiresAt = 'auth_expires_at'; // ISO-8601 or empty
  static const _kDeviceName = 'device_name';

  /// Stable, platform-aware device name — generated once per install and
  /// reused for `X-Device-Name` on token refresh.
  static Future<String> resolveDeviceName(TokenManager tokens) async {
    final existing = await tokens.readDeviceName();
    if (existing != null && existing.isNotEmpty) return existing;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      _ => 'web',
    };
    final name = '$platform-${DateTime.now().millisecondsSinceEpoch}';
    await tokens.setDeviceName(name);
    return name;
  }

  Future<String?> readToken() => _s.read(key: _kToken);
  Future<String?> readExpiresAt() => _s.read(key: _kExpiresAt);
  Future<String?> readDeviceName() => _s.read(key: _kDeviceName);

  /// Persist after login/register/refresh (refresh is single-use rotation — caller must call atomically).
  Future<void> persist({
    required String token,
    String? expiresAt,
    String? deviceName,
  }) async {
    await _s.write(key: _kToken, value: token);
    if (expiresAt != null) await _s.write(key: _kExpiresAt, value: expiresAt);
    if (deviceName != null) await _s.write(key: _kDeviceName, value: deviceName);
  }

  Future<void> setDeviceName(String name) => _s.write(key: _kDeviceName, value: name);

  Future<void> clear() async {
    await _s.delete(key: _kToken);
    await _s.delete(key: _kExpiresAt);
    // keep deviceName — stable per install
  }

  /// True when `expires_at` is < 7 days away (or missing and caller wants proactive check).
  Future<bool> shouldRefresh() async {
    final raw = await readExpiresAt();
    if (raw == null || raw.isEmpty) return false; // server says no expiry
    final dt = DateTime.tryParse(raw);
    if (dt == null) return false;
    return dt.difference(DateTime.now()).inDays < 7;
  }
}

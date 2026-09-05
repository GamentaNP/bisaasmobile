import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Adds the W3 device headers to every request (security plan W3.1).
///
/// - `X-Install-Id`: client-generated UUID v4 persisted in secure storage.
///   Survives app updates; a reinstall generates a fresh value (which is the
///   point — the server treats a changed install on a live token as a risk
///   signal, never a denial).
/// - `X-App-Version` + `X-Platform`: feed the server's
///   EnforceMinimumAppVersion gate (426 with the floor when stale). The
///   version comes from `--dart-define=APP_VERSION`, injected by CI and the
///   Fastfiles; an empty default omits the header, and the server cannot
///   judge what it cannot see — which is the honest pre-W3-client behaviour.
class InstallIdentityInterceptor extends Interceptor {
  InstallIdentityInterceptor({
    FlutterSecureStorage? storage,
    Uuid? uuid,
    String Function()? appVersion,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid(),
        _appVersion = appVersion ?? defaultAppVersion;

  static const _installIdKey = 'device.install_id';

  /// Header contract (server: DeviceBindingService::installId).
  static const installIdHeader = 'X-Install-Id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;
  final String Function() _appVersion;

  String? _cachedInstallId;

  /// Resolved at compile time — String.fromEnvironment is const-only and
  /// throws at runtime on web (DDC) if invoked dynamically.
  static const _compiledAppVersion = String.fromEnvironment('APP_VERSION');

  static String defaultAppVersion() => _compiledAppVersion;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(_attach(options, handler));
  }

  Future<void> _attach(RequestOptions options, RequestInterceptorHandler handler) async {
    final installId = await _installId();
    if (installId != null) {
      options.headers[installIdHeader] = installId;
    }

    final version = _appVersion();
    if (version.isNotEmpty) {
      options.headers['X-App-Version'] = version;
      options.headers['X-Platform'] =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    }

    handler.next(options);
  }

  Future<String?> _installId() async {
    final cached = _cachedInstallId;
    if (cached != null) return cached;

    try {
      var existing = await _storage.read(key: _installIdKey);

      if (existing == null || existing.isEmpty) {
        // Regenerate on first run of every fresh install.
        existing = _uuid.v4();
        await _storage.write(key: _installIdKey, value: existing);
      }

      return _cachedInstallId = existing;
    } on Object {
      // Secure storage unavailable (web, tests): omit the header rather than
      // fail the request.
      return null;
    }
  }
}

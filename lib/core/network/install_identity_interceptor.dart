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

  /// Normalises whatever CI injected into a bare `MAJOR.MINOR.PATCH`.
  ///
  /// The server's `EnforceAppVersion` middleware only judges a version matching
  /// `/^\d+\.\d+\.\d+(-[\w.]+)?$/` and — deliberately — *passes the request
  /// through* when it does not match, because refusing header-less or
  /// unparseable requests would brick older clients at deploy time. That
  /// fail-open is correct, but it meant a tag-derived value silently disabled
  /// the whole gate: CI passed `${{ github.ref_name }}`, so a `v1.2.3` tag sent
  /// `v1.2.3`, the regex rejected it, and no release was ever actually gated.
  /// Stripping the leading `v` and any `+build` suffix makes the header
  /// judgeable, so a raised minimum can really lock out a stale build.
  static String normaliseAppVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    // `1.2.3+45` is valid Dart/pubspec but the server regex allows no `+`.
    final plus = v.indexOf('+');
    if (plus != -1) {
      v = v.substring(0, plus);
    }
    return v;
  }

  static String defaultAppVersion() => normaliseAppVersion(_compiledAppVersion);

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

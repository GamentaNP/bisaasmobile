/// freeRASP-backed security matrix.
///
/// Integrated via the [Talsec] singleton from the `freerasp` package.
/// - Bootstrap calls [AppSecurity.init] once (non-blocking, best-effort).
/// - Threats stream to [AppSecurity.threatStream] for reactive handling.
/// - [AppSecurity.isDeviceCompromised] is a one-shot synchronous check used
///   before sensitive writes; it checks _compromised set by the stream.
/// - No brick on false positive — log + advise pattern only, unless
///   killOnBypass is true in the TalsecConfig.
///
/// Platform notes:
/// - Android: requires signingCertHashes (SHA-256 of the keystore cert in
///   base64); injected at compile time via --dart-define=SIGNING_CERT_HASH.
/// - iOS: requires bundleIds + teamId; injected via --dart-define.
/// - Web/Windows/Linux: no-ops (freeRASP is mobile-only).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

import '../logging/app_logger.dart';

class AppSecurity {
  const AppSecurity._();

  // ---------------------------------------------------------------------------
  // Compile-time injection — populate in dart_defines/production.json.
  // Defaults are empty strings so dev builds don't crash; validation is
  // handled by TalsecConfig itself when the values are set.
  // ---------------------------------------------------------------------------
  static const _androidSigningHash = String.fromEnvironment(
    'SIGNING_CERT_HASH',
    defaultValue: '',
  );
  static const _iosBundleId = String.fromEnvironment(
    'IOS_BUNDLE_ID',
    defaultValue: 'com.bisaas.bisaasmobile',
  );
  static const _iosTeamId = String.fromEnvironment(
    'IOS_TEAM_ID',
    defaultValue: '',
  );
  static const _watcherMail = String.fromEnvironment(
    'SECURITY_WATCHER_MAIL',
    defaultValue: 'security@bisaas.com',
  );

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  static bool _compromised = false;
  static bool _initialized = false;
  static final StreamController<Threat> _controller =
      StreamController<Threat>.broadcast();

  /// Broadcast stream of detected threats.
  /// UI layers can subscribe to surface warnings without polling.
  static Stream<Threat> get threatStream => _controller.stream;

  // ---------------------------------------------------------------------------
  // Bootstrap — call once from bootstrap.dart after Firebase init.
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // freeRASP only runs on Android and iOS.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      AppLogger.i('AppSecurity: freeRASP skipped (non-mobile platform)');
      return;
    }

    try {
      final config = _buildConfig();
      if (config == null) {
        // Dev build without dart-defines — fall back gracefully.
        AppLogger.w(
          'AppSecurity: freeRASP config incomplete (missing dart-defines) — '
          'falling back to no-op security in this build',
        );
        return;
      }

      final callback = ThreatCallback(
        onPrivilegedAccess: () => _onThreat(Threat.privilegedAccess, 'root/jailbreak'),
        onDebug: () => _onThreat(Threat.debug, 'debugger attached'),
        onSimulator: () => _onThreat(Threat.simulator, 'emulator/simulator'),
        onHooks: () => _onThreat(Threat.hooks, 'dynamic hooking (Frida)'),
        onAppIntegrity: () => _onThreat(Threat.appIntegrity, 'app integrity violated'),
        onDeviceBinding: () => _onThreat(Threat.deviceBinding, 'device binding compromised'),
        onUnofficialStore: () => _onThreat(Threat.unofficialStore, 'unofficial store'),
        onObfuscationIssues: () => _onThreat(Threat.obfuscationIssues, 'obfuscation missing'),
        onDevMode: () => _onThreat(Threat.devMode, 'developer mode'),
      );

      await Talsec.instance.attachListener(callback);
      await Talsec.instance.start(config);
      AppLogger.i('AppSecurity: freeRASP started (isProd=${config.isProd})');
    } catch (e, st) {
      // Never crash the app for a security init failure.
      AppLogger.w('AppSecurity: freeRASP init error: $e');
      if (kDebugMode) AppLogger.d(st);
    }
  }

  // ---------------------------------------------------------------------------
  // One-shot check (synchronous) — relies on state set by the threat stream.
  // ---------------------------------------------------------------------------

  /// Returns true if a root/jailbreak or integrity threat has been detected
  /// since [init] was called.  Call before any sensitive local write.
  static bool isDeviceCompromised() => _compromised;

  static Future<void> auditOrWarn() async {
    if (_compromised) {
      AppLogger.w(
        'AppSecurity: device appears compromised — '
        'token remains in secure storage but user should be advised',
      );
    } else {
      AppLogger.i('AppSecurity: device security audit passed');
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static void _onThreat(Threat threat, String label) {
    AppLogger.w('AppSecurity: threat detected — $label (${threat.name})');
    // Mark compromised for high-severity threats only.
    const highSeverity = {
      Threat.privilegedAccess,
      Threat.hooks,
      Threat.appIntegrity,
      Threat.deviceBinding,
    };
    if (highSeverity.contains(threat)) {
      _compromised = true;
    }
    if (!_controller.isClosed) _controller.add(threat);
  }

  static TalsecConfig? _buildConfig() {
    const isProd = !kDebugMode;

    // Android config requires a signing hash.
    AndroidConfig? androidConfig;
    if (Platform.isAndroid && _androidSigningHash.isNotEmpty) {
      androidConfig = AndroidConfig(
        packageName: 'com.bisaas.bisaasmobile',
        signingCertHashes: [_androidSigningHash],
        supportedStores: [
          'com.android.vending', // Google Play
        ],
      );
    }

    // iOS config requires teamId.
    IOSConfig? iosConfig;
    if (Platform.isIOS && _iosTeamId.isNotEmpty) {
      iosConfig = IOSConfig(
        bundleIds: [_iosBundleId],
        teamId: _iosTeamId,
      );
    }

    // Require at least one platform config to be valid.
    if (androidConfig == null && iosConfig == null) return null;

    return TalsecConfig(
      watcherMail: _watcherMail,
      isProd: isProd,
      killOnBypass: false, // advise, don't brick
      androidConfig: androidConfig,
      iosConfig: iosConfig,
    );
  }
}

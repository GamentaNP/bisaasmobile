import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// Holds the forced-update state for the whole app.
///
/// The server refuses a stale build with **426 Upgrade Required** rather than
/// asking it to update (`EnforceAppVersion` → `AppUpdateRequiredException`).
/// Because that applies to *every* route, the state is global rather than
/// per-screen: once the server has refused this build, no screen can work, and
/// retrying is pointless because the only fix is a new install.
class AppUpdateGate extends ChangeNotifier {
  AppUpdateGate();

  static final AppUpdateGate instance = AppUpdateGate();

  String? _minVersion;
  String? _platform;
  String? _currentVersion;

  /// True once the server has refused this build. Latches — a later success
  /// must not silently unlock a build the server considers unsupported.
  bool get isBlocked => _minVersion != null;

  String? get minVersion => _minVersion;
  String? get platform => _platform;
  String? get currentVersion => _currentVersion;

  /// Latches the block from a 426 response. Safe to call for any error; a
  /// non-426 is ignored.
  void observe(Object error) {
    if (error is! ApiException || !error.isAppUpdateRequired) return;
    final min = error.minRequiredVersion;
    if (min == null) return;
    if (_minVersion == min) return;
    _minVersion = min;
    final d = error.details;
    if (d is Map) {
      _platform = d['platform'] as String?;
      _currentVersion = d['current_version'] as String?;
    }
    notifyListeners();
  }

  /// Test seam.
  void reset() {
    _minVersion = null;
    _platform = null;
    _currentVersion = null;
  }
}

/// Where to send a user who must update.
///
/// The Play URL resolves by package name and needs nothing else.
///
/// The App Store does **not** have a package-name lookup: `apps.apple.com/app/id…`
/// takes the *numeric* App Store ID that Apple issues at first publish, so
/// `idcom.bisaas.bisaasmobile` is not a URL — it is a 404. The numeric ID is
/// a deployment value (like the certificate pins), so it arrives as
/// `--dart-define=APP_STORE_ID=…` and is read from the build.
///
/// Until the app is published there is no numeric ID yet. Rather than shipping
/// a link that cannot work, the fallback is the public support page, which
/// always resolves and always reaches a human who can point the user at the
/// right build.
class StoreLinks {
  const StoreLinks._();

  static const packageId = 'com.bisaas.bisaasmobile';

  /// Where the support page lives. Used as the iOS fallback before the app
  /// has a numeric App Store ID.
  static const supportUrl = 'https://bisaas.com/support';

  /// The numeric App Store ID, e.g. `1234567890`. Supplied at build time by
  /// `dart_defines/production.json` once the app has been published.
  static const defaultAppStoreId = String.fromEnvironment('APP_STORE_ID');

  static bool get hasAppStoreId => defaultAppStoreId.trim().isNotEmpty;

  /// [appStoreId] overrides the compiled-in ID. It exists so the behaviour is
  /// testable — `String.fromEnvironment` is fixed at compile time.
  static String forPlatform({
    String? platform,
    TargetPlatform? fallback,
    String? appStoreId,
  }) {
    final isIos = (platform ?? '').toLowerCase() == 'ios' ||
        fallback == TargetPlatform.iOS;
    if (!isIos) {
      return 'https://play.google.com/store/apps/details?id=$packageId';
    }
    final id = (appStoreId ?? defaultAppStoreId).trim();
    return id.isEmpty
        ? supportUrl
        : 'https://apps.apple.com/app/id$id';
  }
}

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

/// Where to send a user who must update. The numeric Play applicationId is not
/// committed here (it is issued by Play Console at first publish), so the
/// package-name lookup URL is used — it resolves by package and keeps working
/// without a code change.
class StoreLinks {
  const StoreLinks._();

  static const packageId = 'com.bisaas.bisaasmobile';

  static String forPlatform({String? platform, TargetPlatform? fallback}) {
    final isIos = (platform ?? '').toLowerCase() == 'ios' ||
        fallback == TargetPlatform.iOS;
    return isIos
        ? 'https://apps.apple.com/app/id$packageId'
        : 'https://play.google.com/store/apps/details?id=$packageId';
  }
}

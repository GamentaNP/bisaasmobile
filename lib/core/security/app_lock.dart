import 'dart:async';

import 'package:flutter/widgets.dart';

import '../storage/preferences.dart';
import 'biometric_auth.dart';

/// Locks app when backgrounded > [grace] and challenges biometric on resume.
/// Only active when the user enabled it in Preferences (and the device has
/// biometrics — otherwise locking would be irreversible).
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock({
    required BiometricAuth biometrics,
    required bool lockEnabled,
    this.grace = const Duration(seconds: 30),
  })  : _bio = biometrics,
        _enabled = lockEnabled;

  final BiometricAuth _bio;
  final Duration grace;
  DateTime? _pausedAt;
  bool _locked = false;
  bool _enabled;

  bool get isLocked => _locked;
  bool get enabled => _enabled;

  /// Toggle from settings; disabling immediately unlocks.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await Preferences.instance.setAppLockEnabled(value);
    if (!value && _locked) {
      _locked = false;
      notifyListeners();
    }
  }

  void init() => WidgetsBinding.instance.addObserver(this);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      if (paused != null && DateTime.now().difference(paused) > grace) {
        _locked = true;
        notifyListeners();
        unawaited(challenge());
      }
    }
  }

  /// Biometric challenge; devices without biometrics never stay locked.
  Future<void> challenge() async {
    final can = await _bio.canCheck;
    if (!can) {
      _locked = false;
      notifyListeners();
      return;
    }
    final ok = await _bio.authenticate(reason: 'Unlock CivilCal');
    _locked = !ok;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }
}

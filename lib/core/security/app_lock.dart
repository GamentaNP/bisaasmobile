import 'dart:async';

import 'package:flutter/widgets.dart';

import 'biometric_auth.dart';

/// Locks app when backgrounded > [grace] and challenges biometric on resume.
class AppLock with WidgetsBindingObserver {
  AppLock({required BiometricAuth biometrics, this.grace = const Duration(seconds: 30)})
      : _bio = biometrics;

  final BiometricAuth _bio;
  final Duration grace;
  DateTime? _pausedAt;
  bool _locked = false;

  bool get isLocked => _locked;

  void init() => WidgetsBinding.instance.addObserver(this);
  void dispose() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      if (paused != null && DateTime.now().difference(paused) > grace) {
        _locked = true;
        unawaited(_challenge());
      }
    }
  }

  Future<void> _challenge() async {
    final ok = await _bio.authenticate(reason: 'Unlock CivilCal');
    _locked = !ok;
  }

  void unlock() => _locked = false;
}

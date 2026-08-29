library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService(this._c);
  final Connectivity _c;

  Stream<bool> get onOnlineChanged =>
      _c.onConnectivityChanged.map((r) => r.any((c) => c != ConnectivityResult.none));

  Future<bool> isOnline() async {
    final r = await _c.checkConnectivity();
    return r.any((c) => c != ConnectivityResult.none);
  }
}

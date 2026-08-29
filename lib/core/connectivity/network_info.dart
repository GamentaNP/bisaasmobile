import 'package:connectivity_plus/connectivity_plus.dart';

abstract final class NetworkInfo {
  static bool isOnlineFromResult(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  static bool isWifi(List<ConnectivityResult> r) =>
      r.contains(ConnectivityResult.wifi);

  static bool isMobile(List<ConnectivityResult> r) =>
      r.contains(ConnectivityResult.mobile);
}

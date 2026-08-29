import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  DeviceInfoService(this._device, this._pkg);
  final DeviceInfoPlugin _device;
  final PackageInfo _pkg;

  String get appVersion => _pkg.version;
  String get buildNumber => _pkg.buildNumber;

  Future<String> platformLabel() async {
    try {
      final android = await _device.androidInfo;
      return 'android-${android.version.release}';
    } catch (_) {}
    try {
      final ios = await _device.iosInfo;
      return 'ios-${ios.systemVersion}';
    } catch (_) {}
    return 'unknown';
  }
}

import 'package:flutter/services.dart';

abstract final class SystemUiService {
  static Future<void> setTransparentStatusBar() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  static void setPreferredOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

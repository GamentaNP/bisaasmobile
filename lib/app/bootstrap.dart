/// One-shot initialization before runApp — call from main.dart.
library;

import '../core/network/dio_client.dart';
import '../core/security/token_manager.dart';

Future<void> bootstrap() async {
  final tokens = TokenManager();
  // device name stable per install
  final existing = await tokens.readDeviceName();
  if (existing == null) {
    await tokens.setDeviceName('android-${DateTime.now().millisecondsSinceEpoch}');
  }
  await DioClient.init(tokens: tokens);
}

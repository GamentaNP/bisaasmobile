import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:bisaasmobile/app/config/api_config.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("smoke", (tester) async {
    expect(ApiConfig.baseUrl.endsWith("/api/v1"), isTrue);
  });
}

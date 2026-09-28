import 'package:bisaasmobile/app/force_update_screen.dart';
import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/app_update_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppUpdateGate.instance.reset);
  tearDown(AppUpdateGate.instance.reset);

  void latch({String min = '2.0.0', String? current = '1.4.0'}) {
    AppUpdateGate.instance.observe(
      ApiException(
        statusCode: 426,
        code: ApiErrorCode.upgradeRequired,
        message: 'no longer supported',
        details: <String, dynamic>{
          'min_version': min,
          'platform': 'android',
          'current_version': current,
        },
      ),
    );
  }

  testWidgets('gate is transparent while the build is supported', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForceUpdateGate(child: Scaffold(body: Text('home content'))),
      ),
    );
    expect(find.text('home content'), findsOneWidget);
    expect(find.byType(ForceUpdateScreen), findsNothing);
  });

  testWidgets('gate takes over the surface on a 426', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForceUpdateGate(child: Scaffold(body: Text('home content'))),
      ),
    );
    latch();
    await tester.pump();

    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.text('home content'), findsNothing);
  });

  testWidgets('states the minimum version the server demands', (tester) async {
    latch(min: '3.1.4');
    await tester.pumpWidget(
      const MaterialApp(home: ForceUpdateGate(child: SizedBox.shrink())),
    );
    expect(find.textContaining('3.1.4'), findsOneWidget);
  });

  testWidgets('offers no Retry — retrying cannot succeed', (tester) async {
    latch();
    await tester.pumpWidget(
      const MaterialApp(home: ForceUpdateGate(child: SizedBox.shrink())),
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('shows the current version so the user can report it', (
    tester,
  ) async {
    latch(current: '1.4.0');
    await tester.pumpWidget(
      const MaterialApp(home: ForceUpdateGate(child: SizedBox.shrink())),
    );
    expect(find.textContaining('1.4.0'), findsOneWidget);
  });

  testWidgets('reassures the user that progress is safe', (tester) async {
    latch();
    await tester.pumpWidget(
      const MaterialApp(home: ForceUpdateGate(child: SizedBox.shrink())),
    );
    expect(find.textContaining('nothing is lost'), findsOneWidget);
  });
}

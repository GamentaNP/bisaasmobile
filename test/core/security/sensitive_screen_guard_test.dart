import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisaasmobile/core/security/sensitive_screen_guard.dart';

/// W2.7 (security plan): the FLAG_SECURE guard must open on mount, close on
/// dispose, and never crash a sensitive screen when the platform side is
/// missing (unit-test shells, iOS, web).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];
  Future<Object?>? handler(MethodCall call) async {
    final args = call.arguments as Map<Object?, Object?>?;
    calls.add('${call.method}:${args?['secure']}');
    return null;
  }

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.bisaas/security_screen'),
      handler,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.bisaas/security_screen'),
      null,
    );
  });

  testWidgets('guard sets FLAG_SECURE on mount and clears on dispose',
      (tester) async {
    await tester.pumpWidget(
      SensitiveScreenGuard.guard(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: const Text('exam'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, contains('setFlagSecure:true'));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(calls, contains('setFlagSecure:false'));
  });

  testWidgets('a missing platform handler never throws into the screen',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.bisaas/security_screen'),
      null,
    );

    await tester.pumpWidget(
      SensitiveScreenGuard.guard(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: const Text('premium'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('premium'), findsOneWidget);
  });
}

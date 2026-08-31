import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/shared/widgets/offline_state_banner.dart';

/// Drives [OfflineStateBanner] with a controllable online-status stream.
Future<void> _pump(WidgetTester tester, Stream<bool> stream) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [onlineStatusProvider.overrideWith((_) => stream)],
      child: const MaterialApp(
        home: Scaffold(body: Column(children: [OfflineStateBanner()])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the offline strip when connectivity is false',
      (tester) async {
    await _pump(tester, Stream.value(false));
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('renders nothing when online', (tester) async {
    await _pump(tester, Stream.value(true));
    expect(find.textContaining("You're offline"), findsNothing);
    expect(find.textContaining('Back online'), findsNothing);
  });

  testWidgets('flashes a sync confirmation on offline -> online transition',
      (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onlineStatusProvider.overrideWith((_) => controller.stream)],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [OfflineStateBanner()])),
        ),
      ),
    );
    controller.add(false);
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);

    controller.add(true);
    await tester.pump(); // provider emits -> rebuild
    await tester.pump(); // listener setState -> rebuild shows synced
    expect(find.textContaining('Back online'), findsOneWidget);
  });
}

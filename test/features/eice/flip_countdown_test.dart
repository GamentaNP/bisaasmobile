import 'package:bisaasmobile/features/eice/presentation/widgets/flip_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

void main() {
  final start = DateTime.utc(2026, 11, 27, 10, 0, 0);

  Widget host({
    required String targetDate,
    required int daysRemaining,
    required DateTime Function() now,
    bool disableAnimations = false,
  }) {
    return localizedApp(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: FlipCountdown(
          targetDate: targetDate,
          daysRemaining: daysRemaining,
          now: now,
        ),
      ),
    );
  }

  testWidgets('flips a digit when the clock advances', (tester) async {
    var now = start;
    final target = start.add(
      const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
    );
    await tester.pumpWidget(
      host(
        targetDate: target.toIso8601String(),
        daysRemaining: 1,
        now: () => now,
      ),
    );

    expect(find.text('04'), findsOneWidget);
    // The caption uses the same zero-padded units as the flip boxes.
    expect(find.text('Exam in 01d 02h 03m 04s'), findsOneWidget);

    now = start.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    // The timer tick starts the flip transition; settle it before asserting
    // the outgoing digit has actually left the widget tree.
    await tester.pumpAndSettle();

    expect(find.text('Exam in 01d 02h 03m 02s'), findsOneWidget);
    expect(find.text('04'), findsNothing);
  });

  testWidgets('collapses to zeros once the target has passed', (tester) async {
    await tester.pumpWidget(
      host(
        targetDate: start.subtract(const Duration(seconds: 1)).toIso8601String(),
        daysRemaining: 0,
        now: () => start,
      ),
    );

    expect(find.text('00'), findsNWidgets(4));
    expect(find.text('Exam in 00d 00h 00m 00s'), findsOneWidget);
  });

  testWidgets('reduced motion removes the flip transition', (tester) async {
    await tester.pumpWidget(
      host(
        targetDate: start.add(const Duration(hours: 1)).toIso8601String(),
        daysRemaining: 0,
        now: () => start,
        disableAnimations: true,
      ),
    );

    expect(find.byWidgetPredicate((w) => w is AnimatedSwitcher), findsNothing);
    expect(find.text('01'), findsOneWidget);
  });
}

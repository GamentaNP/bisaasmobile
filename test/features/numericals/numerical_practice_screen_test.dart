import 'package:bisaasmobile/features/numericals/data/datasources/numerical_remote_data_source.dart';
import 'package:bisaasmobile/features/numericals/domain/entities/numerical.dart';
import 'package:bisaasmobile/features/numericals/presentation/numerical_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNumericalRemote extends Mock implements NumericalRemoteDataSource {}

/// Widget tests for the numerical practice screen.
///
/// The invariant under test is the one the server enforces by omission: a wrong
/// attempt must not put the answer on screen. The entity tests cover the label
/// string; these prove the screen does not reach for the value some other way.
void main() {
  late MockNumericalRemote remote;

  setUpAll(() => registerFallbackValue(<String, double>{}));

  setUp(() => remote = MockNumericalRemote());

  Future<void> pump(WidgetTester tester) async {
    // A tall surface so the worked-solution steps are inside the viewport. The
    // default 800x600 test window leaves them below the fold, and a finder for
    // off-screen content fails for a reason unrelated to what is under test.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [numericalRemoteDataSourceProvider.overrideWithValue(remote)],
        child: const MaterialApp(home: NumericalPracticeScreen(numericalId: 5)),
      ),
    );
    await tester.pumpAndSettle();
  }

  const problem = Numerical(
    numericalId: 5,
    statement: 'A simply supported beam of span 6 m carries a UDL.',
    parameters: {'L': 6, 'w': 10},
    unit: 'kN',
  );

  void stubProblem({Numerical? value}) {
    when(() => remote.randomize(5))
        .thenAnswer((_) async => value ?? problem);
  }

  group('the problem renders', () {
    testWidgets('shows the statement and its parameters', (tester) async {
      stubProblem();
      await pump(tester);

      expect(find.textContaining('simply supported beam'), findsOneWidget);
      expect(find.text('L = 6'), findsOneWidget);
      expect(find.text('w = 10'), findsOneWidget);
    });

    testWidgets('an unreadable problem is reported, not shown as blank', (tester) async {
      when(() => remote.randomize(5)).thenAnswer((_) async => null);
      await pump(tester);
      expect(find.textContaining('could not be loaded'), findsOneWidget);
    });

    testWidgets('a failed load is reported', (tester) async {
      when(() => remote.randomize(5)).thenThrow(StateError('boom'));
      await pump(tester);
      expect(find.textContaining('Could not load'), findsOneWidget);
    });
  });

  group('answer grading', () {
    testWidgets('a wrong answer never shows the value', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          // The server withholds final_answer on a wrong attempt.
          const NumericalCheck(correct: false, unit: 'kN'));
      await pump(tester);

      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not correct'), findsOneWidget);
      // 999 is the value the user typed, so it may appear; the server's answer
      // must not. Nothing from the solution can be present because none was
      // requested.
      expect(find.textContaining('Correct'), findsNothing);
    });

    testWidgets('a correct answer shows the value and the unit', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: true, finalAnswer: 60, unit: 'kN'));
      await pump(tester);

      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct'), findsOneWidget);
      expect(find.textContaining('60 kN'), findsOneWidget);
    });

    testWidgets('a whole-number answer is not shown as 60.0', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: true, finalAnswer: 60, unit: 'kN'));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('60.0'), findsNothing);
    });

    testWidgets('a non-numeric answer is rejected without a request', (tester) async {
      stubProblem();
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a number'), findsOneWidget);
      verifyNever(() => remote.checkAnswer(any(), any()));
    });

    testWidgets('a failed grade is reported, not shown as wrong', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenThrow(StateError('boom'));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not grade'), findsOneWidget);
      expect(find.textContaining('Not correct'), findsNothing,
          reason: 'a network failure is not the learner being wrong');
    });
  });

  group('the worked solution', () {
    testWidgets('is not offered before an answer is attempted', (tester) async {
      stubProblem();
      await pump(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Show worked solution'),
      );
      expect(button.onPressed, isNull,
          reason: 'a solution sitting next to an untouched problem turns practice into lookup');
    });

    testWidgets('is offered after a wrong answer', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: false));
      when(() => remote.solve(any(), parameters: any(named: 'parameters')))
          .thenAnswer((_) async => const Numerical(
        numericalId: 5,
        statement: 'x',
        steps: ['Take moments about B', 'Solve for R_A'],
        finalAnswer: 30,
        unit: 'kN',
        computedBy: 'formula',
      ));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show worked solution'));
      await tester.pumpAndSettle();

      // Steps are numbered, so the finder matches the rendered form rather than
      // the raw step text.
      expect(find.text('1. Take moments about B'), findsOneWidget);
      expect(find.text('2. Solve for R_A'), findsOneWidget);
      expect(find.textContaining('Computed by: formula'), findsOneWidget);
    });

    testWidgets('a server-flagged answer says so', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: false));
      when(() => remote.solve(any(), parameters: any(named: 'parameters')))
          .thenAnswer((_) async => const Numerical(
        numericalId: 5,
        statement: 'x',
        steps: ['Derived'],
        finalAnswer: 30,
        needsReview: true,
      ));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show worked solution'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Flagged by the server'), findsOneWidget);
    });

    testWidgets('is not offered again after a correct answer', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: true, finalAnswer: 60, unit: 'kN'));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.text('Show worked solution'), findsNothing);
    });
  });

  group('a new randomisation', () {
    testWidgets('clears the previous verdict', (tester) async {
      stubProblem();
      when(() => remote.checkAnswer(any(), any())).thenAnswer((_) async =>
          const NumericalCheck(correct: true, finalAnswer: 60, unit: 'kN'));
      await pump(tester);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Correct'), findsOneWidget);

      // Same problem, new numbers.
      when(() => remote.randomize(5)).thenAnswer((_) async => const Numerical(
            numericalId: 5,
            statement: 'A new instance of the same problem.',
            parameters: {'L': 8},
            unit: 'kN',
          ));
      await tester.tap(find.byTooltip('New numbers'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct'), findsNothing,
          reason: 'a stale verdict must not sit above fresh numbers');
      expect(find.text('L = 8'), findsOneWidget);
    });
  });
}

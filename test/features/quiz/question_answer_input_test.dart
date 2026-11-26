/// Widget-level proof for every new attempt renderer.
///
/// A single-layer unit test cannot catch the two bugs that mattered here: an
/// answer value built from a display letter instead of the option key, and a
/// first tap/keystroke submitting before a multi-answer question was complete.
import 'package:bisaasmobile/features/quiz/domain/entities/question.dart';
import 'package:bisaasmobile/features/quiz/presentation/widgets/question_answer_input.dart';
import 'package:bisaasmobile/features/quiz/presentation/widgets/question_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

Question question(
  String type, {
  List<AnswerOption> options = const [],
  Map<String, dynamic> metadata = const {},
}) =>
    Question(
      id: '11',
      body: 'Question body',
      options: options,
      subjectSlug: 'soil',
      difficulty: 1,
      marksPositive: 4,
      marksNegative: 0,
      type: type,
      metadata: metadata,
    );

AnswerOption option(String key, String text) =>
    AnswerOption(id: key, text: text, position: 0);

Future<void> pumpInput(
  WidgetTester tester, {
  required Question question,
  required List<String> submitted,
  VoidCallback? onRetry,
}) async {
  await tester.pumpWidget(localizedApp(
    child: Scaffold(
      body: SingleChildScrollView(
        child: QuestionAnswerInput(
          question: question,
          value: '',
          enabled: true,
          hiddenKeys: const <String>{},
          correctKeys: const <String>{},
          isWrong: false,
          onSubmit: submitted.add,
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('single choice submits the option key on tap', (tester) async {
    final submitted = <String>[];
    await pumpInput(
      tester,
      question: question('mcq', options: [
        option('B', 'Choice B'),
        option('C', 'Choice C'),
      ]),
      submitted: submitted,
    );

    await tester.tap(find.text('Choice B'));
    await tester.pump();
    expect(submitted, ['B']);
  });

  testWidgets('multi select joins keys in server order and waits for submit',
      (tester) async {
    final submitted = <String>[];
    await pumpInput(
      tester,
      question: question('multi_select', options: [
        option('B', 'Choice B'),
        option('D', 'Choice D'),
      ]),
      submitted: submitted,
    );

    // Tap in reverse order: the wire value must still follow option order.
    await tester.tap(find.text('Choice D'));
    await tester.pump();
    await tester.tap(find.text('Choice B'));
    await tester.pump();
    expect(submitted, isEmpty, reason: 'a first checkbox must not submit');

    await tester.tap(find.text('Submit answer'));
    await tester.pump();
    expect(submitted, ['B,D']);
  });

  testWidgets('true/false uses localised fallback options and their keys',
      (tester) async {
    final submitted = <String>[];
    await pumpInput(
      tester,
      question: question('true_false'),
      submitted: submitted,
    );

    expect(find.text('True'), findsOneWidget);
    expect(find.text('False'), findsOneWidget);
    await tester.tap(find.text('True'));
    await tester.pump();
    expect(submitted, ['true']);
  });

  testWidgets('fill blank submits the typed string only on confirm',
      (tester) async {
    final submitted = <String>[];
    await pumpInput(
      tester,
      question: question('fill_blank'),
      submitted: submitted,
    );

    await tester.enterText(find.byType(TextField), 'colour');
    await tester.pump();
    expect(submitted, isEmpty);
    await tester.tap(find.text('Submit answer'));
    await tester.pump();
    expect(submitted, ['colour']);
  });

  testWidgets('multiple blanks use the slot:answer wire format',
      (tester) async {
    final submitted = <String>[];
    await pumpInput(
      tester,
      question: question('fill_blank_multiple',
          metadata: {'blank_count': 2}),
      submitted: submitted,
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'cat');
    await tester.enterText(fields.at(1), 'dog');
    await tester.pump();
    expect(submitted, isEmpty);
    await tester.tap(find.text('Submit answer'));
    await tester.pump();
    expect(submitted, ['blank_1:cat,blank_2:dog']);
  });

  testWidgets('image based renders the question figure and choice keys',
      (tester) async {
    final submitted = <String>[];
    const imageUrl = 'https://evil.example.com/not-loaded.png';
    await pumpInput(
      tester,
      question: question('image_based',
          options: [option('A', 'Choice A'), option('B', 'Choice B')],
          metadata: {'image_url': imageUrl}),
      submitted: submitted,
    );

    final image = find.byType(QuestionImage);
    expect(image, findsOneWidget);
    expect(tester.widget<QuestionImage>(image).imageUrl, imageUrl);
    await tester.tap(find.text('Choice A'));
    await tester.pump();
    expect(submitted, ['A']);
  });

  testWidgets('an unknown family shows a localised error and retries',
      (tester) async {
    final submitted = <String>[];
    var retries = 0;
    await pumpInput(
      tester,
      question: question('theory'),
      submitted: submitted,
      onRetry: () => retries++,
    );

    expect(find.textContaining('theory'), findsOneWidget);
    expect(find.text('Submit answer'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
    expect(submitted, isEmpty);
  });
}

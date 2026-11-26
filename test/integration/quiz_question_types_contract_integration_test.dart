/// End-to-end proof that every supported question family submits the wire
/// answer the server grader parses, through the real Dio → envelope → DTO →
/// domain → repository → controller chain.
///
/// The option rows deliberately carry numeric `id`s next to their `key`s:
/// sending the id would make the grader mark a correct answer wrong.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/question.dart';
import 'package:bisaasmobile/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:bisaasmobile/features/quiz/presentation/state/quiz_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _question(
  int id,
  String type, {
  List<Map<String, dynamic>> options = const [],
  Map<String, dynamic> metadata = const {},
}) =>
    <String, dynamic>{
      'id': id,
      'question_text': 'Question $id ($type)',
      'type': type,
      'options': [
        for (var i = 0; i < options.length; i++)
          {
            'key': options[i]['key'],
            'id': id * 100 + i,
            'text': options[i]['text'],
          },
      ],
      'metadata': metadata,
      'difficulty': 'medium',
      'points': 4,
    };

void main() {
  late FakeApi api;
  late AppDatabase db;
  late ProviderContainer container;

  final questions = <Map<String, dynamic>>[
    _question(1, 'mcq', options: [
      {'key': 'A', 'text': 'First'},
      {'key': 'B', 'text': 'Second'},
    ]),
    _question(2, 'multi_select', options: [
      {'key': 'B', 'text': 'Second'},
      {'key': 'D', 'text': 'Fourth'},
    ]),
    _question(3, 'true_false', options: [
      {'key': 'true', 'text': 'True'},
      {'key': 'false', 'text': 'False'},
    ]),
    _question(4, 'fill_blank'),
    _question(5, 'fill_blank_multiple', options: [
      {'key': 'a', 'text': 'First blank'},
      {'key': 'b', 'text': 'Second blank'},
    ]),
    _question(6, 'image_based',
        options: [
          {'key': 'A', 'text': 'First'},
          {'key': 'B', 'text': 'Second'},
        ],
        metadata: {'image_url': 'https://bisaas.test/figure.png'}),
  ];
  final answers = ['B', 'B,D', 'true', 'colour', 'a:cat,b:dog', 'A'];
  final kinds = [
    QuizQuestionType.singleChoice,
    QuizQuestionType.multipleChoice,
    QuizQuestionType.trueFalse,
    QuizQuestionType.fillBlank,
    QuizQuestionType.fillBlankMultiple,
    QuizQuestionType.imageBased,
  ];

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    db = AppDatabase(NativeDatabase.memory());
    api.on('GET', '/quiz/courses', FakeRoute.ok(<String, dynamic>{
      'data': <dynamic>[
        {'id': 5, 'name': 'Course'},
      ],
    }));
    api.on('GET', '/quiz/courses/5/questions', FakeRoute.ok(<String, dynamic>{
      'items': questions,
    }));
    api.on('POST', '/quiz/attempts', FakeRoute.ok(<String, dynamic>{
      'attempt_id': 710,
      'mode': 'standard',
      'status': 'in_progress',
      'question_count': questions.length,
    }));
    api.on('GET', '/quiz/attempts/710/lifelines',
        FakeRoute.ok(<String, dynamic>{'enabled': false, 'lifelines': <dynamic>[]}));
    api.on('POST', '/quiz/attempts/710/answers',
        FakeRoute.ok(<String, dynamic>{'saved': true}));
    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dioFor(api)),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('every family parses its type and submits its grader-shaped answer',
      () async {
    final controller = container.read(quizControllerProvider.notifier);
    QuizState state() => container.read(quizControllerProvider);

    await controller.startSession('5');
    expect(state().phase, QuizPhase.answering);

    for (var index = 0; index < answers.length; index++) {
      final question = state().currentQuestion!;
      expect(question.inputKind, kinds[index],
          reason: 'question ${index + 1} must select the right renderer');
      final wireOptions =
          (questions[index]['options'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(question.options.map((option) => option.id).toList(),
          wireOptions.map((option) => option['key']).toList(),
          reason: 'the answer value is the option key, not its numeric id');

      await controller.selectAnswer(answers[index]);
      expect(state().phase, QuizPhase.feedback);
      expect(state().lastResult!.selectedOptionId, answers[index]);
      if (index < answers.length - 1) controller.nextQuestion();
    }

    final writes =
        api.requests.where((r) => r.path.endsWith('/answers')).toList();
    expect(writes, hasLength(answers.length));
    for (var index = 0; index < answers.length; index++) {
      expect(api.jsonBodyOf(api.requests.indexOf(writes[index]))['answer'],
          answers[index],
          reason: 'question ${index + 1} sent the wrong wire answer');
    }
  });

  test('the image-based question carries its figure from attempt-safe metadata',
      () async {
    final controller = container.read(quizControllerProvider.notifier);
    await controller.startSession('5');
    for (var i = 0; i < 5; i++) {
      await controller.selectAnswer(answers[i]);
      controller.nextQuestion();
    }
    final question = container.read(quizControllerProvider).currentQuestion!;
    expect(question.inputKind, QuizQuestionType.imageBased);
    expect(question.imageUrl, 'https://bisaas.test/figure.png');
    expect(question.type, 'image_based');
  });

  test('an unsupported family is preserved verbatim instead of becoming an MCQ',
      () async {
    api.on('GET', '/quiz/courses/5/questions',
        FakeRoute.ok(<String, dynamic>{
      'items': [
        _question(9, 'theory', options: [
          {'key': 'A', 'text': 'First'},
          {'key': 'B', 'text': 'Second'},
        ]),
      ],
    }));
    final controller = container.read(quizControllerProvider.notifier);
    await controller.startSession('5');

    final question = container.read(quizControllerProvider).currentQuestion!;
    expect(question.type, 'theory');
    expect(question.inputKind, isNull);
    expect(api.countOf('POST', '/answers'), 0);
  });
}

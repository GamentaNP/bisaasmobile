/// Wire-shape proof for the attempt renderers.
///
/// The server's `QuestionPublicResource` publishes `type` and attempt-safe
/// `metadata`; the grader keys answers by `options[].key`. These are the two
/// facts the old client dropped, so they are pinned here before the widget
/// and integration layers build on them.
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/models/quiz_dto.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question parse(Map<String, dynamic> raw) => QuestionDto.fromJson(raw).toDomain();

Map<String, dynamic> wire(
  String type, {
  List<Map<String, dynamic>> options = const [],
  Map<String, dynamic> metadata = const {},
}) =>
    <String, dynamic>{
      'id': 11,
      'question_text': 'Pick one',
      'type': type,
      'options': options,
      'metadata': metadata,
      'points': 4,
    };

void main() {
  test('every supported server family maps to one renderer', () {
    expect(parse(wire('mcq')).inputKind, QuizQuestionType.singleChoice);
    expect(parse(wire('mcq_single')).inputKind, QuizQuestionType.singleChoice);
    expect(parse(wire('best_answer')).inputKind, QuizQuestionType.singleChoice);
    expect(parse(wire('odd_one_out')).inputKind, QuizQuestionType.singleChoice);
    expect(parse(wire('multi_select')).inputKind,
        QuizQuestionType.multipleChoice);
    expect(parse(wire('mcq_multiple')).inputKind,
        QuizQuestionType.multipleChoice);
    expect(parse(wire('true_false')).inputKind, QuizQuestionType.trueFalse);
    expect(parse(wire('fill_blank')).inputKind, QuizQuestionType.fillBlank);
    expect(parse(wire('fill_blank_single')).inputKind, QuizQuestionType.fillBlank);
    expect(parse(wire('fill_blank_multiple')).inputKind,
        QuizQuestionType.fillBlankMultiple);
    expect(parse(wire('image_based')).inputKind, QuizQuestionType.imageBased);
    expect(parse(wire('image_mcq')).inputKind, QuizQuestionType.imageBased);
  });

  test('an unknown family stays unknown and is not silently an MCQ', () {
    final question = parse(wire('theory'));
    expect(question.type, 'theory');
    expect(question.inputKind, isNull);
    expect(parse(wire('match_pairs')).inputKind, isNull);
    expect(parse(wire('')).inputKind, QuizQuestionType.singleChoice,
        reason: 'legacy cache rows have no type and only ever held MCQs');
    expect(parse(<String, dynamic>{'id': 1}).inputKind,
        QuizQuestionType.singleChoice);
  });

  test('the option key — not the numeric id — becomes the answer value', () {
    final question = parse(wire('mcq', options: [
      {'key': 'B', 'id': 20, 'text': 'Choice B'},
      {'key': 'C', 'id': 21, 'text': 'Choice C'},
    ]));
    expect(question.options.map((option) => option.id), ['B', 'C']);
  });

  test('image and blank metadata survive the wire', () {
    final question = parse(wire('image_based',
        metadata: {'image_url': 'https://bisaas.test/q.png'}));
    expect(question.imageUrl, 'https://bisaas.test/q.png');

    final blanks = parse(wire('fill_blank_multiple',
        metadata: {'blank_count': 2}));
    expect(blanks.blankCount, 2);
    expect(blanks.blankKeys, ['blank_1', 'blank_2']);

    final authored = parse(wire('fill_blank_multiple', options: [
      {'key': 'a', 'text': 'First'},
      {'key': 'b', 'text': 'Second'},
    ]));
    expect(authored.blankKeys, ['a', 'b'],
        reason: 'authored slot keys must win over the fallback numbering');

    final packed = parse(<String, dynamic>{
      'id': 3,
      'type': 'image_based',
      'image_url': 'https://bisaas.test/pack.png',
    });
    expect(packed.imageUrl, 'https://bisaas.test/pack.png',
        reason: 'the offline pack carries image_url at the top level');
  });

  test('the remote normaliser forwards type and metadata to the DTO', () {
    final raw = wire(
      'multi_select',
      options: [
        {'key': 'a', 'text': 'A'},
        {'key': 'b', 'text': 'B'},
      ],
      metadata: const {'blank_count': 3},
    );
    final mapped = QuizRemoteDataSource.questionToDtoMap(raw, '5');
    expect(mapped['type'], 'multi_select');
    expect(mapped['metadata'], isA<Map<String, dynamic>>());
    expect(parse(mapped).inputKind, QuizQuestionType.multipleChoice);
  });
}

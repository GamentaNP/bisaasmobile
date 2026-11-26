import 'package:bisaasmobile/features/quiz/data/models/quiz_catalog_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the results row parses the server explanation and its provenance', () {
    final entry = AttemptReviewEntryDto.fromJson(<String, dynamic>{
      'question_id': 11,
      'question_text': 'Which law explains this?',
      'given_answer': 'a',
      'is_correct': true,
      'explanation': 'Newton third law makes this the right choice.',
      'explanation_source': 'base',
    }).toDomain();

    expect(entry.explanation, 'Newton third law makes this the right choice.');
    expect(entry.explanationSource, 'base');
  });

  test('an omitted explanation stays null — the client invents no prose', () {
    final entry = AttemptReviewEntryDto.fromJson(<String, dynamic>{
      'question_id': 12,
      'question_text': 'Question without a key',
      'is_correct': null,
    }).toDomain();

    expect(entry.explanation, isNull);
    expect(entry.explanationSource, isNull);
  });

  test('a null explanation from a locked review stays null', () {
    final entry = AttemptReviewEntryDto.fromJson(<String, dynamic>{
      'question_id': 13,
      'explanation': null,
      'explanation_source': null,
      'is_correct': null,
    }).toDomain();

    expect(entry.explanation, isNull);
    expect(entry.explanationSource, isNull);
  });
}

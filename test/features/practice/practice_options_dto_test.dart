import 'package:bisaasmobile/features/practice/data/models/practice_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Options and weak-area parsing, pinned to payloads observed live on
/// 2026-09-27.
void main() {
  group('PracticeQuestionDto options', () {
    test('parses the real {key,text} option list', () {
      // GET /api/v1/quiz/questions returns:
      //   "options": [{"key":"A","text":"Option A - primary concept"}, ...]
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 31105,
        'question_text': 'Which statement is correct?',
        'options': [
          {'key': 'A', 'text': 'Option A - primary concept'},
          {'key': 'B', 'text': 'Option B - alternative interpretation'},
          {'key': 'C', 'text': 'Option C - secondary effect'},
          {'key': 'D', 'text': 'Option D - unrelated factor'},
        ],
      });

      expect(dto.options, hasLength(4));
      expect(dto.options.first.key, 'A');
      expect(dto.options.first.text, 'Option A - primary concept');
      expect(dto.options.last.key, 'D');
      // Crucially, no answer key is derived from the option list.
      expect(dto.options.any((o) => o.text.toLowerCase().contains('correct')), isFalse);
    });

    test('tolerates id/value keys and bare strings', () {
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 1,
        'options': [
          {'id': 'x', 'text': 'first'},
          {'value': 'y', 'text': 'second'},
        ],
      });
      expect(dto.options.map((o) => o.key), ['x', 'y']);
    });

    test('assigns positional letters when the key is missing', () {
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 1,
        'options': [
          {'text': 'one'},
          {'text': 'two'},
        ],
      });
      expect(dto.options.map((o) => o.key), ['A', 'B']);
    });

    test('a bare string list becomes keyed options', () {
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 1,
        'options': ['alpha', 'beta'],
      });
      expect(dto.options.map((o) => o.text), ['alpha', 'beta']);
      expect(dto.options.map((o) => o.key), ['A', 'B']);
    });

    test('missing options stay empty — the UI must say so, not invent A-D', () {
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 1,
        'question_text': 'No options on this one',
      });
      expect(dto.options, isEmpty);
      expect(dto.toDomain().hasOptions, isFalse);
    });

    test('toDomain carries the options through', () {
      final dto = PracticeQuestionDto.fromJson(const {
        'id': 42,
        'question_text': 'Q',
        'options': [
          {'key': 'A', 'text': 'a'},
          {'key': 'B', 'text': 'b'},
        ],
      });
      final domain = dto.toDomain();
      expect(domain.hasOptions, isTrue);
      expect(domain.options, hasLength(2));
      expect(domain.options[1].key, 'B');
    });
  });
}

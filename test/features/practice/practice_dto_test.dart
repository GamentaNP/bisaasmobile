import 'package:bisaasmobile/features/practice/data/models/practice_dto.dart';
import 'package:bisaasmobile/features/practice/domain/entities/practice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PracticeQuestionDto', () {
    test('fromJson minimal', () {
      final dto = PracticeQuestionDto.fromJson({'id': 10, 'question_text': 'What is soil?', 'type': 'mcq', 'difficulty': 2, 'points': 4});
      expect(dto.id, 10);
      expect(dto.questionText, 'What is soil?');
      expect(dto.type, 'mcq');
      expect(dto.toDomain(), isA<PracticeQuestion>());
    });

    test('handles string id and fallback keys', () {
      final dto = PracticeQuestionDto.fromJson({'id': '20', 'body': 'Body fallback', 'quiz_category_id': 5});
      expect(dto.id, 20);
      expect(dto.questionText, 'Body fallback');
      expect(dto.categoryId, 5);
    });

    test('additive ignores unknown', () {
      final dto = PracticeQuestionDto.fromJson({'id': 1, 'question_text': 'Q', 'new_field': 'ignored', 'extra': 123});
      expect(dto.id, 1);
    });

    test('fallback for missing fields', () {
      final dto = PracticeQuestionDto.fromJson({});
      expect(dto.id, 0);
      expect(dto.questionText, '');
    });
  });

  group('BookmarkedQuestionDto', () {
    test('fromJson direct question', () {
      final dto = BookmarkedQuestionDto.fromJson({'id': 5, 'question_text': 'Q1', 'type': 'mcq', 'created_at': '2026-08-30T10:00:00Z'});
      expect(dto.question.id, 5);
      expect(dto.bookmarkedAt, isNotNull);
      expect(dto.toDomain(), isA<BookmarkedQuestion>());
    });

    test('fromJson wrapped question', () {
      final dto = BookmarkedQuestionDto.fromJson({
        'question': {'id': 6, 'question_text': 'Wrapped', 'type': 'mcq'},
        'created_at': '2026-08-30T10:00:00Z'
      });
      expect(dto.question.questionText, 'Wrapped');
    });

    test('handles missing created_at', () {
      final dto = BookmarkedQuestionDto.fromJson({'id': 7, 'question_text': 'Q'});
      expect(dto.bookmarkedAt, isNull);
    });
  });

  group('PracticeAttemptHistoryDto', () {
    test('fromJson minimal', () {
      final dto = PracticeAttemptHistoryDto.fromJson({'id': 100, 'mode': 'practice', 'status': 'completed', 'score': 85, 'correct_count': 8, 'wrong_count': 2});
      expect(dto.id, 100);
      expect(dto.mode, 'practice');
      expect(dto.score, 85);
      expect(dto.toDomain(), isA<PracticeAttemptHistoryItem>());
      expect(dto.toDomain().isCompleted, isTrue);
    });

    test('handles string values tolerant', () {
      final dto = PracticeAttemptHistoryDto.fromJson({'id': '101', 'mode': 'standard', 'status': 'in_progress', 'score': '70'});
      expect(dto.id, 101);
      expect(dto.score, 70);
    });

    test('fallback for missing fields', () {
      final dto = PracticeAttemptHistoryDto.fromJson({});
      expect(dto.id, 0);
      expect(dto.mode, 'standard');
      expect(dto.status, 'unknown');
    });
  });

  group('PracticeStartDto', () {
    test('fromJson with attempt_id', () {
      final dto = PracticeStartDto.fromJson({'attempt_id': 55, 'mode': 'practice', 'status': 'in_progress', 'question_count': 10});
      expect(dto.attemptId, '55');
      expect(dto.mode, 'practice');
      expect(dto.questionCount, 10);
    });

    test('handles id fallback', () {
      final dto = PracticeStartDto.fromJson({'id': 60, 'mode': 'practice'});
      expect(dto.attemptId, '60');
    });
  });
}

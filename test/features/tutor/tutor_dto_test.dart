import 'package:bisaasmobile/features/tutor/data/models/tutor_dto.dart';
import 'package:bisaasmobile/features/tutor/domain/entities/tutor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorChatResponseDto', () {
    test('fromJson tolerant — minimal answer', () {
      final dto = TutorChatResponseDto.fromJson({'answer': 'Hello'});
      expect(dto.answer, 'Hello');
      expect(dto.degraded, isFalse);
      expect(dto.sentinel, isNull);
      expect(dto.toDomain(), isA<TutorChatResult>());
      expect(dto.toDomain().answer, 'Hello');
    });

    test('maps response/content/message fallbacks', () {
      expect(TutorChatResponseDto.fromJson({'response': 'R'}).answer, 'R');
      expect(TutorChatResponseDto.fromJson({'content': 'C'}).answer, 'C');
      expect(TutorChatResponseDto.fromJson({'message': 'M'}).answer, 'M');
    });

    test('sentinel NO_DATA and RETRIEVAL_FAILED normalized', () {
      final noData = TutorChatResponseDto.fromJson({'answer': 'x', 'sentinel': 'NO_DATA'});
      expect(noData.sentinel, 'NO_DATA');
      expect(noData.toDomain().isNoData, isTrue);

      final retrieval = TutorChatResponseDto.fromJson({'answer': 'y', 'sentinel': 'RETRIEVAL_FAILED'});
      expect(retrieval.toDomain().isRetrievalFailed, isTrue);

      final degraded = TutorChatResponseDto.fromJson({'answer': 'z', 'degraded': true});
      expect(degraded.degraded, isTrue);
      expect(degraded.toDomain().isDegraded, isTrue);
    });

    test('additive unknown fields ignored', () {
      final dto = TutorChatResponseDto.fromJson({
        'answer': 'hi',
        'new_field': 'ignored',
        'citations': ['a', 'b'],
        'extra': {'nested': 123},
      });
      expect(dto.answer, 'hi');
      expect(dto.citations, ['a', 'b']);
    });

    test('handles degraded flag via is_degraded', () {
      final dto = TutorChatResponseDto.fromJson({'answer': 'x', 'is_degraded': true});
      expect(dto.degraded, isTrue);
    });
  });

  group('TutorPlanDto', () {
    test('fromJson minimal empty', () {
      final dto = TutorPlanDto.fromJson({});
      expect(dto.id, isNotEmpty);
      expect(dto.days, isEmpty);
      expect(dto.toDomain(), isA<TutorPlan>());
    });

    test('fromJson with days tolerant', () {
      final dto = TutorPlanDto.fromJson({
        'id': 'plan-1',
        'title': '6 Month Plan',
        'description': 'PSC Civil',
        'days': [
          {'day_index': 1, 'title': 'Day 1', 'tasks': ['Task A'], 'completed': false},
          {'day_index': 2, 'title': 'Day 2', 'tasks': ['Task B', 'Task C'], 'is_current': true},
        ],
        'current_day': 2,
      });
      expect(dto.id, 'plan-1');
      expect(dto.title, '6 Month Plan');
      expect(dto.days.length, 2);
      expect(dto.days.last.isCurrent, isTrue);
      expect(dto.toDomain().days.length, 2);
      expect(dto.toDomain().currentDayIndex, 2);
    });

    test('handles nested plan key', () {
      final dto = TutorPlanDto.fromJson({
        'plan': {'id': 'p2', 'title': 'Nested', 'days': []},
      });
      expect(dto.id, 'p2');
      expect(dto.title, 'Nested');
    });

    test('additive ignores unknown', () {
      final dto = TutorPlanDto.fromJson({'id': 'x', 'title': 'X', 'future_field': 123, 'another': true});
      expect(dto.id, 'x');
    });
  });

  group('TutorTodayDto', () {
    test('fromJson tolerant with tasks', () {
      final dto = TutorTodayDto.fromJson({
        'date': '2026-08-30T00:00:00Z',
        'title': 'Today',
        'tasks': ['Read chapter 3', 'Solve 5 problems'],
        'completed_count': 1,
        'total_count': 2,
      });
      expect(dto.tasks.length, 2);
      expect(dto.completedCount, 1);
      expect(dto.toDomain().progress, 0.5);
    });

    test('handles today nested', () {
      final dto = TutorTodayDto.fromJson({
        'today': {'title': 'Nested Today', 'tasks': ['a']},
      });
      expect(dto.title, 'Nested Today');
    });
  });

  group('WeakAreaDto', () {
    test('fromJson tolerant minimal', () {
      final dto = WeakAreaDto.fromJson({'topic': 'Soil Mechanics', 'accuracy': 0.42, 'attempts': 5});
      expect(dto.topic, 'Soil Mechanics');
      expect(dto.accuracy, 0.42);
      expect(dto.attempts, 5);
      expect(dto.toDomain(), isA<WeakArea>());
    });

    test('handles string accuracy and missing fields', () {
      final dto = WeakAreaDto.fromJson({'topic': 'RCC', 'accuracy': '0.35'});
      expect(dto.accuracy, 0.35);
      expect(dto.attempts, 0);
    });

    test('additive tolerant', () {
      final dto = WeakAreaDto.fromJson({'topic': 'X', 'new_field': 'ignored'});
      expect(dto.topic, 'X');
    });
  });

  group('ProjectedScoreDto', () {
    test('fromJson score tolerant', () {
      final dto = ProjectedScoreDto.fromJson({'score': 72.5, 'max_score': 100, 'confidence': 0.82, 'trend': 'up'});
      expect(dto.score, 72.5);
      expect(dto.maxScore, 100);
      expect(dto.confidence, 0.82);
      expect(dto.trend, 'up');
      expect(dto.toDomain().percentage, closeTo(72.5, 0.01));
    });

    test('handles string score and nested projected_score', () {
      final dto = ProjectedScoreDto.fromJson({
        'projected_score': {'score': '65', 'max_score': '100'},
      });
      expect(dto.score, 65);
    });

    test('fallback for missing score', () {
      final dto = ProjectedScoreDto.fromJson({});
      expect(dto.score, 0);
    });
  });

  group('WeeklyReportDto', () {
    test('fromJson tolerant', () {
      final dto = WeeklyReportDto.fromJson({
        'week_start': '2026-08-01T00:00:00Z',
        'week_end': '2026-08-07T00:00:00Z',
        'tasks_completed': 5,
        'tasks_planned': 7,
        'average_score': 68.5,
        'summary': 'Good week',
        'insights': ['Insight 1', 'Insight 2'],
      });
      expect(dto.tasksCompleted, 5);
      expect(dto.tasksPlanned, 7);
      expect(dto.averageScore, 68.5);
      expect(dto.insights.length, 2);
      expect(dto.toDomain().completionRate, closeTo(5 / 7, 0.01));
    });
  });

  group('RevisionItemDto', () {
    test('fromJson minimal', () {
      final dto = RevisionItemDto.fromJson({'id': 'r1', 'question_id': 'q1', 'due_at': '2026-08-30T10:00:00Z'});
      expect(dto.id, 'r1');
      expect(dto.questionId, 'q1');
      expect(dto.toDomain(), isA<RevisionItem>());
      expect(dto.toDomain().isOverdue, isA<bool>());
    });

    test('handles camelCase and topic', () {
      final dto = RevisionItemDto.fromJson({'id': 'r2', 'questionId': 'q2', 'dueAt': '2026-08-30T10:00:00Z', 'topic': 'Beam'});
      expect(dto.questionId, 'q2');
      expect(dto.topic, 'Beam');
    });
  });

  group('TutorOnboardingStartDto', () {
    test('fromJson tolerant', () {
      final dto = TutorOnboardingStartDto.fromJson({'session_id': 's123', 'prompt': 'Goal?', 'stage': 'goal'});
      expect(dto.sessionId, 's123');
      expect(dto.prompt, 'Goal?');
      expect(dto.toDomain().sessionId, 's123');
    });

    test('handles camelCase sessionId', () {
      final dto = TutorOnboardingStartDto.fromJson({'sessionId': 'abc', 'message': 'Hi'});
      expect(dto.sessionId, 'abc');
    });
  });
}

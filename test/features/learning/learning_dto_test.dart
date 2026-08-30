import 'package:bisaasmobile/features/learning/data/models/learning_dto.dart';
import 'package:bisaasmobile/features/learning/domain/entities/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningTrackDto', () {
    test('fromJson tolerant minimal', () {
      final dto = LearningTrackDto.fromJson({'id': 1, 'title': 'Civil', 'track_type': 'exam'});
      expect(dto.id, 1);
      expect(dto.title, 'Civil');
      expect(dto.trackType, 'exam');
      expect(dto.toDomain(), isA<LearningTrack>());
      expect(dto.toDomain().name, 'Civil');
    });

    test('handles string id and extra fields tolerant', () {
      final dto = LearningTrackDto.fromJson({'id': '5', 'title': 'X', 'status': 'published', 'syllabus_nodes_count': 3, 'goals_count': 1, 'unknown': 'ignored'});
      expect(dto.id, 5);
      expect(dto.syllabusNodesCount, 3);
      expect(dto.goalsCount, 1);
      expect(dto.status, 'published');
    });

    test('additive unknown does not throw', () {
      final dto = LearningTrackDto.fromJson({'id': 99, 'title': 'Y', 'new_field': {'nested': true}});
      expect(dto.id, 99);
    });

    test('fallback for missing title uses name', () {
      final dto = LearningTrackDto.fromJson({'id': 2, 'name': 'Fallback Title'});
      expect(dto.title, 'Fallback Title');
    });
  });

  group('LearningGoalDto', () {
    test('fromJson minimal with track', () {
      final dto = LearningGoalDto.fromJson({
        'id': 10,
        'track_id': 1,
        'track': {'id': 1, 'title': 'Civil', 'track_type': 'exam'},
        'intensity': 'regular',
        'daily_minutes': 30,
        'status': 'active',
      });
      expect(dto.id, 10);
      expect(dto.trackId, 1);
      expect(dto.track?.title, 'Civil');
      expect(dto.intensity, 'regular');
      expect(dto.dailyMinutes, 30);
      expect(dto.toDomain(), isA<LearningGoal>());
      expect(dto.toDomain().isActive, isTrue);
    });

    test('handles string ids and nulls tolerant', () {
      final dto = LearningGoalDto.fromJson({'id': '11', 'track_id': '2'});
      expect(dto.id, 11);
      expect(dto.trackId, 2);
      expect(dto.status, isNull);
    });

    test('additive ignores new fields', () {
      final dto = LearningGoalDto.fromJson({'id': 12, 'track_id': 1, 'new_future': 123, 'placement_meta': {'a': 1}});
      expect(dto.id, 12);
      expect(dto.placementMeta, {'a': 1});
    });
  });

  group('LearningGoalReadinessDto', () {
    test('fromJson readiness', () {
      final dto = LearningGoalReadinessDto.fromJson({'goal_id': 10, 'readiness': 72, 'topic_count': 12});
      expect(dto.readiness, 72);
      expect(dto.topicCount, 12);
      expect(dto.toDomain().readinessFraction, closeTo(0.72, 0.01));
    });

    test('handles string readiness', () {
      final dto = LearningGoalReadinessDto.fromJson({'goal_id': '10', 'readiness': '85', 'topic_count': '5'});
      expect(dto.readiness, 85);
    });
  });

  group('DailyPlanDto', () {
    test('fromJson with items', () {
      final dto = DailyPlanDto.fromJson({
        'id': 1,
        'goal_id': 10,
        'plan_date': '2026-08-30',
        'items': [
          {'type': 'review', 'id': 1, 'label': 'Review: Atom', 'estimated_minutes': 3, 'completed': false},
          {'type': 'topic', 'id': 2, 'label': 'Study Soil', 'estimated_minutes': 15, 'completed': true},
        ],
        'minutes_budget': 45,
        'status': 'in_progress',
        'completed_items': 1,
      });
      expect(dto.id, 1);
      expect(dto.items.length, 2);
      expect(dto.items.first.type, 'review');
      expect(dto.completedItems, 1);
      expect(dto.toDomain(), isA<DailyPlan>());
      expect(dto.toDomain().progress, closeTo(0.5, 0.01));
    });

    test('handles legacy string tasks', () {
      final dto = DailyPlanDto.fromJson({'id': 2, 'goal_id': 10, 'plan_date': '2026-08-30', 'items': ['Task A', 'Task B']});
      expect(dto.items.length, 2);
      expect(dto.items.first.label, 'Task A');
    });

    test('tolerant to missing fields', () {
      final dto = DailyPlanDto.fromJson({});
      expect(dto.id, 0);
      expect(dto.items, isEmpty);
    });
  });

  group('ReviewItemDto', () {
    test('fromJson minimal', () {
      final dto = ReviewItemDto.fromJson({'id': 1, 'knowledge_atom_id': 100, 'due_at': '2026-08-30T10:00:00Z', 'state': 'learning'});
      expect(dto.id, 1);
      expect(dto.knowledgeAtomId, 100);
      expect(dto.state, 'learning');
      expect(dto.toDomain(), isA<ReviewItem>());
    });

    test('with knowledge_atom nested', () {
      final dto = ReviewItemDto.fromJson({
        'id': 2,
        'knowledge_atom_id': 101,
        'knowledge_atom': {'id': 101, 'title': 'Atom Title', 'content': 'Content'},
        'due_at': '2026-08-30T10:00:00Z',
        'interval_index': 2,
        'lapses': 1,
      });
      expect(dto.knowledgeAtom?.title, 'Atom Title');
      expect(dto.intervalIndex, 2);
      expect(dto.lapses, 1);
    });

    test('handles camelCase', () {
      final dto = ReviewItemDto.fromJson({'id': 3, 'knowledgeAtomId': 102, 'dueAt': '2026-08-30T10:00:00Z'});
      expect(dto.knowledgeAtomId, 102);
    });
  });

  group('LearningTutorReplyDto', () {
    test('fromJson direct reply', () {
      final dto = LearningTutorReplyDto.fromJson({'reply': {'hint': 'Try Socratic', 'worked_example': 'Example', 'confidence': 0.85, 'next_step': 'try_again'}});
      expect(dto.hint, 'Try Socratic');
      expect(dto.confidence, 0.85);
      expect(dto.toDomain(), isA<TutorReply>());
    });

    test('fromJson envelope fallback', () {
      final dto = LearningTutorReplyDto.fromJson({'hint': 'H', 'worked_example': '', 'confidence': '0.7'});
      expect(dto.hint, 'H');
      expect(dto.confidence, 0.7);
    });

    test('handles nested worked_example object', () {
      final dto = LearningTutorReplyDto.fromJson({
        'reply': {
          'hint': 'H',
          'worked_example': {'scenario': 'Scenario', 'steps': [{'description': 'Step 1'}], 'outcome_question': 'Outcome?'},
          'confidence': 0.9,
          'next_step': 'next'
        }
      });
      expect(dto.workedExample, contains('Scenario'));
      expect(dto.workedExample, contains('Step 1'));
    });

    test('additive ignores unknown', () {
      final dto = LearningTutorReplyDto.fromJson({'hint': 'hi', 'new_field': 'ignored', 'extra': 123});
      expect(dto.hint, 'hi');
    });
  });
}

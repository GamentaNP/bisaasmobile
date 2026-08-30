import 'package:bisaasmobile/features/coaching/data/models/coaching_dto.dart';
import 'package:bisaasmobile/features/coaching/domain/entities/coaching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadinessDto', () {
    test('fromJson tolerant minimal', () {
      final dto = ReadinessDto.fromJson('goal-1', {'score': 72, 'level': 'intermediate'});
      expect(dto.goalId, 'goal-1');
      expect(dto.score, 72);
      expect(dto.level, 'intermediate');
      expect(dto.toDomain(), isA<Readiness>());
      expect(dto.toDomain().hasData, isTrue);
      expect(dto.toDomain().percentage, 72);
    });

    test('handles readiness nested and alternative keys', () {
      final dto = ReadinessDto.fromJson('g2', {
        'readiness': {'score': '65.5', 'readiness_level': 'beginner', 'missing_topics': ['Soil', 'RCC']},
      });
      expect(dto.score, 65.5);
      expect(dto.level, 'beginner');
      expect(dto.missingTopics, ['Soil', 'RCC']);
    });

    test('additive ignores unknown', () {
      final dto = ReadinessDto.fromJson('g3', {'score': 10, 'new_field': 'x', 'extra': 123});
      expect(dto.score, 10);
    });

    test('handles missing score as null', () {
      final dto = ReadinessDto.fromJson('g4', {});
      expect(dto.score, isNull);
      expect(dto.toDomain().hasData, isFalse);
      expect(dto.toDomain().percentage, 0);
    });

    test('handles string score and readiness_score key', () {
      final dto = ReadinessDto.fromJson('g5', {'readiness_score': '88.2'});
      expect(dto.score, 88.2);
    });

    test('handles next_steps alternative naming', () {
      final dto = ReadinessDto.fromJson('g6', {
        'score': 50,
        'next_steps': ['Revise soil', 'Do drill'],
      });
      expect(dto.nextSteps, ['Revise soil', 'Do drill']);
    });
  });

  group('CoachingTrackDto', () {
    test('fromJson minimal', () {
      final dto = CoachingTrackDto.fromJson({'id': 'civil', 'slug': 'civil', 'name': 'Civil Engineering'});
      expect(dto.id, 'civil');
      expect(dto.slug, 'civil');
      expect(dto.name, 'Civil Engineering');
      expect(dto.toDomain(), isA<CoachingTrack>());
    });

    test('handles slug fallback for id', () {
      final dto = CoachingTrackDto.fromJson({'slug': 'electrical', 'name': 'Electrical'});
      expect(dto.id, 'electrical');
      expect(dto.slug, 'electrical');
    });

    test('additive tolerant with extra fields', () {
      final dto = CoachingTrackDto.fromJson({'id': 'x', 'slug': 'x', 'name': 'X', 'extra': 'ignored'});
      expect(dto.name, 'X');
    });
  });

  group('CoachingTodayDto', () {
    test('fromJson tolerant with tasks', () {
      final dto = CoachingTodayDto.fromJson({
        'date': '2026-08-30T00:00:00Z',
        'title': 'Today',
        'tasks': ['Task A', 'Task B'],
        'completed_count': 1,
        'total_count': 2,
      });
      expect(dto.tasks.length, 2);
      expect(dto.completedCount, 1);
      expect(dto.toDomain().progress, 0.5);
    });

    test('handles today nested shape', () {
      final dto = CoachingTodayDto.fromJson({
        'today': {'title': 'Nested', 'tasks': ['a']},
      });
      expect(dto.title, 'Nested');
      expect(dto.tasks, ['a']);
    });

    test('handles empty tasks', () {
      final dto = CoachingTodayDto.fromJson({});
      expect(dto.tasks, isEmpty);
      expect(dto.toDomain().progress, 0);
    });

    test('handles string date parsing', () {
      final dto = CoachingTodayDto.fromJson({'date': '2026-08-30T10:00:00Z', 'tasks': []});
      expect(dto.date.year, 2026);
    });
  });

  group('CoachingDashboardData tolerant aggregation', () {
    test('hasAnyData false when all empty', () {
      const data = CoachingDashboardData();
      expect(data.hasAnyData, isFalse);
      expect(data.isDegraded, isFalse);
      expect(data.tracks, isEmpty);
      expect(data.weakAreas, isEmpty);
    });

    test('hasAnyData true when any present', () {
      const data = CoachingDashboardData(
        tracks: [CoachingTrack(id: '1', slug: 'civil', name: 'Civil')],
      );
      expect(data.hasAnyData, isTrue);
    });
  });
}

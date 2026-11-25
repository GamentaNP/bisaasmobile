import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/courses/data/datasources/courses_remote_data_source.dart';
import 'package:bisaasmobile/features/gamification/data/datasources/achievements_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_catalog_remote_data_source.dart';
import '../../integration/support/fake_api.dart';

Dio _dio(FakeApi api) => Dio(BaseOptions(baseUrl: 'https://bisaas.test/api/v1'))
  ..httpClientAdapter = api;

void main() {
  group('catalog data sources', () {
    test('course catalog parses data as a collection and rejects drift',
        () async {
      final api = FakeApi({
        'GET /quiz/courses': FakeRoute.envelope({
          'success': true,
          'data': [
            {'id': 12, 'name': 'Physics', 'description': 'Mechanics'},
          ],
        }),
      });
      final ds = CoursesRemoteDataSource(_dio(api));
      final courses = await ds.getCourses();
      expect(courses.single.title, 'Physics');

      final drift = FakeApi({
        'GET /quiz/courses': FakeRoute.ok({'unexpected': true}),
      });
      await expectLater(
        CoursesRemoteDataSource(_dio(drift)).getCourses(),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('question page sends a cursor, never a page, and reads pagination',
        () async {
      final api = FakeApi({
        'GET /quiz/courses/7/questions': FakeRoute.envelope({
          'success': true,
          'data': {'items': [{'id': 1}, {'id': 2}]},
          'pagination': {
            'type': 'cursor',
            'per_page': 2,
            'count': 2,
            'has_more': true,
            'next_cursor': 'opaque-next',
          },
        }),
      });
      final ds = QuizCatalogRemoteDataSource(_dio(api));
      final page = await ds.getQuestionPage(
        courseId: '7',
        categoryId: '3',
        perPage: 2,
      );
      expect(page.items.length, 2);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'opaque-next');
      expect(api.queryOf(0)['category_id'], 3);
      expect(api.queryOf(0)['per_page'], 2);
      expect(api.queryOf(0).containsKey('page'), isFalse);
      expect(api.queryOf(0).containsKey('cursor'), isFalse);

      final second = FakeApi({
        'GET /quiz/courses/7/questions': FakeRoute.envelope({
          'success': true,
          'data': {'items': []},
          'pagination': {'type': 'cursor', 'has_more': false},
        }),
      });
      await QuizCatalogRemoteDataSource(_dio(second))
          .getQuestionPage(courseId: '7', cursor: 'opaque-next');
      expect(second.queryOf(0)['cursor'], 'opaque-next');
      expect(second.queryOf(0).containsKey('page'), isFalse);
    });

    test('review rows resolve data.answers and unreadable bodies throw',
        () async {
      final api = FakeApi({
        'GET /quiz/attempts/9/results': FakeRoute.ok({
          'answers': [
            {
              'question_text': '2 + 2?',
              'given_answer': '4',
              'is_correct': true,
            },
          ],
        }),
      });
      final ds = QuizCatalogRemoteDataSource(_dio(api));
      final review = await ds.getAttemptReview('9');
      expect(review.entries.single.body, '2 + 2?');
      expect(review.entries.single.isCorrect, isTrue);

      final drift = FakeApi({
        'GET /quiz/attempts/9/results': FakeRoute.ok({'unexpected': true}),
      });
      await expectLater(
        QuizCatalogRemoteDataSource(_dio(drift)).getAttemptReview('9'),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('achievements merge catalog buckets with server progress', () async {
      final api = FakeApi({
        'GET /economy/achievements': FakeRoute.ok({
          'unlocked': [
            {'id': 1, 'name': 'First step', 'rarity': 'rare'},
          ],
          'in_progress': [],
          'locked': [],
        }),
        'GET /me/achievements/progress': FakeRoute.envelope({
          'success': true,
          'data': [
            {'achievement_id': 1, 'progress_current': 5, 'progress_target': 5},
          ],
        }),
        'GET /me/achievements/recent': FakeRoute.envelope({
          'success': true,
          'data': [
            {'achievement_id': 1},
          ],
        }),
      });
      final bundle = await AchievementsRemoteDataSource(_dio(api))
          .fetchAchievements();
      final data = bundle.toDomain();
      expect(data.achievements.single.name, 'First step');
      expect(data.achievements.single.isCompleted, isTrue);
      expect(data.achievements.single.progressCurrent, 5);
      expect(data.recentCount, 1);
    });
  });
}

import 'package:bisaasmobile/features/game/data/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /api/v1/quiz/game/worlds` mixes key conventions: model columns arrive
/// snake_case (`banner_image`, `access_mode`, `quiz_course_id`,
/// `required_stars`) while the computed aggregates are camelCase
/// (`totalStarsEarned`, `totalMaxStars`, `completionPercent`, `currentLevelId`).
/// These tests pin both so a future "cleanup" to one casing cannot silently
/// zero out every world.
void main() {
  group('GameWorldSummaryDto', () {
    test('parses the real /worlds payload (snake columns + camel aggregates)', () {
      final world = GameWorldSummaryDto.fromJson(const {
        'id': 1,
        'name': 'Structural Analysis',
        'slug': 'structural-analysis',
        'banner_image': 'https://cdn.test/banner.png',
        'icon_slug': 'tower',
        'quiz_course_id': 42,
        'access_mode': 'open',
        'required_stars': 0,
        'totalStarsEarned': 12,
        'totalMaxStars': 48,
        'completionPercent': 25,
        'currentLevelId': 7,
      });

      expect(world.id, 1);
      expect(world.name, 'Structural Analysis');
      expect(world.slug, 'structural-analysis');
      expect(world.bannerImage, 'https://cdn.test/banner.png');
      expect(world.iconSlug, 'tower');
      expect(world.quizCourseId, 42);
      expect(world.accessMode, 'open');
      expect(world.requiredStars, 0);
      expect(world.totalStarsEarned, 12);
      expect(world.totalMaxStars, 48);
      expect(world.completionPercent, 25);
      expect(world.currentLevelId, 7);
      expect(world.isUnlocked, isTrue);
    });

    test('also accepts the camelCase spelling used by the /map payload', () {
      final world = GameWorldSummaryDto.fromJson(const {
        'id': 2,
        'slug': 'fluid-mechanics',
        'accessMode': 'stars_required',
        'requiredStars': 30,
        'bannerImage': 'https://cdn.test/b.png',
        'iconSlug': 'drop',
        'quizCourseId': 7,
        'totalStarsEarned': 12,
        'totalMaxStars': 48,
        'completionPercent': 25,
      });

      expect(world.accessMode, 'stars_required');
      expect(world.requiredStars, 30);
      expect(world.bannerImage, 'https://cdn.test/b.png');
      expect(world.quizCourseId, 7);
    });

    test('isUnlocked respects a stars gate', () {
      GameWorldSummaryDto gate(int required, int earned) => GameWorldSummaryDto.fromJson({
            'id': 1,
            'slug': 'w',
            'access_mode': 'stars_required',
            'required_stars': required,
            'totalStarsEarned': earned,
          });

      expect(gate(30, 12).isUnlocked, isFalse);
      expect(gate(30, 30).isUnlocked, isTrue);
      expect(gate(30, 44).isUnlocked, isTrue);
    });

    test('plan_required worlds are never unlocked client-side', () {
      final world = GameWorldSummaryDto.fromJson(const {
        'id': 3,
        'slug': 'premium',
        'access_mode': 'plan_required',
        'totalStarsEarned': 999,
      });
      expect(world.isUnlocked, isFalse);
    });

    test('tolerates a near-empty object without throwing', () {
      final world = GameWorldSummaryDto.fromJson(const {});
      expect(world.id, 0);
      expect(world.name, 'World');
      expect(world.slug, '');
      expect(world.totalStarsEarned, 0);
      expect(world.quizCourseId, isNull);
    });
  });

  group('GameWorldMapDto', () {
    test('merges top-level aggregates onto the embedded world', () {
      // GameWorldMapService puts `world` (model columns, camelCase in the map
      // payload) alongside the computed totals at the top level.
      final map = GameWorldMapDto.fromJson(const {
        'world': {
          'id': 5,
          'name': 'RCC Design',
          'slug': 'rcc-design',
          'accessMode': 'open',
          'unlockCostCoins': 0,
        },
        'chapters': [
          {
            'id': 11,
            'name': 'Chapter 1',
            'slug': 'chapter-1',
            'sortOrder': 1,
            'starUnlockThreshold': 0,
            'isUnlocked': true,
            'userStars': 6,
            'maxStars': 24,
            'levels': [
              {
                'id': 101,
                'levelNumber': 1,
                'chapterPosition': 1,
                'status': 'completed',
                'isUnlocked': true,
                'isCurrent': false,
                'starsEarned': 3,
                'xpReward': 20,
                'coinReward': 5,
                'questionCount': 10,
                'isBoss': false,
              },
              {
                'id': 102,
                'levelNumber': 2,
                'chapterPosition': 2,
                'status': 'unlocked',
                'isUnlocked': true,
                'isCurrent': true,
                'starsEarned': 0,
                'xpReward': 20,
                'coinReward': 5,
                'questionCount': 10,
                'isBoss': false,
                'difficultyBand': 'medium',
                'timeLimitSeconds': 90,
              },
            ],
          },
        ],
        'currentLevelId': 102,
        'totalStarsEarned': 6,
        'totalMaxStars': 24,
        'completionPercent': 25,
      });

      expect(map.world.id, 5);
      expect(map.world.name, 'RCC Design');
      // Aggregates lifted from the top level onto the world summary.
      expect(map.world.totalStarsEarned, 6);
      expect(map.world.totalMaxStars, 24);
      expect(map.world.completionPercent, 25);
      expect(map.world.currentLevelId, 102);

      expect(map.chapters, hasLength(1));
      final chapter = map.chapters.first;
      expect(chapter.userStars, 6);
      expect(chapter.maxStars, 24);
      expect(chapter.isUnlocked, isTrue);
      expect(chapter.levels, hasLength(2));

      final first = chapter.levels.first;
      expect(first.levelNumber, 1);
      expect(first.status, 'completed');
      expect(first.isCompleted, isTrue);
      expect(first.isLocked, isFalse);
      expect(first.starsEarned, 3);
      expect(first.xpReward, 20);
      expect(first.coinReward, 5);
      expect(first.questionCount, 10);

      final second = chapter.levels[1];
      expect(second.isCurrent, isTrue);
      expect(second.difficultyBand, 'medium');
      expect(second.timeLimitSeconds, 90);
      expect(second.isCompleted, isFalse);
    });

    test('a locked level reads as locked and carries no invented rewards', () {
      final map = GameWorldMapDto.fromJson(const {
        'world': {'id': 1, 'slug': 'w'},
        'chapters': [
          {
            'id': 1,
            'name': 'C',
            'slug': 'c',
            'levels': [
              {'id': 9, 'levelNumber': 5, 'status': 'locked', 'isUnlocked': false},
            ],
          },
        ],
      });
      final level = map.chapters.first.levels.first;
      expect(level.isLocked, isTrue);
      expect(level.isCompleted, isFalse);
      // Absent server fields must stay at zero, never a fabricated reward.
      expect(level.xpReward, 0);
      expect(level.coinReward, 0);
      expect(level.questionCount, 0);
      expect(level.starsEarned, 0);
    });

    test('tolerates a missing chapters array', () {
      final map = GameWorldMapDto.fromJson(const {'world': {'id': 1, 'slug': 'w'}});
      expect(map.chapters, isEmpty);
      expect(map.totalStarsEarned, 0);
    });
  });
}

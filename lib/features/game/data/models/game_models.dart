// ignore_for_file: cast_nullable_to_non_nullable

/// Game World Map DTOs — faithfully mirrors the Laravel GameWorldMapService response.
///
/// Endpoint shapes:
///   GET /api/v1/quiz/game/worlds       → {worlds: [GameWorldSummaryDto]}
///   GET /api/v1/quiz/game/world/{slug}/map → GameWorldMapDto
library;

/// Lightweight world entry from `GET /api/v1/quiz/game/worlds`.
class GameWorldSummaryDto {
  const GameWorldSummaryDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.accessMode,
    required this.totalStarsEarned,
    required this.totalMaxStars,
    required this.completionPercent,
    this.bannerImage,
    this.iconSlug,
    this.quizCourseId,
    this.currentLevelId,
    this.requiredStars = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String accessMode; // 'free' | 'premium' | 'coins'
  final int totalStarsEarned;
  final int totalMaxStars;
  final int completionPercent;
  final String? bannerImage;
  final String? iconSlug;
  final int? quizCourseId;
  final int? currentLevelId;
  final int requiredStars;

  factory GameWorldSummaryDto.fromJson(Map<String, dynamic> j) =>
      GameWorldSummaryDto(
        id: (j['id'] ?? 0) as int,
        name: (j['name'] ?? 'World').toString(),
        slug: (j['slug'] ?? '').toString(),
        accessMode: (j['access_mode'] ?? 'free').toString(),
        totalStarsEarned: (j['totalStarsEarned'] as num?)?.toInt() ?? 0,
        totalMaxStars: (j['totalMaxStars'] as num?)?.toInt() ?? 0,
        completionPercent: (j['completionPercent'] as num?)?.toInt() ?? 0,
        bannerImage: j['banner_image'] as String?,
        iconSlug: j['icon_slug'] as String?,
        quizCourseId: j['quiz_course_id'] as int?,
        currentLevelId: j['currentLevelId'] as int?,
        requiredStars: (j['required_stars'] as num?)?.toInt() ?? 0,
      );
}

/// Full world map from `GET /api/v1/quiz/game/world/{slug}/map`.
class GameWorldMapDto {
  const GameWorldMapDto({
    required this.world,
    required this.chapters,
    required this.totalStarsEarned,
    required this.totalMaxStars,
    required this.completionPercent,
    this.currentLevelId,
  });

  final GameWorldSummaryDto world;
  final List<GameChapterDto> chapters;
  final int totalStarsEarned;
  final int totalMaxStars;
  final int completionPercent;
  final int? currentLevelId;

  factory GameWorldMapDto.fromJson(Map<String, dynamic> j) {
    final worldRaw = j['world'] as Map<String, dynamic>? ?? {};
    // Merge top-level star fields into world summary
    final worldWithStars = {
      ...worldRaw,
      'totalStarsEarned': j['totalStarsEarned'] ?? 0,
      'totalMaxStars': j['totalMaxStars'] ?? 0,
      'completionPercent': j['completionPercent'] ?? 0,
      'currentLevelId': j['currentLevelId'],
    };
    return GameWorldMapDto(
      world: GameWorldSummaryDto.fromJson(worldWithStars),
      chapters: (j['chapters'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(GameChapterDto.fromJson)
          .toList(),
      totalStarsEarned: (j['totalStarsEarned'] as num?)?.toInt() ?? 0,
      totalMaxStars: (j['totalMaxStars'] as num?)?.toInt() ?? 0,
      completionPercent: (j['completionPercent'] as num?)?.toInt() ?? 0,
      currentLevelId: j['currentLevelId'] as int?,
    );
  }
}

class GameChapterDto {
  const GameChapterDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.starUnlockThreshold,
    required this.isUnlocked,
    required this.userStars,
    required this.maxStars,
    required this.levels,
    this.description,
    this.narrativeText,
    this.bannerImage,
  });

  final int id;
  final String name;
  final String slug;
  final int sortOrder;
  final int starUnlockThreshold;
  final bool isUnlocked;
  final int userStars;
  final int maxStars;
  final List<GameLevelDto> levels;
  final String? description;
  final String? narrativeText;
  final String? bannerImage;

  factory GameChapterDto.fromJson(Map<String, dynamic> j) => GameChapterDto(
        id: (j['id'] ?? 0) as int,
        name: (j['name'] ?? 'Chapter').toString(),
        slug: (j['slug'] ?? '').toString(),
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? (j['sort_order'] as num?)?.toInt() ?? 0,
        starUnlockThreshold: (j['starUnlockThreshold'] as num?)?.toInt() ??
            (j['star_unlock_threshold'] as num?)?.toInt() ?? 0,
        isUnlocked: j['isUnlocked'] as bool? ?? false,
        userStars: (j['userStars'] as num?)?.toInt() ?? 0,
        maxStars: (j['maxStars'] as num?)?.toInt() ?? 0,
        levels: (j['levels'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(GameLevelDto.fromJson)
            .toList(),
        description: j['description'] as String?,
        narrativeText: j['narrativeText'] as String? ?? j['narrative_text'] as String?,
        bannerImage: j['bannerImage'] as String? ?? j['banner_image'] as String?,
      );
}

class GameLevelDto {
  const GameLevelDto({
    required this.id,
    required this.levelNumber,
    required this.chapterPosition,
    required this.status,
    required this.isUnlocked,
    required this.isCurrent,
    required this.starsEarned,
    required this.xpReward,
    required this.coinReward,
    required this.questionCount,
    required this.isBoss,
    this.title,
    this.description,
    this.bestScore,
    this.bestAccuracyPct,
    this.bestTimeSeconds,
    this.difficultyBand,
    this.timeLimitSeconds,
  });

  final int id;
  final int levelNumber;
  final int chapterPosition;
  final String status; // 'completed' | 'unlocked' | 'locked'
  final bool isUnlocked;
  final bool isCurrent;
  final int starsEarned;
  final int xpReward;
  final int coinReward;
  final int questionCount;
  final bool isBoss;
  final String? title;
  final String? description;
  final double? bestScore;
  final double? bestAccuracyPct;
  final int? bestTimeSeconds;
  final String? difficultyBand;
  final int? timeLimitSeconds;

  bool get isCompleted => status == 'completed';
  bool get isLocked => status == 'locked';

  factory GameLevelDto.fromJson(Map<String, dynamic> j) => GameLevelDto(
        id: (j['id'] ?? 0) as int,
        levelNumber: (j['levelNumber'] as num?)?.toInt() ?? (j['level_number'] as num?)?.toInt() ?? 0,
        chapterPosition: (j['chapterPosition'] as num?)?.toInt() ?? (j['chapter_position'] as num?)?.toInt() ?? 0,
        status: (j['status'] ?? 'locked').toString(),
        isUnlocked: j['isUnlocked'] as bool? ?? false,
        isCurrent: j['isCurrent'] as bool? ?? false,
        starsEarned: (j['starsEarned'] as num?)?.toInt() ?? 0,
        xpReward: (j['xpReward'] as num?)?.toInt() ?? 0,
        coinReward: (j['coinReward'] as num?)?.toInt() ?? 0,
        questionCount: (j['questionCount'] as num?)?.toInt() ?? 0,
        isBoss: j['isBoss'] as bool? ?? false,
        title: j['title'] as String?,
        description: j['description'] as String?,
        bestScore: (j['bestScore'] as num?)?.toDouble(),
        bestAccuracyPct: (j['bestAccuracyPct'] as num?)?.toDouble(),
        bestTimeSeconds: j['bestTimeSeconds'] as int?,
        difficultyBand: j['difficultyBand'] as String?,
        timeLimitSeconds: j['timeLimitSeconds'] as int?,
      );
}

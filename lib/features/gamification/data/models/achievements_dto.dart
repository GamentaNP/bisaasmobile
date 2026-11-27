import 'package:bisaasmobile/shared/utils/wire_coercion.dart';
import '../../../../core/network/api_failure.dart';
import '../../domain/entities/achievements.dart';

/// Wire shapes behind the three achievement endpoints.
///
/// The catalog is an object with three frozen buckets (`unlocked`,
/// `in_progress`, `locked`); progress and recent are ordinary collections.
/// A catalog object with none of those buckets is a shape we do not understand
/// and throws [ContractViolation] rather than showing "no badges".
class AchievementCatalogDto {
  const AchievementCatalogDto(this.buckets);

  final Map<String, List<Map<String, dynamic>>> buckets;

  static const endpoint = '/economy/achievements';

  factory AchievementCatalogDto.fromJson(Map<String, dynamic> data) {
    final buckets = <String, List<Map<String, dynamic>>>{};
    for (final key in const ['unlocked', 'in_progress', 'locked']) {
      final raw = data[key];
      if (raw == null) continue;
      if (raw is! List) {
        throw ContractViolation(
          'Expected `$key` to be a list',
          endpoint: endpoint,
        );
      }
      buckets[key] = raw.whereType<Map<String, dynamic>>().toList();
    }
    if (buckets.isEmpty) {
      throw const ContractViolation(
        'Achievement catalog payload not understood',
        endpoint: endpoint,
      );
    }
    return AchievementCatalogDto(buckets);
  }
}

class AchievementProgressDto {
  const AchievementProgressDto({
    required this.achievementId,
    required this.isCompleted,
    required this.progressCurrent,
    required this.progressTarget,
    this.key,
    this.name,
    this.completedAt,
  });

  final int achievementId;
  final bool isCompleted;
  final int progressCurrent;
  final int progressTarget;
  final String? key;
  final String? name;
  final String? completedAt;

  factory AchievementProgressDto.fromJson(Map<String, dynamic> j) {
    return AchievementProgressDto(
      achievementId: wireIntOrZero(j['achievement_id']),
      isCompleted: _asBool(j['is_completed']),
      progressCurrent: wireIntOrZero(j['progress_current']),
      progressTarget: wireIntOrZero(j['progress_target']),
      key: j['key']?.toString(),
      name: j['name']?.toString(),
      completedAt: j['completed_at']?.toString(),
    );
  }
}

/// Merges the catalog buckets with the per-user progress rows into the shape
/// the UI renders. The merge is a client-side join of two server payloads — it
/// does not invent completion or counters.
class AchievementsBundleDto {
  const AchievementsBundleDto({
    required this.catalog,
    required this.progress,
    required this.recentCount,
  });

  final AchievementCatalogDto catalog;
  final List<AchievementProgressDto> progress;
  final int recentCount;

  AchievementsData toDomain() {
    final progressMap = <int, AchievementProgressDto>{
      for (final p in progress) if (p.achievementId != 0) p.achievementId: p,
    };

    final achievements = <AchievementEntry>[];
    for (final bucket in const ['unlocked', 'in_progress', 'locked']) {
      final rows = catalog.buckets[bucket] ?? const <Map<String, dynamic>>[];
      for (final item in rows) {
        // The `unlocked` bucket nests the catalog row under `achievement`
        // (server userAchievementPayload), other buckets are flat.
        final nested = item['achievement'];
        final source = nested is Map<String, dynamic> ? nested : item;
        final id = wireIntOrZero(
          source['id'] ?? item['achievement_id'] ?? item['id'],
        );
        final p = progressMap[id];
        achievements.add(
          AchievementEntry(
            id: id,
            key: (source['key'] ?? item['key'] ?? '').toString(),
            name: (source['name'] ?? item['name'] ?? 'Achievement').toString(),
            rarity: (source['rarity'] ?? item['rarity'] ?? 'common').toString(),
            isCompleted: bucket == 'unlocked' || (p?.isCompleted ?? false),
            progressCurrent: p?.progressCurrent ?? 0,
            progressTarget: p?.progressTarget ?? 1,
            completedAt: item['completed_at']?.toString() ?? p?.completedAt,
          ),
        );
      }
    }

    return AchievementsData(
      achievements: achievements,
      recentCount: recentCount,
    );
  }
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/public_profile.dart';

/// Wire DTOs for `/quiz/profiles/{username}` and `/quiz/profiles/compare`.
///
/// Only the sections the UI renders are typed; additive fields are ignored.
/// A malformed required section throws contract drift rather than rendering
/// an empty profile.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Object?> list(Object? value, String key, String endpoint) {
    if (value is List) return value;
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static int intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num numOf(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String requiredString(Object? value, String key, String endpoint) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A profile has no $key', endpoint: endpoint);
    }
    return text;
  }

  static String? nullableString(Object? value) => value?.toString();
}

class PublicProfileDto {
  const PublicProfileDto({required this.data});
  final Map<String, dynamic> data;

  factory PublicProfileDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/profiles/{username}',
  }) {
    _Parse.map(data['profile'], 'profile', endpoint);
    _Parse.map(data['stats'], 'stats', endpoint);
    final achievements = data['recent_achievements'];
    if (achievements != null) {
      _Parse.list(achievements, 'recent_achievements', endpoint);
    }
    return PublicProfileDto(data: data);
  }

  PublicProfileSnapshot toDomain({String endpoint = '/quiz/profiles/{username}'}) {
    final rawProfile = _Parse.map(data['profile'], 'profile', endpoint);
    final rawStats = _Parse.map(data['stats'], 'stats', endpoint);
    final reputation = data['reputation'];
    final reputationMap = reputation is Map<String, dynamic> ? reputation : null;

    return PublicProfileSnapshot(
      profile: ProfileCardData(
        username: _Parse.requiredString(rawProfile['username'], 'username', endpoint),
        name: _Parse.requiredString(
          rawProfile['name'] ?? rawProfile['display_name'],
          'name',
          endpoint,
        ),
        headline: _Parse.nullableString(rawProfile['headline']),
        bio: _Parse.nullableString(rawProfile['bio']),
        avatarUrl: _Parse.nullableString(rawProfile['avatar_url']),
        level: _Parse.intOf(rawProfile['level']),
        isOwner: rawProfile['is_owner'] == true,
        isPublic: rawProfile['is_public'] != false,
      ),
      stats: ProfileStatsData(
        totalQuizzes: _Parse.numOf(rawStats['total_quizzes']),
        completedQuizzes: _Parse.numOf(rawStats['completed_quizzes']),
        totalBattles: _Parse.numOf(rawStats['total_battles']),
        averageScore: _Parse.numOf(rawStats['average_score']),
        accuracyPercent: _Parse.numOf(rawStats['accuracy_percent']),
      ),
      reputationScore: reputationMap == null
          ? null
          : _Parse.numOf(reputationMap['score']),
      reputationTier: reputationMap == null
          ? null
          : _Parse.nullableString(reputationMap['tier']),
      recentAchievements: (data['recent_achievements'] is List
              ? (data['recent_achievements'] as List).whereType<Map<String, dynamic>>()
              : const <Map<String, dynamic>>[])
          .map((a) => ProfileAchievementData(
                name: _Parse.requiredString(a['name'], 'name', endpoint),
                iconUrl: _Parse.nullableString(a['icon_url']),
                rarity: _Parse.nullableString(a['rarity']),
                rewardCoins: _Parse.intOf(a['reward_coins']),
                completedAt: _Parse.nullableString(a['completed_at']),
              ))
          .toList(),
    );
  }
}

class ProfileComparisonDto {
  const ProfileComparisonDto({required this.data});
  final Map<String, dynamic> data;

  factory ProfileComparisonDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/profiles/compare',
  }) {
    _Parse.map(data['viewer'], 'viewer', endpoint);
    _Parse.map(data['target'], 'target', endpoint);
    final comparison = _Parse.map(data['comparison'], 'comparison', endpoint);
    _Parse.list(comparison['rows'], 'comparison.rows', endpoint);
    return ProfileComparisonDto(data: data);
  }

  ProfileComparison toDomain({String endpoint = '/quiz/profiles/compare'}) {
    final comparison = _Parse.map(data['comparison'], 'comparison', endpoint);
    CompactProfile compact(Object? value) {
      final j = _Parse.map(value, 'profile', endpoint);
      return CompactProfile(
        username: _Parse.requiredString(j['username'], 'username', endpoint),
        name: _Parse.requiredString(j['name'], 'name', endpoint),
        avatarUrl: _Parse.nullableString(j['avatar_url']),
        level: _Parse.intOf(j['level']),
        totalXp: _Parse.numOf(j['total_xp']),
      );
    }

    return ProfileComparison(
      viewer: compact(data['viewer']),
      target: compact(data['target']),
      rows: _Parse.list(comparison['rows'], 'comparison.rows', endpoint)
          .whereType<Map<String, dynamic>>()
          .map((row) => ComparisonRow(
                label: _Parse.requiredString(row['label'], 'label', endpoint),
                viewer: row['viewer'],
                target: row['target'],
                suffix: _Parse.nullableString(row['suffix']),
              ))
          .toList(),
    );
  }
}

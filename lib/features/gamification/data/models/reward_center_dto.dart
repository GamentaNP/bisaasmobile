import '../../../../core/network/api_failure.dart';
import '../../domain/entities/reward_center.dart';

/// Wire DTO for `GET /reward-center`.
///
/// A missing check_in/spin object or a malformed achievements list is drift;
/// only a genuinely empty achievements list yields an empty section.
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

  static String requiredString(Object? value, String key, String endpoint) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A reward-center row has no $key', endpoint: endpoint);
    }
    return text;
  }

  static String? nullableString(Object? value) => value?.toString();
}

class RewardCenterDto {
  const RewardCenterDto({required this.data});
  final Map<String, dynamic> data;

  factory RewardCenterDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/reward-center',
  }) {
    _Parse.map(data['check_in'], 'check_in', endpoint);
    _Parse.map(data['spin'], 'spin', endpoint);
    final achievements = data['recent_achievements'];
    if (achievements != null) {
      _Parse.list(achievements, 'recent_achievements', endpoint);
    }
    return RewardCenterDto(data: data);
  }

  RewardCenterSnapshot toDomain({String endpoint = '/reward-center'}) {
    final checkIn = _Parse.map(data['check_in'], 'check_in', endpoint);
    final spin = _Parse.map(data['spin'], 'spin', endpoint);

    return RewardCenterSnapshot(
      checkIn: CheckInStatusData(
        claimedToday: checkIn['claimed_today'] == true,
        streakDay: _Parse.intOf(checkIn['streak_day']),
        todayReward: _Parse.intOf(checkIn['today_reward']),
        nextReward: _Parse.intOf(checkIn['next_reward']),
      ),
      spin: SpinStatusData(
        canSpin: spin['can_spin'] == true,
        nextSpinAt: _Parse.nullableString(spin['next_spin_at']),
        prizes: (spin['prizes'] is List
                ? (spin['prizes'] as List).whereType<Map<String, dynamic>>()
                : const <Map<String, dynamic>>[])
            .map((p) => SpinPrizeData(
                  label: _Parse.requiredString(p['label'], 'label', endpoint),
                  type: _Parse.nullableString(p['type']),
                  coins: _Parse.intOf(p['coins']),
                  xp: _Parse.intOf(p['xp']),
                  lifelineSlug: _Parse.nullableString(p['lifeline_slug']),
                  lifelineQuantity: _Parse.intOf(p['lifeline_quantity']),
                  colorHex: _Parse.nullableString(p['color_hex']),
                  rarity: _Parse.nullableString(p['rarity']),
                ))
            .toList(),
      ),
      balance: _Parse.intOf(data['balance']),
      recentAchievements: (data['recent_achievements'] is List
              ? (data['recent_achievements'] as List).whereType<Map<String, dynamic>>()
              : const <Map<String, dynamic>>[])
          .map((a) => RewardAchievementData(
                key: _Parse.requiredString(a['key'], 'key', endpoint),
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

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/impact_leaders.dart';

/// Wire DTO for `GET /social/impact-leaders`.
///
/// A wrong `leaders` type is drift; an empty list is the only valid way to
/// render "no leaders".
abstract final class _Parse {
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
      throw ContractViolation('An impact leader has no $key', endpoint: endpoint);
    }
    return text;
  }
}

class ImpactLeadersDto {
  const ImpactLeadersDto({required this.data});
  final Map<String, dynamic> data;

  factory ImpactLeadersDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/social/impact-leaders',
  }) {
    _Parse.list(data['leaders'], 'leaders', endpoint);
    return ImpactLeadersDto(data: data);
  }

  ImpactLeadersSnapshot toDomain({String endpoint = '/social/impact-leaders'}) =>
      ImpactLeadersSnapshot(
        leaders: _Parse.list(data['leaders'], 'leaders', endpoint)
            .whereType<Map<String, dynamic>>()
            .map((j) => ImpactLeader(
                  userId: _Parse.intOf(j['user_id']),
                  name: _Parse.requiredString(j['name'], 'name', endpoint),
                  score: _Parse.intOf(j['score']),
                  qualifiedReferrals: _Parse.intOf(j['qualified_referrals']),
                ))
            .toList(),
        viewerRank: data['viewer_rank'] is int
            ? data['viewer_rank'] as int
            : null,
      );
}

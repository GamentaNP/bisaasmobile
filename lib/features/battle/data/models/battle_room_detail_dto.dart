import '../../../../core/network/api_failure.dart';
import '../../domain/entities/battle_room_detail.dart';

/// Strict wire parser for the participant-only lobby detail (§9.5).
///
/// Only the documented safe fields are read. `question_ids`, settlement
/// snapshots and any other future key are ignored rather than copied into the
/// entity — a drift that removes a required field still throws.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> rows(
    Object? value,
    String key,
    String endpoint,
  ) {
    if (value is! List) {
      throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
    }
    return value.map((row) => map(row, '$key row', endpoint)).toList();
  }

  static int intOf(Object? value, String key, String endpoint) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation('Expected $key to be an int', endpoint: endpoint);
  }

  static int? optionalInt(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation(
      'Expected $key to be an int or null',
      endpoint: endpoint,
    );
  }

  static String string(Object? value, String key, String endpoint) {
    if (value is String && value.isNotEmpty) return value;
    throw ContractViolation('Expected $key to be a string', endpoint: endpoint);
  }

  static String? optionalString(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      'Expected $key to be a string or null',
      endpoint: endpoint,
    );
  }

  static bool boolOf(Object? value, String key, String endpoint) {
    if (value is bool) return value;
    throw ContractViolation('Expected $key to be a bool', endpoint: endpoint);
  }
}

class BattleRoomDetailDto {
  const BattleRoomDetailDto({required this.data});
  final Map<String, dynamic> data;

  factory BattleRoomDetailDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/battle-rooms/{lobby}',
  }) {
    final lobby = _Parse.map(data['lobby'], 'lobby', endpoint);
    _Parse.intOf(lobby['id'], 'lobby.id', endpoint);
    _Parse.string(lobby['code'], 'lobby.code', endpoint);
    final host = _Parse.map(lobby['host'], 'lobby.host', endpoint);
    _Parse.intOf(host['id'], 'lobby.host.id', endpoint);
    _Parse.rows(lobby['participants'], 'lobby.participants', endpoint);
    _Parse.intOf(lobby['wager_coins'], 'lobby.wager_coins', endpoint);
    return BattleRoomDetailDto(data: data);
  }

  BattleRoomDetail toDomain({String endpoint = '/quiz/battle-rooms/{lobby}'}) {
    final lobby = _Parse.map(data['lobby'], 'lobby', endpoint);
    final host = _Parse.map(lobby['host'], 'lobby.host', endpoint);

    return BattleRoomDetail(
      lobby: BattleRoomLobby(
        id: _Parse.intOf(lobby['id'], 'lobby.id', endpoint),
        code: _Parse.string(lobby['code'], 'lobby.code', endpoint),
        host: BattleRoomMember(
          id: _Parse.intOf(host['id'], 'lobby.host.id', endpoint),
          name: _Parse.optionalString(host['name'], 'lobby.host.name', endpoint),
        ),
        participants: _Parse.rows(lobby['participants'], 'lobby.participants', endpoint)
            .map((row) => BattleRoomParticipant(
                  id: _Parse.intOf(row['id'], 'participants.id', endpoint),
                  userId: _Parse.intOf(row['user_id'], 'participants.user_id', endpoint),
                  userName: _Parse.optionalString(
                    row['user_name'],
                    'participants.user_name',
                    endpoint,
                  ),
                  score: _Parse.optionalInt(row['score'], 'participants.score', endpoint) ?? 0,
                  rank: _Parse.optionalInt(row['rank'], 'participants.rank', endpoint),
                  isSpectating: _Parse.boolOf(
                    row['is_spectating'],
                    'participants.is_spectating',
                    endpoint,
                  ),
                  joinedAt: _Parse.optionalString(
                    row['joined_at'],
                    'participants.joined_at',
                    endpoint,
                  ),
                  evictedAt: _Parse.optionalString(
                    row['evicted_at'],
                    'participants.evicted_at',
                    endpoint,
                  ),
                ))
            .toList(),
        mode: _Parse.optionalString(lobby['mode'], 'lobby.mode', endpoint),
        queueType: _Parse.optionalString(lobby['queue_type'], 'lobby.queue_type', endpoint),
        status: _Parse.optionalString(lobby['status'], 'lobby.status', endpoint),
        wagerCoins: _Parse.intOf(lobby['wager_coins'], 'lobby.wager_coins', endpoint),
        maxPlayers: _Parse.optionalInt(lobby['max_players'], 'lobby.max_players', endpoint),
        startedAt: _Parse.optionalString(lobby['started_at'], 'lobby.started_at', endpoint),
        finishedAt: _Parse.optionalString(lobby['finished_at'], 'lobby.finished_at', endpoint),
        scheduledFor: _Parse.optionalString(
          lobby['scheduled_for'],
          'lobby.scheduled_for',
          endpoint,
        ),
      ),
    );
  }
}

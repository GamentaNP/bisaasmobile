/// Data source for `GET /quiz/battle-rooms/{lobby}` (§9.5).
///
/// Host/participant/admin only — the server 403s anyone else. This is a read:
/// no join, start, heartbeat or settlement mutation is issued from here.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/battle_room_detail.dart';
import '../models/battle_room_detail_dto.dart';

class BattleRoomDetailRemoteDataSource {
  const BattleRoomDetailRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/battle-rooms';

  Future<BattleRoomDetail> getLobby(String lobbyId) async {
    if (int.tryParse(lobbyId) == null) {
      throw ContractViolation(
        'A battle lobby id must be numeric',
        endpoint: endpoint,
      );
    }
    final path = '$endpoint/$lobbyId';
    final res = await _dio.get<Map<String, dynamic>>(path);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: path);
    }
    return BattleRoomDetailDto.fromJson(
      requireDataMap(body, endpoint: path),
      endpoint: path,
    ).toDomain(endpoint: path);
  }
}

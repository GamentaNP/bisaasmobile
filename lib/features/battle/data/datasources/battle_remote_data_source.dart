import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';

class BattleRemoteDataSource {
  const BattleRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getFirebaseToken() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/firebase-token');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> findMatch({String? category}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/battles/match',
      data: category != null ? {'category': category} : null,
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>? ?? {'id': 'demo', 'status': 'searching'};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/leaderboards/$id');
    final body = res.data!;
    if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
    final envelope = ApiResponse.fromJson(body, (json) => (json as List?)?.cast<Map<String, dynamic>>() ?? []);
    return envelope.data ?? [];
  }
}

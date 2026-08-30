// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable, omit_local_variable_types, unnecessary_cast

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/live_event_dto.dart';

/// Verified routes:
/// GET /quiz/live-events, GET /quiz/live-events/{event},
/// POST /quiz/live-events/{event}/register, DELETE register,
/// POST /quiz/live-events/{event}/check-in, GET /snapshot, POST /answers
class LiveEventsRemoteDataSource {
  const LiveEventsRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<List<LiveEventDto>> getLiveEvents({int limit = 25}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/live-events',
      queryParameters: {'limit': limit},
    );
    final body = res.data;
    if (body == null) return [];
    List<Map<String, dynamic>> raw = [];
    final data = body['data'];
    if (data is Map<String, dynamic> && data['events'] is List) {
      raw = (data['events'] as List).cast<Map<String, dynamic>>();
    } else if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (body['events'] is List) {
      raw = (body['events'] as List).cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is Map<String, dynamic> && json['events'] is List) {
            return (json['events'] as List).cast<Map<String, dynamic>>();
          }
          if (json is List) return (json as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
      } catch (_) {}
    }
    return raw.map(LiveEventDto.fromJson).toList();
  }

  Future<LiveEventDetailDto> getLiveEvent(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/live-events/$id');
    final body = res.data;
    if (body == null) throw Exception('Live event $id not found');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Live event data missing');
    return LiveEventDetailDto.fromJson(data);
  }

  Future<LiveEventParticipantDto> register(int eventId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/live-events/$eventId/register',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Register empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      final d = body['data'] as Map<String, dynamic>;
      // Could be {participant: {...}} or participant directly
      if (d['participant'] is Map<String, dynamic>) {
        data = d['participant'] as Map<String, dynamic>;
      } else {
        data = d;
      }
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        final d = env.data;
        if (d != null && d['participant'] is Map<String, dynamic>) {
          data = d['participant'] as Map<String, dynamic>;
        } else {
          data = d;
        }
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Participant missing');
    return LiveEventParticipantDto.fromJson(data);
  }

  Future<void> unregister(int eventId) async {
    await _dio.delete<Map<String, dynamic>>('/quiz/live-events/$eventId/register');
  }

  Future<LiveEventParticipantDto> checkIn(int eventId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/live-events/$eventId/check-in',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Check-in empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      final d = body['data'] as Map<String, dynamic>;
      if (d['participant'] is Map<String, dynamic>) {
        data = d['participant'] as Map<String, dynamic>;
      } else {
        data = d;
      }
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        final d = env.data;
        if (d != null && d['participant'] is Map<String, dynamic>) {
          data = d['participant'] as Map<String, dynamic>;
        } else {
          data = d;
        }
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Participant missing');
    return LiveEventParticipantDto.fromJson(data);
  }

  Future<LiveEventSnapshotDto> getSnapshot(int eventId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/live-events/$eventId/snapshot');
    final body = res.data;
    if (body == null) return LiveEventSnapshotDto.fromJson({});
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      final d = body['data'] as Map<String, dynamic>;
      // Could be {snapshot: {...}} or snapshot directly
      if (d['snapshot'] is Map<String, dynamic>) {
        // Keep the whole data map but snapshot dto handles nesting
        data = d;
      } else {
        data = d;
      }
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    return LiveEventSnapshotDto.fromJson(data ?? {});
  }

  Future<LiveEventParticipantDto> submitAnswer(int eventId, {required int questionIndex, required String answer, String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/live-events/$eventId/answers',
      data: {'question_index': questionIndex, 'answer': answer},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Answer empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      final d = body['data'] as Map<String, dynamic>;
      if (d['participant'] is Map<String, dynamic>) {
        data = d['participant'] as Map<String, dynamic>;
      } else {
        data = d;
      }
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        final d = env.data;
        if (d != null && d['participant'] is Map<String, dynamic>) {
          data = d['participant'] as Map<String, dynamic>;
        } else {
          data = d;
        }
      } catch (_) {
        data = body;
      }
    }
    if (data == null) throw Exception('Participant missing');
    return LiveEventParticipantDto.fromJson(data);
  }
}

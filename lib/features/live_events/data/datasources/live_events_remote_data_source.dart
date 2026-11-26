import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../models/live_event_dto.dart';

/// Verified routes:
/// GET /quiz/live-events, GET /quiz/live-events/{event},
/// POST /quiz/live-events/{event}/register, DELETE register,
/// POST /quiz/live-events/{event}/check-in, GET /snapshot, POST /answers
class LiveEventsRemoteDataSource {
  const LiveEventsRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  /// Reads the envelope's `data` object. Writes nest their payload one level
  /// deeper (`participant`, `snapshot`) and the DTOs handle that nesting; a
  /// body the client cannot read now throws rather than being parsed as the
  /// raw envelope and rendered as a half-empty DTO.
  Map<String, dynamic> _requireData(
    Map<String, dynamic>? body,
    String endpoint,
  ) =>
      requireDataMap(body, endpoint: endpoint);

  Future<List<LiveEventDto>> getLiveEvents({int limit = 25}) async {
    const endpoint = '/quiz/live-events';
    final res = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'limit': limit},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    late final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final events = data['events'] ?? data['items'];
      if (events is List) {
        raw = events;
      } else if (data.isEmpty) {
        // A published empty object is the server saying "no events".
        raw = const <dynamic>[];
      } else {
        throw ContractViolation(
          'Live-events payload not understood: no `events` list under `data`',
          endpoint: endpoint,
        );
      }
    } else if (body['events'] is List) {
      raw = body['events'] as List;
    } else {
      throw ContractViolation(
        'Live-events payload not understood, got ${data.runtimeType}',
        endpoint: endpoint,
      );
    }
    // A malformed row must throw instead of silently reducing the count.
    final rows = <Map<String, dynamic>>[];
    for (final row in raw) {
      if (row is! Map<String, dynamic>) {
        throw ContractViolation(
          'Expected each live event to be an object, got ${row.runtimeType}',
          endpoint: endpoint,
        );
      }
      rows.add(row);
    }
    return rows.map(LiveEventDto.fromJson).toList();
  }

  Future<LiveEventDetailDto> getLiveEvent(int id) async {
    final endpoint = '/quiz/live-events/$id';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return LiveEventDetailDto.fromJson(_requireData(res.data, endpoint));
  }

  Future<LiveEventParticipantDto> register(int eventId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    // Canonical is PUT /live-events/{id}/registration; POST .../register is
    // the §4.3 alias (routes/api/v1/quiz.php:379-383).
    final endpoint = '/quiz/live-events/$eventId/registration';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    // The server publishes `data.participant`; a participant directly under
    // `data` is also accepted so the existing wire shape stays intact.
    final data = _requireData(res.data, endpoint);
    final participant = data['participant'];
    return LiveEventParticipantDto.fromJson(
      participant is Map<String, dynamic> ? participant : data,
    );
  }

  Future<void> unregister(int eventId) async {
    await _dio.delete<Map<String, dynamic>>('/quiz/live-events/$eventId/register');
  }

  Future<LiveEventParticipantDto> checkIn(int eventId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final endpoint = '/quiz/live-events/$eventId/attendance';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final data = _requireData(res.data, endpoint);
    final participant = data['participant'];
    return LiveEventParticipantDto.fromJson(
      participant is Map<String, dynamic> ? participant : data,
    );
  }

  Future<LiveEventSnapshotDto> getSnapshot(int eventId) async {
    final endpoint = '/quiz/live-events/$eventId/snapshot';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    // The DTO handles the `{snapshot: {...}}` nesting itself; pass the whole
    // published `data` object, never an invented empty one.
    return LiveEventSnapshotDto.fromJson(_requireData(res.data, endpoint));
  }

  Future<LiveEventParticipantDto> submitAnswer(int eventId, {required int questionIndex, required String answer, String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final endpoint = '/quiz/live-events/$eventId/answers';
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: {'question_index': questionIndex, 'answer': answer},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final data = _requireData(res.data, endpoint);
    final participant = data['participant'];
    return LiveEventParticipantDto.fromJson(
      participant is Map<String, dynamic> ? participant : data,
    );
  }
}

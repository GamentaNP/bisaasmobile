import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';

/// Verified server routes (`routes/api/v1/quiz.php:546-558` — Firebase
/// Multiplayer Battles):
/// - GET  /quiz/firebase-token                      → custom token for RTDB auth
/// - POST /quiz/battles                             → create/find open battle
///                                                      ({category_id required,
///                                                       total_questions 5..20})
/// - PUT  /quiz/battles/{id}/participation          → join an open battle
/// - PUT  /quiz/battles/{id}/answer                → {question_id, question_index,
///                                                      selected_option 1..4,
///                                                      time_taken_ms}
/// - PUT  /quiz/battles/{id}/completion             → force-finish (HOST ONLY)
/// - GET  /quiz/battles/{id}/results                → final results
/// - GET  /quiz/battles/history                     → battle history
///
/// **Canonical spellings are used deliberately.** The server registers the
/// §4.3 state transitions as PUT and keeps the POST forms only as
/// `*.transition-alias` pending a freeze. Only create and answer were wired
/// before, so a battle could be started and answered but never joined, ended or
/// read back — the result screen had to invent the outcome.
///
/// RTDB subscription is read-only on /battles/{lobbyId} (see
/// docs/mobileapp/RTDB_BATTLE_SCHEMA.md). Dio baseUrl already ends with /api/v1.
class BattleRemoteDataSource {
  const BattleRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  /// A required object under `data`. A response the client cannot read throws;
  /// it never becomes a fabricated lobby.
  Map<String, dynamic> _requireData(
    Map<String, dynamic>? body,
    String endpoint,
  ) =>
      requireDataMap(body, endpoint: endpoint);

  /// `POST /quiz/battle-rooms` — a private lobby owned by the caller.
  ///
  /// Every field is sent explicitly because the server validates each one:
  /// `mode` is constrained to `LobbyService::SUPPORTED_MODES`, `queue_type`
  /// to `unranked|ranked`, and `wager_coins` is required (0 is allowed).
  Future<Map<String, dynamic>> createLobby({
    required String mode,
    int wagerCoins = 0,
    String queueType = 'unranked',
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/battle-rooms',
      data: <String, dynamic>{
        'mode': mode,
        'queue_type': queueType,
        'wager_coins': wagerCoins,
      },
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
      ),
    );
    return _requireData(res.data, '/quiz/battle-rooms');
  }

  /// `POST /quiz/battle-rooms/{lobby}/invitations` — invite by email.
  ///
  /// The server requires an Idempotency-Key here (the call sends a
  /// notification), so a retry with the same key does not invite twice.
  Future<Map<String, dynamic>> inviteToLobby({
    required int lobbyId,
    required String email,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/battle-rooms/$lobbyId/invitations',
      data: <String, dynamic>{'email': email},
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
      ),
    );
    return _requireData(
      res.data,
      '/quiz/battle-rooms/{lobby}/invitations',
    );
  }

  /// `PUT /quiz/invitations/{notification}/acceptance` — the invited user
  /// joins the lobby. Returns the lobby the notification pointed at.
  Future<Map<String, dynamic>> acceptLobbyInvitation({
    required int notificationId,
    String? idempotencyKey,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/invitations/$notificationId/acceptance',
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
      ),
    );
    return _requireData(
      res.data,
      '/quiz/invitations/{notification}/acceptance',
    );
  }

  /// `data` out of the envelope.
  ///
  /// A body the client cannot read is a contract drift and throws — it must
  /// never become an empty lobby, which would render as "no battles".
  Map<String, dynamic> _dataOrEmpty(Map<String, dynamic>? body) {
    if (body == null) {
      throw const ContractViolation('Empty response body');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final parsed = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?).data;
      if (parsed != null) return parsed;
    } on Object {
      // Fall through to the contract violation below.
    }
    throw const ContractViolation('Battle payload not understood');
  }

  Future<Map<String, dynamic>> getFirebaseToken() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/firebase-token');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    return Map<String, dynamic>.from(data as Map);
  }

  /// Create or find an open battle. The server requires a `category_id`
  /// (quiz_categories.id); when [categoryId] is null a default is resolved
  /// from the first course's first category.
  ///
  /// `mode` is `1v1|2v2|3v3`. It is sent on the same create endpoint for both
  /// solo and team queues — the canonical and team payloads are parsed by
  /// `BattlePayload`, so a published team route only needs its path changed
  /// here. POST create requires an Idempotency-Key (§7).
  Future<Map<String, dynamic>> findMatch({
    int? categoryId,
    int totalQuestions = 10,
    String mode = '1v1',
    String? idempotencyKey,
  }) async {
    final resolved = categoryId ?? await _defaultCategoryId();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/battles',
      data: {
        'category_id': resolved,
        'total_questions': totalQuestions,
        'mode': mode,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>?;
    if (data == null) {
      // The previous fallback was `{'id': 'demo', 'status': 'searching'}` —
      // a fabricated battle id that left the arena waiting on a lobby that
      // does not exist. A body we cannot read is a failure, not a demo.
      throw const ContractViolation(
        'Battle payload not understood',
        endpoint: '/quiz/battles',
      );
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<int> _defaultCategoryId() async {
    final coursesRes = await _dio.get<Map<String, dynamic>>('/quiz/courses');
    final courses = _dataList(coursesRes.data);
    if (courses.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quiz/courses'),
        type: DioExceptionType.connectionError,
        error: appL10n().coursesNone,
      );
    }
    final courseId = courses.first['id'];
    final catsRes = await _dio.get<Map<String, dynamic>>('/quiz/courses/$courseId/categories');
    final cats = _dataList(catsRes.data);
    if (cats.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quiz/courses/$courseId/categories'),
        type: DioExceptionType.connectionError,
        error: appL10n().arcadeCategoryError,
      );
    }
    return int.parse(cats.first['id'].toString());
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic>? body, {String? endpoint}) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['data'];
      if (items is List) return items.whereType<Map<String, dynamic>>().toList();
    }
    throw ContractViolation(
      'Expected a list under `data`, got ${data.runtimeType}',
      endpoint: endpoint,
    );
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String id) async {
    final endpoint = '/quiz/leaderboards/$id';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      final nested = data['items'] ?? data['leaderboard'] ?? data['entries'];
      if (nested is List) return nested.whereType<Map<String, dynamic>>().toList();
    }
    throw ContractViolation(
      'Leaderboard payload not understood, got ${data.runtimeType}',
      endpoint: endpoint,
    );
  }

  /// Joins an open battle. No request body.
  ///
  /// Returns a fresh `firebase_token` for RTDB auth, so a join by the second
  /// player yields the credentials it needs without a second round-trip.
  /// 404 when the battle is no longer available — a normal outcome, since the
  /// lobby can fill while this request is in flight.
  Future<Map<String, dynamic>> join(String firebaseBattleId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/participation',
    );
    return _dataOrEmpty(res.data);
  }

  /// Ends the battle and syncs results server-side.
  ///
  /// **Host only** — `BattleController::end` returns 403 "Only the battle host
  /// can end the battle" for player 2, so the caller must not offer this to
  /// everyone. 409 when the battle is not `in_progress`.
  Future<Map<String, dynamic>> end(String firebaseBattleId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/completion',
    );
    return _dataOrEmpty(res.data);
  }

  /// Authoritative outcome. 403 for a user who is not a participant.
  Future<Map<String, dynamic>> getResults(String firebaseBattleId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/results',
    );
    return _dataOrEmpty(res.data);
  }

  /// Completed battles for this user, newest first, with a `stats` block.
  Future<Map<String, dynamic>> getHistory() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/battles/history');
    return _dataOrEmpty(res.data);
  }
}

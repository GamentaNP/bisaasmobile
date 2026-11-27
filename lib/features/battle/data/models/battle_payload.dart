/// The one place that knows both battle payload vintages.
///
/// The old create response carried only `{battle_id, firebase_battle_id,
/// firebase_token}`; the canonical payload adds `id`, `status`, `mode`,
/// `questions`, `players`, `me`, `started_at`, `per_question_seconds`,
/// `total_questions` and a fresh `firebase_token` on both create and join.
/// Both are parsed here so a screen never has to know which one it received.
library;

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/battle.dart';

class BattlePayload {
  const BattlePayload._();

  static const createEndpoint = '/quiz/battles';
  static const joinEndpoint = '/quiz/battles/{id}/participation';
  static const resultsEndpoint = '/quiz/battles/{id}/results';

  static int? intOf(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static num? numOf(Object? raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }

  static bool? boolOf(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      if (raw.toLowerCase() == 'true') return true;
      if (raw.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static String stringOf(Object? raw, [String fallback = '']) {
    final value = raw?.toString();
    return (value == null || value.isEmpty) ? fallback : value;
  }

  static Map<String, dynamic> stringMap(Object? raw) {
    if (raw is! Map) return const <String, dynamic>{};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value,
    };
  }

  /// `started_at` is an ISO-8601 string in the canonical payload and unix
  /// **seconds** in the legacy/RTDB one. Magnitude separates seconds from
  /// milliseconds so a drift in units cannot silently stop the question clock.
  static DateTime? startedAt(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    // DateTime.tryParse happily reads a bare digit string as a year, so a
    // numeric timestamp must be classified before the ISO branch.
    final secondsOrMs = intOf(raw);
    if (secondsOrMs == null) {
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }
    if (secondsOrMs.abs() >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(secondsOrMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(secondsOrMs * 1000);
  }

  static bool isTerminal(Object? status) =>
      BattleMatch.isBattleStatusTerminal(status);

  /// `winner` in RTDB may be a uid string, a numeric id or a map; the results
  /// API calls it `winner_id`. One representation is enough for the UI.
  static String? winnerUid(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return winnerUid(raw['uid'] ?? raw['id'] ?? raw['user_id']);
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static BattleOption option(Object? raw, int index) {
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final key = m['key'] ?? m['id'] ?? m['option_id'];
    final declared = intOf(key) ?? intOf(m['order'] ?? m['position']);
    final order = (declared != null && declared >= 1 && declared <= 4)
        ? declared - 1
        : index;
    return BattleOption(
      id: stringOf(key, '${index + 1}'),
      text: stringOf(m['text'] ?? m['label']),
      order: order,
    );
  }

  static BattleQuestion question(Object? raw, int index) {
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final optionsRaw = m['options'];
    final options = optionsRaw is List
        ? [
            for (var i = 0; i < optionsRaw.length; i++) option(optionsRaw[i], i),
          ]
        : <BattleOption>[];
    return BattleQuestion(
      id: stringOf(m['id'] ?? m['question_id'], '${index + 1}'),
      text: stringOf(m['body'] ?? m['text'] ?? m['question']),
      options: options,
      // Answer keys never travel in a payload the client can read: grading is
      // server-authoritative. This stays empty by design.
      correctOptionId: '',
      points: intOf(m['points']) ?? 10,
      index: intOf(m['question_index']) ?? index,
    );
  }

  static BattlePlayer player(Object? raw, {String? fallbackUid}) {
    final m = raw is Map ? raw : const <Object?, Object?>{};
    return BattlePlayer(
      uid: stringOf(m['uid'] ?? m['firebase_uid'] ?? m['id'], fallbackUid ?? ''),
      displayName:
          stringOf(m['display_name'] ?? m['displayName'] ?? m['name'] ?? m['user_name']),
      avatarUrl: stringOf(m['avatar_url'] ?? m['avatar']),
      score: intOf(m['score']) ?? 0,
      currentIdx: intOf(m['current_idx'] ?? m['current_question_index']) ?? 0,
      finished: boolOf(m['finished']) ?? false,
      team: m['team'] == null ? null : stringOf(m['team']),
      serverId: intOf(m['id'] ?? m['user_id']),
    );
  }

  static List<BattlePlayer> players(Object? raw) {
    if (raw is! List) return const <BattlePlayer>[];
    return [
      for (var i = 0; i < raw.length; i++) player(raw[i], fallbackUid: '$i'),
    ];
  }

  /// Parses create, join and RTDB snapshots into one entity.
  ///
  /// [requireQuestions] is true on REST create/join: a match the server
  /// published without questions is contract drift, not an empty arena. RTDB
  /// snapshots arrive before the questions node is written, so they pass
  /// false and merge into an existing match instead.
  static BattleMatch parse(
    Map<String, dynamic> raw, {
    String? endpoint,
    BattleMatch? base,
    bool requireQuestions = true,
  }) {
    // Canonical responses place the match directly under `data`; the results
    // endpoint nests it under `battle`. Accept both.
    final source = raw['battle'] is Map
        ? stringMap(raw['battle'])
        : raw;

    final questionsRaw = source['questions'] ?? source['question'] ?? raw['questions'];
    final questions = questionsRaw is List
        ? [
            for (var i = 0; i < questionsRaw.length; i++)
              question(questionsRaw[i], i),
          ]
        : <BattleQuestion>[];
    if (questions.isEmpty && requireQuestions && (base?.questions.isEmpty ?? true)) {
      throw ContractViolation(
        'Battle payload has no questions',
        endpoint: endpoint ?? createEndpoint,
      );
    }

    final playersRaw = source['players'] ?? raw['players'];
    final parsedPlayers = players(playersRaw);
    final legacyP1 = source['player1'] ?? raw['player1'];
    final legacyP2 = source['player2'] ?? raw['player2'];
    final effectivePlayers = parsedPlayers.isNotEmpty
        ? parsedPlayers
        : [
            if (legacyP1 != null) player(legacyP1, fallbackUid: 'p1'),
            if (legacyP2 != null) player(legacyP2, fallbackUid: 'p2'),
          ];

    final id = stringOf(
      source['id'] ??
          source['firebase_battle_id'] ??
          source['battle_id'] ??
          source['lobby_id'] ??
          raw['id'] ??
          raw['firebase_battle_id'] ??
          raw['battle_id'],
      base?.id ?? '',
    );
    if (id.isEmpty) {
      throw ContractViolation(
        'Battle payload has no id',
        endpoint: endpoint ?? createEndpoint,
      );
    }

    final meMap = stringMap(source['me'] ?? raw['me']);
    final meUid = stringOf(meMap['uid'] ?? meMap['firebase_uid'], base?.meUid ?? '');
    final currentUserId = intOf(meMap['id'] ?? meMap['uid']) ?? base?.currentUserId;

    final parsedStarted = startedAt(source['started_at'] ?? raw['started_at']);
    final started = parsedStarted ??
        base?.startedAt ??
        startedAt(
          source['started_at_ms'] ??
              source['created_at'] ??
              raw['started_at_ms'],
        );

    final token = stringOf(
      source['firebase_token'] ??
          source['token'] ??
          source['custom_token'] ??
          raw['firebase_token'],
      base?.firebaseToken ?? '',
    );

    final p1 = effectivePlayers.isNotEmpty
        ? effectivePlayers.first
        : (base?.player1 ?? const BattlePlayer(uid: 'p1', displayName: '', avatarUrl: ''));
    final p2 = effectivePlayers.length > 1
        ? effectivePlayers[1]
        : (base?.player2 ?? const BattlePlayer(uid: 'p2', displayName: '', avatarUrl: ''));

    return BattleMatch(
      id: id,
      status: stringOf(source['status'] ?? raw['status'], base?.status ?? 'waiting'),
      opponentLabel: stringOf(
        source['opponent'] ?? source['opponent_label'],
        base?.opponentLabel ?? '',
      ),
      player1: p1,
      player2: p2,
      players: effectivePlayers.isNotEmpty ? effectivePlayers : (base?.players ?? const []),
      questions: questions.isNotEmpty ? questions : (base?.questions ?? const []),
      perQuestionSeconds: intOf(source['per_question_seconds'] ?? raw['per_question_seconds']) ??
          base?.perQuestionSeconds ??
          30,
      category: stringOf(source['category'] ?? raw['category'], base?.category ?? 'general'),
      startedAtMs: intOf(source['started_at_ms'] ?? raw['started_at_ms']) ?? base?.startedAtMs,
      finishedAtMs: intOf(source['finished_at_ms'] ?? raw['finished_at_ms']) ?? base?.finishedAtMs,
      winnerUid: winnerUid(source['winner'] ?? source['winner_id'] ?? raw['winner']) ??
          base?.winnerUid,
      mode: stringOf(source['mode'] ?? raw['mode'], base?.mode ?? '1v1'),
      firebaseBattleId: stringOf(
        source['firebase_battle_id'] ?? source['battle_id'] ?? raw['firebase_battle_id'],
        base?.firebaseBattleId ?? '',
      ),
      firebaseToken: token,
      meUid: meUid,
      currentUserId: currentUserId,
      totalQuestions: intOf(source['total_questions'] ?? raw['total_questions']) ??
          base?.totalQuestions ??
          questions.length,
      startedAt: started,
    );
  }

  /// Legacy token endpoint: `GET /quiz/firebase-token` may answer with
  /// `data.token`, `data.custom_token` or the canonical `data.firebase_token`.
  static String firebaseToken(Map<String, dynamic> raw) => stringOf(
        raw['firebase_token'] ?? raw['token'] ?? raw['custom_token'],
      );
}

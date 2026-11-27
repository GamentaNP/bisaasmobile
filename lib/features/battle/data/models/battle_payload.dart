/// The one place that knows both battle payload vintages.
///
/// The canonical payload is produced by `BattlePayloadFactory` on the server
/// for create, join, quick-match and team-match. RTDB snapshots carry the same
/// field names but store `players` as a map keyed by uid and `started_at` as
/// unix seconds. Both are parsed here so a screen never has to know which one
/// it received.
library;

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/battle.dart';

class BattlePayload {
  const BattlePayload._();

  static const createEndpoint = '/quiz/battles';
  static const joinEndpoint = '/quiz/battles/{id}/participation';
  static const resultsEndpoint = '/quiz/battles/{id}/results';
  static const teamMatchEndpoint = '/quiz/battle-rooms/team-matches';
  static const quickMatchEndpoint = '/quiz/battle-rooms/quick-matches';

  static const teamModes = <String>{'2v2', '3v3', '5v5'};

  static int? intOf(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
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
    return {for (final entry in raw.entries) entry.key.toString(): entry.value};
  }

  /// `started_at` is an ISO-8601 string in REST responses and unix **seconds**
  /// in RTDB. Magnitude separates seconds from milliseconds so a unit drift
  /// cannot silently stop the question clock. DateTime.tryParse would happily
  /// read a bare digit string as a year, so numeric values come first.
  static DateTime? startedAt(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final secondsOrMs = intOf(raw);
    if (secondsOrMs != null) {
      if (secondsOrMs.abs() >= 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(secondsOrMs);
      }
      return DateTime.fromMillisecondsSinceEpoch(secondsOrMs * 1000);
    }
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static bool isTerminal(Object? status) =>
      BattleMatch.isBattleStatusTerminal(status);

  static bool isTerminalSnapshot(Map<String, dynamic> snapshot) =>
      BattleMatch.isTerminalSnapshot(snapshot);

  /// `winner` in RTDB is the winning uid as a string; the results API also
  /// publishes `winner_id`. One representation is enough for the UI.
  static String? winnerUid(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return winnerUid(raw['uid'] ?? raw['id'] ?? raw['user_id']);
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static BattleOption option(Object? raw, int index) {
    final m = raw is Map ? stringMap(raw) : const <String, dynamic>{};
    final key = m['key'] ?? m['id'] ?? m['option_id'];
    // Canonical keys are `a`, `b`, `c`, `d` — map them by position, not by
    // pretending the letter is a number.
    final order = index < 4 ? index : (intOf(key) != null ? intOf(key)! - 1 : index);
    return BattleOption(
      id: stringOf(key, '${index + 1}'),
      text: stringOf(m['text'] ?? m['label']),
      order: order.clamp(0, 3),
    );
  }

  static BattleQuestion question(Object? raw, int index) {
    final m = raw is Map ? stringMap(raw) : const <String, dynamic>{};
    final optionsRaw = m['options'];
    final options = <BattleOption>[];
    if (optionsRaw is List) {
      for (var i = 0; i < optionsRaw.length; i++) {
        options.add(option(optionsRaw[i], i));
      }
    } else if (optionsRaw is Map) {
      final entries = optionsRaw.entries.toList()
        ..sort((a, b) =>
            intOf(a.key)?.compareTo(intOf(b.key) ?? 0) ?? 0);
      for (var i = 0; i < entries.length; i++) {
        options.add(option(entries[i].value, i));
      }
    }
    return BattleQuestion(
      id: stringOf(m['id'] ?? m['question_id'], '${index + 1}'),
      text: stringOf(m['body'] ?? m['text'] ?? m['question']),
      options: options,
      // Answer keys never travel in a client-readable payload: grading is
      // server-authoritative. This stays empty by design.
      correctOptionId: '',
      points: intOf(m['points']) ?? 10,
      index: intOf(m['question_index']) ?? index,
    );
  }

  static BattlePlayer player(
    Object? raw, {
    String? fallbackUid,
    BattlePlayer? base,
  }) {
    final m = raw is Map ? stringMap(raw) : const <String, dynamic>{};
    return BattlePlayer(
      uid: stringOf(m['uid'] ?? m['firebase_uid'] ?? m['id'], fallbackUid ?? ''),
      displayName: stringOf(
        m['display_name'] ?? m['displayName'] ?? m['name'] ?? m['user_name'],
        base?.displayName ?? '',
      ),
      avatarUrl: stringOf(m['avatar_url'] ?? m['avatar'], base?.avatarUrl ?? ''),
      // RTDB `players/{uid}` only carries uid/name/team/answered, so keep the
      // authoritative score from the REST player when the node omits it.
      score: intOf(m['score']) ?? base?.score ?? 0,
      currentIdx: intOf(m['current_idx'] ?? m['current_question_index']) ??
          base?.currentIdx ??
          0,
      finished: boolOf(m['finished']) ?? base?.finished ?? false,
      team: m['team'] == null ? null : stringOf(m['team']),
      serverId: intOf(m['id'] ?? m['user_id']) ?? base?.serverId,
    );
  }

  static List<BattlePlayer> players(Object? raw, {List<BattlePlayer>? base}) {
    BattlePlayer? byUid(String uid) {
      for (final p in base ?? const <BattlePlayer>[]) {
        if (p.uid == uid) return p;
      }
      return null;
    }

    if (raw is List) {
      return [
        for (var i = 0; i < raw.length; i++) player(raw[i], fallbackUid: '$i'),
      ];
    }
    if (raw is Map) {
      final entries = raw.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return [
        for (final entry in entries)
          player(
            entry.value,
            fallbackUid: entry.key.toString(),
            base: byUid(entry.key.toString()),
          ),
      ];
    }
    return const <BattlePlayer>[];
  }

  static List<BattleTeam> teams(Object? raw) {
    if (raw is! List) return const <BattleTeam>[];
    return [
      for (final t in raw)
        BattleTeam(
          key: stringOf(stringMap(t)['key']),
          name: stringOf(stringMap(t)['name'] ?? stringMap(t)['label']),
        ),
    ];
  }

  /// Parses create, join, team-match and RTDB snapshots into one entity.
  ///
  /// [requireQuestions] is true on REST create/join: a match the server
  /// published without questions is contract drift, not an empty arena. RTDB
  /// snapshots arrive before questions on legacy battles, so they pass false
  /// and merge into an existing match instead.
  static BattleMatch parse(
    Map<String, dynamic> raw, {
    String? endpoint,
    BattleMatch? base,
    bool requireQuestions = true,
  }) {
    final source = raw['battle'] is Map ? stringMap(raw['battle']) : raw;

    final questions = <BattleQuestion>[];
    final questionsRaw = source['questions'] ?? raw['questions'];
    if (questionsRaw is List) {
      for (var i = 0; i < questionsRaw.length; i++) {
        questions.add(question(questionsRaw[i], i));
      }
    } else if (questionsRaw is Map) {
      final entries = questionsRaw.entries.toList()
        ..sort((a, b) =>
            intOf(a.key)?.compareTo(intOf(b.key) ?? 0) ?? 0);
      for (var i = 0; i < entries.length; i++) {
        questions.add(question(entries[i].value, i));
      }
    }
    if (questions.isEmpty && requireQuestions && (base?.questions.isEmpty ?? true)) {
      throw ContractViolation(
        'Battle payload has no questions',
        endpoint: endpoint ?? createEndpoint,
      );
    }

    final parsedPlayers = players(
      source['players'] ?? raw['players'],
      base: base?.players,
    );
    final legacyP1 = source['player1'] ?? raw['player1'];
    final legacyP2 = source['player2'] ?? raw['player2'];
    final effectivePlayers = parsedPlayers.isNotEmpty
        ? parsedPlayers
        : [
            if (legacyP1 != null) player(legacyP1, fallbackUid: 'p1'),
            if (legacyP2 != null) player(legacyP2, fallbackUid: 'p2'),
          ];

    // Canonical `id` IS the RTDB handle. `battle_id`/`lobby_id` are numeric
    // database ids and must never be used as the subscription key.
    final id = stringOf(
      source['id'] ?? raw['id'] ?? source['firebase_battle_id'] ?? raw['firebase_battle_id'],
      base?.id ?? '',
    );
    if (id.isEmpty) {
      throw ContractViolation(
        'Battle payload has no id',
        endpoint: endpoint ?? createEndpoint,
      );
    }

    final me = stringMap(source['me'] ?? raw['me']);
    final meUid = stringOf(me['uid'], base?.meUid ?? '');
    final currentUserId = intOf(me['id'] ?? me['uid']) ?? base?.currentUserId;

    final parsedStarted = startedAt(source['started_at'] ?? raw['started_at']);
    // A REST ISO-8601 value is more precise than the RTDB seconds alias; keep
    // it once we have it.
    final started = base?.startedAt ??
        parsedStarted ??
        startedAt(
          source['started_at_ms'] ??
              source['created_at'] ??
              raw['started_at_ms'],
        );

    final token = stringOf(
      source['firebase_token'] ?? raw['firebase_token'],
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
        source['firebase_battle_id'] ?? raw['firebase_battle_id'],
        base?.firebaseBattleId ?? '',
      ),
      firebaseToken: token,
      meUid: meUid,
      currentUserId: currentUserId,
      totalQuestions: intOf(source['total_questions'] ?? raw['total_questions']) ??
          base?.totalQuestions ??
          questions.length,
      startedAt: started,
      action: stringOf(source['action'] ?? raw['action'], base?.action ?? ''),
      lobbyId: intOf(source['lobby_id'] ?? raw['lobby_id']) ?? base?.lobbyId,
      teams: teams(source['teams'] ?? raw['teams']).isNotEmpty
          ? teams(source['teams'] ?? raw['teams'])
          : (base?.teams ?? const []),
    );
  }
}

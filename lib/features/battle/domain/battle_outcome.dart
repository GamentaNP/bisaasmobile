import 'package:flutter/foundation.dart';

/// One player's authoritative line in `GET /quiz/battles/{id}/results`.
@immutable
class BattleOutcomePlayer {
  const BattleOutcomePlayer({
    required this.uid,
    required this.name,
    required this.score,
    this.team,
    this.isMe = false,
    this.isWinner = false,
  });
  final String uid;
  final String name;
  final int score;
  final String? team;
  final bool isMe;
  final bool isWinner;
}

/// Server-authoritative outcome of a battle, from
/// `GET /quiz/battles/{firebaseBattleId}/results`.
///
/// The screen previously inferred the outcome client-side and, when the winner
/// was not yet known, treated that as a **win**:
///
///   isWin = winnerUid == null || winnerUid == me.uid || me.score >= opp.score
///
/// So an unresolved battle rendered as a victory, and a tie rendered as a
/// victory too. Both are lies to the user about money-adjacent progress, and
/// neither matches the server's own computation:
///
///   result = winner_id === user.id ? 'win' : (winner_id === null ? 'draw' : 'loss')
@immutable
class BattleOutcome {
  const BattleOutcome({
    required this.result,
    this.userId,
    this.opponentName,
    this.userScore,
    this.opponentScore,
    this.categoryName,
    this.endedAt,
    this.players = const [],
    this.winnerUid,
  });

  /// `win` | `loss` | `draw` | `pending`.
  final String result;

  final int? userId;
  final String? opponentName;
  final int? userScore;
  final int? opponentScore;
  final String? categoryName;
  final DateTime? endedAt;

  /// Every participant, not just two — team modes publish up to six.
  final List<BattleOutcomePlayer> players;

  final String? winnerUid;

  bool get isWin => result == 'win';
  bool get isLoss => result == 'loss';
  bool get isDraw => result == 'draw';

  /// True when the server has not resolved the battle yet. Callers must show a
  /// neutral state here rather than guessing — that guess is the bug this
  /// replaces.
  bool get isPending => result == 'pending';

  /// Parses the payload from `GET /quiz/battles/{id}/results`. Returns a
  /// `pending` outcome instead of a fabricated one when the payload is missing
  /// or unrecognised, so a shape change cannot silently turn into a win.
  ///
  /// Both the legacy `{battle: {player1, player2, winner_id}}` shape and the
  /// canonical `{players, me, winner, status}` shape are accepted.
  factory BattleOutcome.fromResults(
    Map<String, dynamic> data, {
    required int? currentUserId,
    String? currentUid,
  }) {
    final rawSource = data['battle'] is Map ? data['battle'] : data;
    if (rawSource is! Map) {
      return BattleOutcome(result: 'pending', userId: currentUserId);
    }
    final b = {
      for (final entry in rawSource.entries)
        entry.key.toString(): entry.value,
    };

    int? intOf(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    String stringOf(Object? v, [String fallback = '']) {
      final s = v?.toString();
      return (s == null || s.isEmpty) ? fallback : s;
    }

    Map<String, dynamic> mapOf(Object? v) {
      if (v is! Map) return const <String, dynamic>{};
      return {for (final e in v.entries) e.key.toString(): e.value};
    }

    final list = b['players'] is List
        ? (b['players'] as List).map(mapOf).toList()
        : <Map<String, dynamic>>[];
    if (list.isEmpty) {
      for (final key in const ['player1', 'player2']) {
        if (b[key] is Map) list.add(mapOf(b[key]));
      }
    }

    final parsed = <BattleOutcomePlayer>[
      for (final p in list)
        BattleOutcomePlayer(
          uid: stringOf(p['uid'] ?? p['firebase_uid']),
          name: stringOf(p['name'] ?? p['display_name']),
          score: intOf(p['score']) ?? 0,
          team: p['team'] == null ? null : stringOf(p['team']),
        ),
    ];

    final me = mapOf(b['me']);
    final meUid = stringOf(me['uid'] ?? me['id']);
    int? myIndex;
    for (var i = 0; i < parsed.length; i++) {
      final p = list[i];
      if ((currentUserId != null && intOf(p['id'] ?? p['user_id']) == currentUserId) ||
          (currentUid != null && currentUid.isNotEmpty && parsed[i].uid == currentUid) ||
          (meUid.isNotEmpty && parsed[i].uid == meUid)) {
        myIndex = i;
        break;
      }
    }
    // Without an id match, the server's player1 slot is the historical
    // convention. Never invent a win from this fallback.
    myIndex ??= parsed.isEmpty ? null : 0;

    final winnerRaw = b['winner'] ?? b['winner_id'];
    final winnerUid = winnerRaw is Map
        ? stringOf(winnerRaw['uid'] ?? winnerRaw['id'] ?? winnerRaw['user_id'])
        : (winnerRaw is String ? winnerRaw : '');
    final winnerId = winnerRaw is Map
        ? intOf(winnerRaw['id'] ?? winnerRaw['user_id'])
        : intOf(winnerRaw);

    final status = stringOf(b['status']);
    final resolved = BattleOutcomeStatus.isTerminal(status) || winnerId != null || winnerUid.isNotEmpty;

    final String result;
    if (!resolved) {
      result = 'pending';
    } else if (winnerId == null && winnerUid.isEmpty) {
      result = 'draw';
    } else {
      final mine = myIndex == null ? null : parsed[myIndex];
      final myServerId = myIndex == null
          ? null
          : intOf(list[myIndex]['id'] ?? list[myIndex]['user_id']);
      final won = (currentUserId != null && winnerId == currentUserId) ||
          (mine != null && winnerUid.isNotEmpty && mine.uid == winnerUid) ||
          (myServerId != null && winnerId == myServerId);
      result = won ? 'win' : 'loss';
    }

    final others = <BattleOutcomePlayer>[];
    for (var i = 0; i < parsed.length; i++) {
      if (i != myIndex) others.add(parsed[i]);
    }
    others.sort((a, b) => b.score.compareTo(a.score));

    final players = <BattleOutcomePlayer>[
      for (var i = 0; i < parsed.length; i++)
        BattleOutcomePlayer(
          uid: parsed[i].uid,
          name: parsed[i].name,
          score: parsed[i].score,
          team: parsed[i].team,
          isMe: i == myIndex,
          isWinner: (winnerId != null &&
                  intOf(list[i]['id'] ?? list[i]['user_id']) == winnerId) ||
              (winnerUid.isNotEmpty && parsed[i].uid == winnerUid),
        ),
    ];

    return BattleOutcome(
      result: result,
      userId: currentUserId,
      opponentName: others.isEmpty ? null : others.first.name,
      userScore: myIndex == null ? null : parsed[myIndex].score,
      opponentScore: others.isEmpty ? null : others.first.score,
      categoryName: b['category'] is Map
          ? stringOf((b['category'] as Map)['name'])
          : stringOf(b['category']),
      endedAt: DateTime.tryParse(stringOf(b['ended_at'])),
      players: players,
      winnerUid: winnerUid.isEmpty ? null : winnerUid,
    );
  }
}

/// Kept as a tiny standalone helper so the arena's RTDB listener and the
/// result parser cannot disagree about which state ends a battle.
class BattleOutcomeStatus {
  const BattleOutcomeStatus._();
  static bool isTerminal(Object? status) {
    final s = status?.toString().toLowerCase();
    return s == 'finished' || s == 'completed';
  }
}

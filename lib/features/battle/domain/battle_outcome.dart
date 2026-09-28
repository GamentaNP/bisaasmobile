import 'package:flutter/foundation.dart';

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
  });

  /// `win` | `loss` | `draw` | `pending`.
  final String result;

  final int? userId;
  final String? opponentName;
  final int? userScore;
  final int? opponentScore;
  final String? categoryName;
  final DateTime? endedAt;

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
  factory BattleOutcome.fromResults(Map<String, dynamic> data, {required int? currentUserId}) {
    final battle = data['battle'];
    if (battle is! Map) {
      return BattleOutcome(result: 'pending', userId: currentUserId);
    }
    final b = battle.cast<String, dynamic>();

    int? scoreOf(Object? p) {
      if (p is! Map<String, dynamic>) return null;
      final v = p['score'];
      return v is int ? v : (v is num ? v.toInt() : null);
    }

    // The server returns both players; pick ours by id when possible and fall
    // back to position only when the ids are absent.
    final p1 =
        b['player1'] is Map<String, dynamic> ? b['player1'] as Map<String, dynamic> : null;
    final p2 =
        b['player2'] is Map<String, dynamic> ? b['player2'] as Map<String, dynamic> : null;

    int? idOf(Map<String, dynamic>? p) {
      final v = p?['id'];
      return v is int ? v : (v is num ? v.toInt() : null);
    }

    Map<String, dynamic>? mine;
    Map<String, dynamic>? theirs;
    if (currentUserId != null && idOf(p1) == currentUserId) {
      mine = p1;
      theirs = p2;
    } else if (currentUserId != null && idOf(p2) == currentUserId) {
      mine = p2;
      theirs = p1;
    } else {
      mine = p1;
      theirs = p2;
    }

    final winnerId = b['winner_id'];
    final winner = winnerId is int ? winnerId : (winnerId is num ? winnerId.toInt() : null);

    // Mirror the server's own rule, and treat "status not completed" as pending
    // rather than as a win.
    final status = (b['status'] ?? '').toString();
    final resolved = status == 'completed' || winner != null;
    final String result;
    if (!resolved) {
      result = 'pending';
    } else if (winner == null) {
      result = 'draw';
    } else if (currentUserId != null && winner == currentUserId) {
      result = 'win';
    } else {
      result = 'loss';
    }

    return BattleOutcome(
      result: result,
      userId: currentUserId,
      opponentName: theirs?['name']?.toString(),
      userScore: scoreOf(mine),
      opponentScore: scoreOf(theirs),
      categoryName: b['category'] is Map
          ? (b['category'] as Map)['name']?.toString()
          : b['category']?.toString(),
      endedAt: DateTime.tryParse((b['ended_at'] ?? '').toString()),
    );
  }
}

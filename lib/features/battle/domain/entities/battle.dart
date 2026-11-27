import 'package:meta/meta.dart';

@immutable
class BattleToken {
  const BattleToken({required this.token, required this.expiresAt});
  final String token;
  final DateTime? expiresAt;
}

@immutable
class BattlePlayer {
  const BattlePlayer({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    this.score = 0,
    this.currentIdx = 0,
    this.finished = false,
    this.team,
    this.serverId,
  });
  final String uid;
  final String displayName;
  final String avatarUrl;
  final int score;
  final int currentIdx;
  final bool finished;

  /// `alpha` / `bravo` for team battles, null in 1v1.
  final String? team;

  /// Numeric user id from the server, used to compare against the authoritative
  /// `winner_id` in `GET /quiz/battles/{id}/results`.
  final int? serverId;
}

@immutable
class BattleTeam {
  const BattleTeam({required this.key, this.name = ''});
  final String key;
  final String name;
}

@immutable
class BattleQuestion {
  const BattleQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionId,
    required this.points,
    this.index = 0,
  });
  final String id;
  final String text;
  final List<BattleOption> options;
  final String correctOptionId;
  final int points;

  /// Zero-based position published by the server (or derived from the array).
  final int index;
}

@immutable
class BattleOption {
  const BattleOption({
    required this.id,
    required this.text,
    this.order = 0,
  });
  final String id;
  final String text;

  /// Zero-based option position. The canonical key is a letter (`a`..`d`)
  /// while the answer endpoint takes `selected_option` 1..4, so the letter is
  /// translated to its position at submit time — never guessed from the key.
  final int order;
}

@immutable
class BattleMatch {
  const BattleMatch({
    required this.id,
    required this.status,
    // Placeholder for a mapped server field that no screen renders yet. Empty,
    // not 'Searching…' — an unrendered field has no business carrying copy.
    this.opponentLabel = '',
    // No display copy in the domain layer: an empty name means "the server
    // published none", and the screen fills in the locale's "You"/"Opponent".
    this.player1 = const BattlePlayer(uid: 'p1', displayName: '', avatarUrl: ''),
    this.player2 = const BattlePlayer(uid: 'p2', displayName: '', avatarUrl: ''),
    this.players = const [],
    this.questions = const [],
    this.perQuestionSeconds = 30,
    this.category = 'general',
    this.startedAtMs,
    this.finishedAtMs,
    this.winnerUid,
    this.mode = '1v1',
    this.firebaseBattleId = '',
    this.firebaseToken = '',
    this.meUid = '',
    this.currentUserId,
    this.totalQuestions = 0,
    this.startedAt,
    this.action = '',
    this.lobbyId,
    this.teams = const [],
  });
  final String id;
  final String status; // waiting, in_progress, active, finished
  final String opponentLabel;
  final BattlePlayer player1;
  final BattlePlayer player2;

  /// Every participant, including teams of five. Legacy payloads with only
  /// `player1`/`player2` are exposed through [allPlayers].
  final List<BattlePlayer> players;

  final List<BattleQuestion> questions;
  final int perQuestionSeconds;
  final String category;
  final int? startedAtMs;
  final int? finishedAtMs;
  final String? winnerUid;

  /// `1v1`, `2v2`, `3v3` or `5v5`.
  final String mode;

  final String firebaseBattleId;

  /// Fresh custom token minted by create/join. Single-use, never persisted.
  final String firebaseToken;

  /// Canonical `me.uid` — the uid that identifies this user in RTDB, in the
  /// `players` map and in the result payload.
  final String meUid;

  /// Canonical `me.id` (integer). The results endpoint compares integer ids.
  final int? currentUserId;

  final int totalQuestions;

  /// ISO-8601 from the server. On RTDB the legacy node carries unix seconds,
  /// which the parser converts before it reaches this field.
  final DateTime? startedAt;

  /// `created` | `joined` | `started` from the canonical payload.
  final String action;

  /// Team-lobby id (team responses only).
  final int? lobbyId;

  /// Alpha/bravo rosters published by the team endpoints.
  final List<BattleTeam> teams;

  /// The participants a screen should render, regardless of payload vintage.
  List<BattlePlayer> get allPlayers =>
      players.isNotEmpty ? players : [player1, player2];

  /// The server publishes `id` equal to `firebase_battle_id`; it is the RTDB
  /// subscription key. `battle_id`/`lobby_id` are numeric db ids, not handles.
  String get rtdbId => id;

  int get questionCount =>
      totalQuestions > 0 ? totalQuestions : questions.length;

  bool get isTerminal => isBattleStatusTerminal(status);

  BattlePlayer me(String uid) {
    for (final p in allPlayers) {
      if (p.uid == uid) return p;
    }
    return player1;
  }

  BattlePlayer opponent(String uid) {
    for (final p in allPlayers) {
      if (p.uid != uid) return p;
    }
    return player2;
  }

  bool isMe(BattlePlayer player, String uid) => player.uid == uid;

  static const Object _unset = Object();

  BattleMatch copyWith({
    String? id,
    String? status,
    String? opponentLabel,
    BattlePlayer? player1,
    BattlePlayer? player2,
    List<BattlePlayer>? players,
    List<BattleQuestion>? questions,
    int? perQuestionSeconds,
    String? category,
    Object? startedAtMs = _unset,
    Object? finishedAtMs = _unset,
    Object? winnerUid = _unset,
    String? mode,
    String? firebaseBattleId,
    String? firebaseToken,
    String? meUid,
    Object? currentUserId = _unset,
    int? totalQuestions,
    Object? startedAt = _unset,
    String? action,
    Object? lobbyId = _unset,
    List<BattleTeam>? teams,
  }) =>
      BattleMatch(
        id: id ?? this.id,
        status: status ?? this.status,
        opponentLabel: opponentLabel ?? this.opponentLabel,
        player1: player1 ?? this.player1,
        player2: player2 ?? this.player2,
        players: players ?? this.players,
        questions: questions ?? this.questions,
        perQuestionSeconds: perQuestionSeconds ?? this.perQuestionSeconds,
        category: category ?? this.category,
        startedAtMs:
            identical(startedAtMs, _unset) ? this.startedAtMs : startedAtMs as int?,
        finishedAtMs: identical(finishedAtMs, _unset)
            ? this.finishedAtMs
            : finishedAtMs as int?,
        winnerUid: identical(winnerUid, _unset) ? this.winnerUid : winnerUid as String?,
        mode: mode ?? this.mode,
        firebaseBattleId: firebaseBattleId ?? this.firebaseBattleId,
        firebaseToken: firebaseToken ?? this.firebaseToken,
        meUid: meUid ?? this.meUid,
        currentUserId: identical(currentUserId, _unset)
            ? this.currentUserId
            : currentUserId as int?,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        startedAt:
            identical(startedAt, _unset) ? this.startedAt : startedAt as DateTime?,
        action: action ?? this.action,
        lobbyId: identical(lobbyId, _unset) ? this.lobbyId : lobbyId as int?,
        teams: teams ?? this.teams,
      );

  /// Terminal states are spelled differently across the REST payload
  /// (`finished`) and the legacy RTDB alias (`completed`).
  static bool isBattleStatusTerminal(Object? status) {
    final s = status?.toString().toLowerCase();
    return s == 'finished' || s == 'completed';
  }

  /// The RTDB node also publishes additive `completed=true` and
  /// `legacy_status='completed'` beside `status='finished'`.
  static bool isTerminalSnapshot(Map<String, dynamic> snapshot) {
    if (isBattleStatusTerminal(snapshot['status'])) return true;
    if (snapshot['completed'] == true) return true;
    return snapshot['legacy_status']?.toString().toLowerCase() == 'completed';
  }
}

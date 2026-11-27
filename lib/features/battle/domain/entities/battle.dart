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

  /// Team label published by the server (`1`, `2`, `A`, `B`, …). Null in 1v1.
  final String? team;

  /// Numeric user id from the server, used to compare against the authoritative
  /// `winner_id` in `GET /quiz/battles/{id}/results`.
  final int? serverId;
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

  /// Zero-based option position. The answer endpoint takes `selected_option`
  /// 1..4, so this is sent as `order + 1` even when the published key is a
  /// letter (`A`..`D`) rather than a number.
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
  });
  final String id;
  final String status; // waiting, starting, in_progress, finished/completed
  final String opponentLabel;
  final BattlePlayer player1;
  final BattlePlayer player2;

  /// Every participant, including teams of three. Legacy payloads with only
  /// `player1`/`player2` are exposed through [allPlayers].
  final List<BattlePlayer> players;

  final List<BattleQuestion> questions;
  final int perQuestionSeconds;
  final String category;
  final int? startedAtMs;
  final int? finishedAtMs;
  final String? winnerUid;

  /// `1v1`, `2v2` or `3v3` — sent to the create endpoint so the server can
  /// place the user in a queue of the right size.
  final String mode;

  /// The handle used on RTDB (`battles/{firebaseBattleId}`). It is NOT the
  /// numeric database `battle_id`, which is what [id] carried historically.
  final String firebaseBattleId;

  /// Fresh custom token minted by create/join. It is single-use for
  /// `signInWithCustomToken`, never persisted and never reused after a refresh.
  final String firebaseToken;

  /// The local user's uid as published by the server (`me.uid`).
  final String meUid;

  /// Numeric user id (`me.id` / `me.uid` when numeric). The results endpoint
  /// compares integer ids, so this is what the outcome screen needs.
  final int? currentUserId;

  final int totalQuestions;

  /// Server start time. ISO-8601 and unix seconds are both accepted by the
  /// parser; the ticker derives the question index from this single value.
  final DateTime? startedAt;

  /// The participants a screen should render, regardless of payload vintage.
  List<BattlePlayer> get allPlayers =>
      players.isNotEmpty ? players : [player1, player2];

  /// RTDB handle with a legacy fallback for old payloads that carried only
  /// `id` / `battle_id`.
  String get rtdbId => firebaseBattleId.isNotEmpty ? firebaseBattleId : id;

  /// Authoritative question count, falling back to the array when the server
  /// did not publish `total_questions`.
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
      );

  /// Terminal states are spelled differently across the REST payload
  /// (`completed`) and RTDB (`finished`). Both end the battle.
  static bool isBattleStatusTerminal(Object? status) {
    final s = status?.toString().toLowerCase();
    return s == 'finished' || s == 'completed';
  }
}

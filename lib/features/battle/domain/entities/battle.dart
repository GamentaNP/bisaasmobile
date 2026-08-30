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
  });
  final String uid;
  final String displayName;
  final String avatarUrl;
  final int score;
  final int currentIdx;
  final bool finished;
}

@immutable
class BattleQuestion {
  const BattleQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionId,
    required this.points,
  });
  final String id;
  final String text;
  final List<BattleOption> options;
  final String correctOptionId;
  final int points;
}

@immutable
class BattleOption {
  const BattleOption({required this.id, required this.text});
  final String id;
  final String text;
}

@immutable
class BattleMatch {
  const BattleMatch({
    required this.id,
    required this.status,
    this.opponentLabel = 'Searching…',
    this.player1 = const BattlePlayer(uid: 'p1', displayName: 'You', avatarUrl: ''),
    this.player2 = const BattlePlayer(uid: 'p2', displayName: 'Opponent', avatarUrl: ''),
    this.questions = const [],
    this.perQuestionSeconds = 15,
    this.category = 'general',
    this.startedAtMs,
    this.finishedAtMs,
    this.winnerUid,
  });
  final String id;
  final String status; // waiting, starting, in_progress, finished
  final String opponentLabel;
  final BattlePlayer player1;
  final BattlePlayer player2;
  final List<BattleQuestion> questions;
  final int perQuestionSeconds;
  final String category;
  final int? startedAtMs;
  final int? finishedAtMs;
  final String? winnerUid;

  /// Look up "me" by [uid] (defaults to player1).
  BattlePlayer me(String uid) => player1.uid == uid ? player1 : player2;
  BattlePlayer opponent(String uid) => player1.uid == uid ? player2 : player1;
}

// ignore_for_file: strict_raw_type

import '../../domain/entities/battle.dart';
import '../../domain/repositories/battle_repository.dart';
import '../datasources/battle_remote_data_source.dart';

class BattleRepositoryImpl implements BattleRepository {
  const BattleRepositoryImpl(this._remote);
  final BattleRemoteDataSource _remote;

  @override
  Future<BattleToken> getFirebaseToken() async {
    final m = await _remote.getFirebaseToken();
    final token = (m['token'] ?? m['custom_token'] ?? m['firebase_token'] ?? '') as String;
    final expRaw = m['expires_at'] ?? m['expiresAt'];
    DateTime? exp;
    if (expRaw is String) exp = DateTime.tryParse(expRaw);
    return BattleToken(token: token, expiresAt: exp);
  }

  @override
  Future<BattleMatch> findMatch({int? categoryId, int totalQuestions = 10}) async {
    final m = await _remote.findMatch(categoryId: categoryId, totalQuestions: totalQuestions);
    BattlePlayer player(Map? raw) => BattlePlayer(
          uid: (raw?['uid'] ?? '').toString(),
          displayName: (raw?['display_name'] ?? raw?['name'] ?? 'Player').toString(),
          avatarUrl: (raw?['avatar_url'] ?? '').toString(),
          score: (raw?['score'] as int?) ?? 0,
          currentIdx: (raw?['current_idx'] as int?) ?? 0,
          finished: (raw?['finished'] as bool?) ?? false,
        );
    BattleQuestion question(Map raw) => BattleQuestion(
          id: (raw['id'] ?? '').toString(),
          text: (raw['text'] ?? raw['body'] ?? '').toString(),
          options: ((raw['options'] as List?) ?? const [])
              .cast<Map>()
              .map((o) => BattleOption(id: (o['id'] ?? '').toString(), text: (o['text'] ?? '').toString()))
              .toList(),
          // Never read an answer key from the realtime payload. Battles are
          // graded by the server (POST /quiz/battles/{id}/answer) and the RTDB
          // node only carries `is_correct` after the fact. Parsing a key here
          // would put the answer on-device before the answer is given, in the
          // one mode that has coin stakes.
          correctOptionId: '',
          points: (raw['points'] as int?) ?? 10,
        );
    return BattleMatch(
      id: (m['id'] ?? m['battle_id'] ?? m['lobby_id'] ?? 'demo') as String,
      status: (m['status'] ?? 'searching') as String,
      opponentLabel: (m['opponent'] ?? m['opponent_label'] ?? 'Searching…') as String,
      player1: player(m['player1'] as Map?),
      player2: player(m['player2'] as Map?),
      questions: ((m['questions'] as List?) ?? const []).cast<Map>().map(question).toList(),
      perQuestionSeconds: (m['per_question_seconds'] as int?) ?? 15,
      category: (m['category'] ?? 'any') as String,
      startedAtMs: (m['started_at'] as int?) ?? (m['started_at_ms'] as int?),
      finishedAtMs: (m['finished_at'] as int?) ?? (m['finished_at_ms'] as int?),
      winnerUid: m['winner'] as String?,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId) => _remote.getLeaderboard(boardId);
}

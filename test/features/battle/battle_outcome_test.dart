import 'package:bisaasmobile/features/battle/domain/battle_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for a user-facing lie.
///
/// The result screen computed the verdict on-device:
///
///   isWin = winnerUid == null || winnerUid == me.uid || me.score >= opp.score
///
/// A battle the server had not yet resolved (`winner_uid` absent) rendered as
/// "YOU WIN!", and so did a score tie. Both are wrong, and the server already
/// owns the answer via `GET /quiz/battles/{id}/results`.
void main() {
  // Shape from BattleController::results().
  Map<String, dynamic> payload({
    int? winnerId,
    String status = 'completed',
    int p1 = 10,
    int p2 = 10,
  }) {
    return {
      'battle': {
        'id': 1,
        'firebase_battle_id': 'fb-1',
        'category': {'id': 2, 'name': 'Soil Mechanics'},
        'player1': {'id': 100, 'name': 'A', 'score': p1},
        'player2': {'id': 200, 'name': 'B', 'score': p2},
        'winner_id': winnerId,
        'status': status,
        'ended_at': '2026-09-28T10:00:00+00:00',
      },
    };
  }

  group('win / loss / draw', () {
    test('winner is the user', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: 100, p1: 12, p2: 4),
        currentUserId: 100,
      );
      expect(o.result, 'win');
      expect(o.isWin, isTrue);
    });

    test('winner is the opponent', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: 200, p1: 3, p2: 9),
        currentUserId: 100,
      );
      expect(o.result, 'loss');
      expect(o.isLoss, isTrue);
    });

    test('completed with no winner is a draw, NOT a win', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: null, p1: 7, p2: 7),
        currentUserId: 100,
      );
      expect(o.result, 'draw');
      expect(o.isDraw, isTrue);
      expect(o.isWin, isFalse);
    });
  });

  group('an unresolved battle must not be shown as a win', () {
    test('in-progress with no winner is pending', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: null, status: 'in_progress', p1: 10, p2: 10),
        currentUserId: 100,
      );
      expect(o.result, 'pending');
      expect(o.isPending, isTrue);
      expect(o.isWin, isFalse);
      expect(o.isLoss, isFalse);
      expect(o.isDraw, isFalse);
    });

    test('a leading score mid-battle is still pending', () {
      // The old rule would have called this a win purely on the score compare.
      final o = BattleOutcome.fromResults(
        payload(winnerId: null, status: 'in_progress', p1: 10, p2: 0),
        currentUserId: 100,
      );
      expect(o.result, 'pending');
      expect(o.isWin, isFalse);
    });

    test('a missing battle object is pending, never a win', () {
      final o = BattleOutcome.fromResults(const <String, dynamic>{}, currentUserId: 100);
      expect(o.result, 'pending');
      expect(o.isWin, isFalse);
    });

    test('a payload with no status and no winner is pending', () {
      final o = BattleOutcome.fromResults(
        const {
          'battle': {
            'player1': {'id': 100, 'score': 5},
            'player2': {'id': 200, 'score': 1},
          },
        },
        currentUserId: 100,
      );
      expect(o.result, 'pending');
      expect(o.isWin, isFalse);
    });
  });

  group('picks the correct side by user id', () {
    test('the user as player2', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: 200, p1: 3, p2: 9),
        currentUserId: 200,
      );
      expect(o.result, 'win');
      expect(o.userScore, 9);
      expect(o.opponentScore, 3);
      expect(o.opponentName, 'A');
    });

    test('the user as player1', () {
      final o = BattleOutcome.fromResults(
        payload(winnerId: 200, p1: 3, p2: 9),
        currentUserId: 100,
      );
      expect(o.result, 'loss');
      expect(o.userScore, 3);
      expect(o.opponentScore, 9);
      expect(o.opponentName, 'B');
    });
  });

  test('reads the category and end time', () {
    final o = BattleOutcome.fromResults(
      payload(winnerId: 100),
      currentUserId: 100,
    );
    expect(o.categoryName, 'Soil Mechanics');
    expect(o.endedAt, isNotNull);
  });
}

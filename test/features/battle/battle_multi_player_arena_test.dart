import 'package:bisaasmobile/features/battle/domain/entities/battle.dart';
import 'package:bisaasmobile/features/battle/presentation/widgets/battle_score_board.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

void main() {
  testWidgets('arena score board renders every player, grouped by team',
      (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final players = [
      for (var i = 1; i <= 6; i++)
        BattlePlayer(
          uid: 'u$i',
          displayName: 'Player $i',
          avatarUrl: '',
          score: i * 4,
          team: i <= 3 ? 'A' : 'B',
        ),
    ];
    final match = BattleMatch(
      id: 'fb-1',
      status: 'in_progress',
      mode: '3v3',
      players: players,
      questions: const [],
      perQuestionSeconds: 30,
    );

    await tester.pumpWidget(
      localizedApp(
        child: Scaffold(
          body: BattleScoreBoard(
            players: match.allPlayers,
            meUid: 'u1',
            timerPct: 0.5,
            secondsLeft: 15,
            total: 30,
          ),
        ),
      ),
    );

    for (var i = 1; i <= 6; i++) {
      expect(find.text('Player $i'), findsOneWidget);
      expect(find.text(l10n.commonPoints(i * 4)), findsOneWidget);
    }
    expect(find.text(l10n.battleTeamLabel('A')), findsOneWidget);
    expect(find.text(l10n.battleTeamLabel('B')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('a 1v1 payload with no teams still renders the score strip',
      (tester) async {
    final players = [
      const BattlePlayer(uid: 'u1', displayName: '', avatarUrl: '', score: 3),
      const BattlePlayer(uid: 'u2', displayName: 'Rival', avatarUrl: '', score: 7),
    ];
    await tester.pumpWidget(
      localizedApp(
        child: Scaffold(
          body: BattleScoreBoard(
            players: players,
            meUid: 'u1',
            timerPct: 1,
            secondsLeft: 30,
            total: 30,
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

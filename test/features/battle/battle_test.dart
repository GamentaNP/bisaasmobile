import 'package:bisaasmobile/features/battle/domain/entities/battle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BattleToken holds token and expiry', () {
    final t = BattleToken(token: 'tok123', expiresAt: DateTime.parse('2027-01-01T00:00:00Z'));
    expect(t.token, 'tok123');
    expect(t.expiresAt, isNotNull);
  });

  test('BattleMatch holds fields', () {
    const m = BattleMatch(id: 'b1', status: 'searching', opponentLabel: 'Waiting…');
    expect(m.id, 'b1');
    expect(m.status, 'searching');
  });
}

import 'package:meta/meta.dart';

@immutable
class BattleToken {
  const BattleToken({required this.token, required this.expiresAt});
  final String token;
  final DateTime? expiresAt;
}

@immutable
class BattleMatch {
  const BattleMatch({
    required this.id,
    required this.status,
    required this.opponentLabel,
  });
  final String id;
  final String status; // searching, matched, finished
  final String opponentLabel;
}

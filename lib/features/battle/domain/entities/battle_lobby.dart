/// A private battle room and the invitation into it.
///
/// The lobby is created, joined and activated **by the server**
/// (`QuizBattleRoomApiController`, `QuizLobbyApiController`); the client only
/// carries the ids and the code. Every field here comes from a server
/// response — status in particular is never inferred locally, because the
/// lobby state machine (waiting → active → finished) decides whether a battle
/// can start.
library;

class BattleLobby {
  const BattleLobby({
    required this.id,
    required this.code,
    required this.status,
  });

  /// `quiz_lobbies.id` — the path parameter for every later lobby call.
  final int id;

  /// The join code shown to the invited player.
  final String code;

  /// Server-reported state (`waiting`, `active`, `finished`, …).
  final String status;

  factory BattleLobby.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['lobby_id'];
    if (id is! int || id <= 0) {
      throw const FormatException('battle lobby id must be a positive integer');
    }
    final code = json['code'];
    if (code is! String || code.isEmpty) {
      throw const FormatException('battle lobby code is required');
    }
    final status = json['status'];
    return BattleLobby(
      id: id,
      code: code,
      status: status is String && status.isNotEmpty ? status : 'waiting',
    );
  }
}

class BattleInvitation {
  const BattleInvitation({
    required this.notificationId,
    required this.inviteeId,
    required this.inviteeName,
  });

  /// The `system_notifications` id whose acceptance endpoint joins the lobby.
  final int notificationId;

  final int inviteeId;
  final String inviteeName;

  factory BattleInvitation.fromJson(Map<String, dynamic> json) {
    final notificationId = json['notification_id'];
    final inviteeId = json['invitee_id'];
    if (notificationId is! int || notificationId <= 0) {
      throw const FormatException('invitation notification_id is required');
    }
    if (inviteeId is! int || inviteeId <= 0) {
      throw const FormatException('invitation invitee_id is required');
    }
    final name = json['invitee_name'];
    return BattleInvitation(
      notificationId: notificationId,
      inviteeId: inviteeId,
      inviteeName: name is String ? name : '',
    );
  }
}

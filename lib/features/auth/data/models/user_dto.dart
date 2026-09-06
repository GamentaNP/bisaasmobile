import '../../domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.emailVerifiedAt,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // Two wire shapes reach this mapper: a flat user object (login/register
    // responses) and GET /me's envelope {user:{...}, player_hud:{xp, coins,
    // level, streak_days}, ...}. Flatten to the inner user, then fall back to
    // player_hud for the live economy stats the user row doesn't carry.
    final src = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final hud = json['player_hud'] as Map<String, dynamic>?;
    return UserDto(
      id: (src['id'] ?? json['id'] ?? 0) as int,
      name: src['name'] as String? ?? '',
      email: src['email'] as String? ?? '',
      avatarUrl:
          src['avatar_url'] as String? ?? src['avatar'] as String?,
      level: (src['level'] as int?) ?? (hud?['level'] as int?) ?? 1,
      xp: (src['xp'] as int?) ?? (hud?['xp'] as int?) ?? 0,
      coins: (src['coins'] as int?) ?? (hud?['coins'] as int?) ?? 0,
      streakDays: (src['streak_days'] as int?) ??
          (src['streak'] as int?) ??
          (hud?['streak_days'] as int?) ??
          0,
      emailVerifiedAt: src['email_verified_at'] != null
          ? DateTime.tryParse(src['email_verified_at'] as String)
          : null,
      createdAt: src['created_at'] != null
          ? DateTime.tryParse(src['created_at'] as String)
          : null,
    );
  }

  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int coins;
  final int streakDays;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'level': level,
        'xp': xp,
        'coins': coins,
        'streak_days': streakDays,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  User toDomain() => User(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        level: level,
        xp: xp,
        coins: coins,
        streakDays: streakDays,
        emailVerifiedAt: emailVerifiedAt,
        createdAt: createdAt,
      );
}

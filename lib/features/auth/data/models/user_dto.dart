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
    return UserDto(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? json['streak'] as int? ?? 0,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
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

import 'package:meta/meta.dart';

/// Pure Dart User entity (no Flutter, no JSON dependencies).
@immutable
class User {
  const User({
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

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? level,
    int? xp,
    int? coins,
    int? streakDays,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          level == other.level &&
          xp == other.xp &&
          coins == other.coins;

  @override
  int get hashCode => Object.hash(id, name, email, level, xp, coins);
}

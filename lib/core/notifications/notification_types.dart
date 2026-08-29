enum NotificationType {
  quizReminder('quiz_reminder'),
  achievementUnlocked('achievement_unlocked'),
  streakAtRisk('streak_at_risk'),
  battleInvite('battle_invite'),
  system('system'),
  unknown('unknown');

  const NotificationType(this.raw);
  final String raw;

  static NotificationType fromRaw(String? raw) =>
      values.firstWhere((e) => e.raw == raw, orElse: () => unknown);
}

import 'package:flutter/material.dart';

import '../../features/gamification/domain/entities/achievements.dart';

/// Rarity colours are presentation, not server data.
///
/// Both the achievements gallery and the profile badge strip render the same
/// palette. Keeping the mapping here means neither feature imports the other.
extension AchievementRarityColor on AchievementEntry {
  Color get rarityColor {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFEAB308);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'rare':
        return const Color(0xFF22D3EE);
      case 'uncommon':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

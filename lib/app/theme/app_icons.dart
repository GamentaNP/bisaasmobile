library;

import 'package:flutter/material.dart';

/// Single place for icon constants — avoids scattered IconData literals and enables easy swap to custom font.
abstract final class AppIcons {
  // Navigation
  static const IconData home = Icons.home_rounded;
  static const IconData quiz = Icons.quiz_rounded;
  static const IconData calculator = Icons.calculate_rounded;
  static const IconData library = Icons.menu_book_rounded;
  static const IconData profile = Icons.person_rounded;

  // Actions
  static const IconData share = Icons.share_rounded;
  static const IconData bookmark = Icons.bookmark_rounded;
  static const IconData bookmarkBorder = Icons.bookmark_border_rounded;
  static const IconData streak = Icons.local_fire_department_rounded;
  static const IconData trophy = Icons.emoji_events_rounded;
  static const IconData coin = Icons.monetization_on_rounded;

  // States
  static const IconData check = Icons.check_circle_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData offline = Icons.wifi_off_rounded;
}

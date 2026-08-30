// ignore_for_file: unused_local_variable, unawaited_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../../../../app/theme/app_colors.dart';
import 'lottie_overlay.dart';

/// Slide-down toast from the top of the screen. Stays 4 seconds
/// then slides back up. Non-blocking — user can still interact with
/// the screen underneath.
class AchievementUnlockToast extends StatefulWidget {
  const AchievementUnlockToast({
    required this.title,
    required this.description,
    this.iconUrl,
    super.key,
  });
  final String title;
  final String description;
  final String? iconUrl;

  static OverlayEntry? _current;

  static void show(BuildContext context, {required String title, required String description, String? iconUrl}) {
    _current?.remove();
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: AchievementUnlockToast(title: title, description: description, iconUrl: iconUrl),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _current = entry;
  }

  @override
  State<AchievementUnlockToast> createState() => _AchievementUnlockToastState();
}

class _AchievementUnlockToastState extends State<AchievementUnlockToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
    _haptic();
  }

  Future<void> _haptic() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 80, amplitude: 220);
      }
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    AchievementUnlockToast._current?.remove();
    AchievementUnlockToast._current = null;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _dismiss,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.xpGold, AppColors.streakOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Lottie.asset('assets/animations/achievement_unlock.json', fit: BoxFit.contain, repeat: false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Achievement Unlocked!',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(widget.title,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(widget.description,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Combines a [LottieOverlay] and an [AchievementUnlockToast] for
/// server payloads like `QuizResult.achievementsUnlocked[]`.
class GamificationAnnouncer {
  GamificationAnnouncer._();

  static Future<void> announceLevelUp(BuildContext context, {required int newLevel, String? newTitle}) async {
    await LottieOverlay.show(
      context,
      LottieOverlay(
        asset: 'assets/animations/level_up.json',
        title: 'LEVEL UP!',
        subtitle: 'You are now Level $newLevel${newTitle != null ? " · $newTitle" : ""}',
        color: AppColors.xpGold,
      ),
    );
  }

  static void announceAchievement(BuildContext context, {required String title, required String description}) {
    AchievementUnlockToast.show(context, title: title, description: description);
  }
}

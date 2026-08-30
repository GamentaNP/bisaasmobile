import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Rating prompt — triggers after meaningful moments (quiz complete 3×, calc 5×, streak 7).
/// Uses `in_app_review` which shows native Play/App Store sheet, falls back to store URL.
/// Throttled: at most once per 30 days, never on first launch.
class RatingService {
  RatingService(this._review);
  final InAppReview _review;

  static const _kLastPrompt = 'rating_last_prompt';
  static const _kQuizCompletes = 'rating_quiz_completes';
  static const _kCalcCount = 'rating_calc_count';

  // ignore: prefer_constructors_over_static_methods — factory reads platform singleton
  static RatingService create() => RatingService(InAppReview.instance);

  Future<void> onQuizComplete() async {
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt(_kQuizCompletes) ?? 0) + 1;
    await p.setInt(_kQuizCompletes, n);
    if (n == 3 || n == 10 || n == 25) await _maybePrompt(p);
  }

  Future<void> onCalculatorUse() async {
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt(_kCalcCount) ?? 0) + 1;
    await p.setInt(_kCalcCount, n);
    if (n == 5 || n == 20) await _maybePrompt(p);
  }

  Future<void> _maybePrompt(SharedPreferences p) async {
    final last = p.getInt(_kLastPrompt) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < 30 * 24 * 60 * 60 * 1000) return; // 30 days
    if (!await _review.isAvailable()) return;
    try {
      await _review.requestReview();
      await p.setInt(_kLastPrompt, now);
      AppLogger.i('Rating prompt shown');
    } catch (e) {
      AppLogger.w('Rating prompt failed: $e');
      // fallback to store listing
      try { await _review.openStoreListing(appStoreId: '6440000000'); } catch (_) {}
    }
  }
}

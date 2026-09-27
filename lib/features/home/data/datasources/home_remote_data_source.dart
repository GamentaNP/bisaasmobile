// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_response.dart';
import '../models/dashboard_dto.dart';

/// Aggregates Home dashboard from multiple authoritative endpoints.
///
/// Contract per `MOBILE_API_INTEGRATION_GUIDE.md:9`:
/// - `GET /me` → user, roles, subscription, onboarding, flags
/// - `GET /quiz/streak` → streak
/// - `GET /quiz/daily` → daily quiz card
/// - `GET /learning/today` → today plan / active course
///
/// All calls are best-effort; offline → fallback cached/offline preview.
/// Never invents coins/XP — values come from server or fallback shows 0.
class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._dio);
  final Dio _dio;

  // Offline / unreachable fallback. Every field is an honest zero or null:
  // no invented quiz title, no invented XP threshold. The UI renders an
  // "offline" treatment when it sees a zero-streak, un-scheduled, zero-balance
  // payload rather than a fake "Daily Engineering Sprint".
  static const _fallback = DashboardDto(
    streakDays: 0,
    isDailyCompleted: false,
    dailyQuizScheduled: false,
    dailyQuizTitle: null,
    dailyQuizQuestionsCount: 0,
    dailyQuizXpReward: null,
    dailyQuizCoinsReward: null,
    level: 1,
    currentXp: 0,
    nextLevelXp: null,
    coinsBalance: 0,
    activeCourseTitle: null,
    activeCourseProgress: 0,
  );

  Future<DashboardDto> getDashboard() async {
    // Parallel fetches — each isolated so one 404/offline does not kill dashboard.
    final meFuture = _safeGet('/me');
    final streakFuture = _safeGet('/quiz/streak');
    final dailyFuture = _safeGet('/quiz/daily');
    final todayFuture = _safeGet('/learning/today');
    final missionsFuture = _safeGet('/quiz/game/missions/dashboard');

    final results = await Future.wait<Map<String, dynamic>?>([
      meFuture,
      streakFuture,
      dailyFuture,
      todayFuture,
      missionsFuture,
    ]);

    final me = results[0];
    final streak = results[1];
    final daily = results[2];
    final today = results[3];
    final missions = results[4];

    // If all are null we are offline or backend not reachable → fallback.
    if (me == null && streak == null && daily == null && today == null) {
      AppLogger.w('Home dashboard: all remotes null → offline fallback');
      return _fallback;
    }

    // Merge into shape DashboardDto understands.
    // DashboardDto tolerates missing keys; we build a merged map
    // so its fromJson can stay the single SSOT mapper.
    final merged = <String, dynamic>{};

    // /me → {user:{...}, player_hud:{xp,coins,level,streak_days}, ...}
    if (me != null) {
      // me may be {user:{...}} wrapped or flat; the user row itself often
      // lacks economy stats — those live in the sibling player_hud object.
      final user = me['user'] as Map<String, dynamic>? ?? me;
      final hud = me['player_hud'] as Map<String, dynamic>?;
      merged['user'] = {
        'level': user['level'] ?? hud?['level'] ?? me['level'],
        'xp': user['xp'] ?? user['experience'] ?? hud?['xp'] ?? me['xp'],
        'coins': user['coins'] ?? user['wallet_balance'] ?? hud?['coins'] ?? me['coins'],
        'next_level_xp': user['next_level_xp'] ?? me['next_level_xp'],
      };
      // Preserve top-level level etc for legacy fallback paths
      merged['level'] = merged['user']?['level'];
      merged['current_xp'] = merged['user']?['xp'];
      merged['coins_balance'] = merged['user']?['coins'];
      if (me['active_course'] != null) merged['active_course'] = me['active_course'];
    }

    // /quiz/streak → {current, current_streak, best, days}
    if (streak != null) {
      merged['streak'] = {
        'current_streak': streak['current_streak'] ??
            streak['current'] ??
            streak['days'] ??
            streak['streak_days'] ??
            streak['streak'],
      };
      merged['streak_days'] = merged['streak']?['current_streak'];
    }

    // /quiz/daily → {schedule: {...} | null, has_completed: bool}
    // Verified against QuizDailyApiController@today. The schedule is the raw
    // quiz_daily_schedules row (snake_case) and carries NO xp/coin reward, so
    // those stay absent rather than being invented. `has_completed` is the
    // only completion flag — the old code looked for `completed`, so
    // isDailyCompleted was permanently false.
    if (daily != null) {
      final schedule = daily['schedule'] as Map<String, dynamic>?;
      merged['daily_quiz'] = {
        'scheduled': schedule != null,
        'title': schedule?['title'],
        'questions_count': schedule?['question_count'],
        'time_limit_minutes': schedule?['time_limit_minutes'],
        'course_id': schedule?['quiz_course_id'],
        'category_id': schedule?['quiz_category_id'],
        'completed': daily['has_completed'] ?? daily['completed'] ?? false,
      };
    }

    // /learning/today → {active_course, today:{course, progress}}
    if (today != null) {
      final course = today['active_course'] as Map<String, dynamic>? ??
          today['course'] as Map<String, dynamic>? ??
          (today['today'] is Map ? (today['today'] as Map<String, dynamic>)['course'] : null);
      if (course != null) {
        merged['active_course'] = {
          'title': course['title'] ?? course['name'],
          'progress': (course['progress'] ?? course['completion'] ?? 0.0 as num).toDouble(),
        };
      }
      // If today contains plan items, pick first as daily title fallback
      if (merged['daily_quiz'] == null && today['today'] != null) {
        final plan = today['today'];
        if (plan is Map && plan['title'] != null) {
          merged['daily_quiz'] = {
            'title': plan['title'],
            'questions_count': plan['questions_count'] ?? 0,
            'xp_reward': plan['xp_reward'] ?? 0,
            'coins_reward': plan['coins_reward'] ?? 0,
            'completed': plan['completed'] ?? false,
          };
        }
      }
    }

    // /quiz/game/missions/dashboard → streak/missions overlay
    if (missions != null && merged['streak'] == null) {
      final mStreak = missions['streak'] as Map<String, dynamic>?;
      if (mStreak != null) {
        merged['streak'] = {
          'current_streak': mStreak['current_streak'] ?? mStreak['current'],
        };
      }
    }

    try {
      return DashboardDto.fromJson(merged);
    } catch (e, st) {
      AppLogger.w('Dashboard merge parse failed → fallback: $e');
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        AppLogger.d(st);
      }
      return _fallback;
    }
  }

  /// GET `path` returning the `data` envelope or null on any failure.
  /// Never throws — callers decide fallback.
  Future<Map<String, dynamic>?> _safeGet(String path) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      if (res.data == null) return null;
      // Server `data` may be a map OR a list (e.g. missions dashboard
      // returns `data: [ ... ]`) — tolerate both without a cast crash.
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) {
          if (json is Map<String, dynamic>) return json;
          if (json is List<dynamic>) return {'value': json};
          return null;
        },
      );
      if (envelope.data is Map<String, dynamic>) {
        return envelope.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 404/401 on streak/daily during early backend staging is expected — no log spam.
      if (code == 404 || code == 401) return null;
      AppLogger.w('Home _safeGet $path failed $code: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.w('Home _safeGet $path error: $e');
      return null;
    }
  }
}

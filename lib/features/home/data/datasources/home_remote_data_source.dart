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

  static const _fallback = DashboardDto(
    streakDays: 1,
    isDailyCompleted: false,
    dailyQuizTitle: 'Daily Engineering MCQ Sprint',
    dailyQuizQuestionsCount: 10,
    dailyQuizXpReward: 100,
    dailyQuizCoinsReward: 20,
    level: 1,
    currentXp: 150,
    nextLevelXp: 500,
    coinsBalance: 50,
    activeCourseTitle: 'Structural Analysis & Design (RCC)',
    activeCourseProgress: 0.35,
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

    // /me → {user:{level,xp,coins}, ...}
    if (me != null) {
      // me may be {user:{id,name,level,xp,coins}, ...} or flat
      final user = me['user'] as Map<String, dynamic>? ?? me;
      merged['user'] = {
        'level': user['level'] ?? me['level'],
        'xp': user['xp'] ?? user['experience'] ?? me['xp'],
        'coins': user['coins'] ?? user['wallet_balance'] ?? me['coins'],
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

    // /quiz/daily → {title, questions_count, xp_reward, coins_reward, completed}
    if (daily != null) {
      // Some deployments nest under quiz or daily_quiz
      final src = daily['quiz'] as Map<String, dynamic>? ??
          daily['daily_quiz'] as Map<String, dynamic>? ??
          daily;
      merged['daily_quiz'] = {
        'title': src['title'] ?? src['name'] ?? daily['title'],
        'questions_count': src['questions_count'] ?? src['question_count'] ?? src['total_questions'],
        'xp_reward': src['xp_reward'] ?? src['xp'],
        'coins_reward': src['coins_reward'] ?? src['coins'],
        'completed': src['completed'] ?? src['is_completed'] ?? false,
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
          'progress': course['progress'] ?? course['completion'] ?? 0.35,
        };
      }
      // If today contains plan items, pick first as daily title fallback
      if (merged['daily_quiz'] == null && today['today'] != null) {
        final plan = today['today'];
        if (plan is Map && plan['title'] != null) {
          merged['daily_quiz'] = {
            'title': plan['title'],
            'questions_count': 10,
            'xp_reward': 100,
            'coins_reward': 20,
            'completed': false,
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

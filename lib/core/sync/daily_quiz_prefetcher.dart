// ignore_for_file: unawaited_futures

/// Midnight daily-quiz prefetch.
///
/// Warms the Drift `Questions` cache with today's daily quiz so that offline
/// practice has content ready before the user opens the quiz tab. Uses ONLY
/// verified `/api/v1` routes (`GET /quiz/daily` → `GET /quiz/courses/{id}/questions`)
/// and the existing [QuizLocalDataSource.cacheSession] path — it never invents
/// a route and never grades or mints anything locally (server stays
/// authoritative per AGENTS.md boundary rule).
///
/// Scheduling model: an in-app [Timer] that fires at the next local midnight
/// and reschedules itself. True OS-background execution (workmanager /
/// BGTaskScheduler) is intentionally deferred — those native plugins are
/// excluded from the appbundle build (see docs/GOLDEN_PATH_RUNBOOK.md), and a
/// dedicated `GET /api/v1/mobile/daily-quiz-pack` endpoint does not yet exist
/// on the backend (see FLUTTER_SENIOR_REVIEW §6.2 Gap 1). When that endpoint
/// ships, swap `_resolveCourseId` + `_fetchAndCache` to hit it directly.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/quiz/data/datasources/quiz_local_data_source.dart';
import '../../features/quiz/data/datasources/quiz_remote_data_source.dart';
import '../logging/app_logger.dart';

/// Prefetches and caches the daily quiz pack into Drift.
class DailyQuizPrefetcher {
  DailyQuizPrefetcher({
    required Dio dio,
    required QuizRemoteDataSource remote,
    required QuizLocalDataSource local,
    int hourOfDay = 0,
    int minuteOfHour = 0,
    Timer Function(Duration, void Function())? timerFactory,
  })  : _remote = remote,
        _local = local,
        _dio = dio,
        _hourOfDay = hourOfDay,
        _minuteOfHour = minuteOfHour,
        _timerFactory = timerFactory ?? Timer.new;

  final Dio _dio;
  final QuizRemoteDataSource _remote;
  final QuizLocalDataSource _local;
  final int _hourOfDay;
  final int _minuteOfHour;
  final Timer Function(Duration, void Function()) _timerFactory;

  Timer? _timer;
  bool _running = false;
  String? _lastPrefetchedDate;

  /// Starts the recurring midnight prefetch loop. Idempotent.
  void start() {
    if (_running) return;
    _running = true;
    _scheduleNext();
  }

  /// Stops the loop (call on app pause / dispose).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext() {
    if (!_running) return;
    final delay = _durationToNextSlot(DateTime.now());
    AppLogger.i('DailyQuizPrefetch: next run in ${delay.inMinutes} min');
    _timer = _timerFactory(delay, () {
      unawaited(prefetchOnce().whenComplete(_scheduleNext));
    });
  }

  /// Duration until the next local `_hourOfDay:_minuteOfHour` slot (default
  /// midnight). Pure + deterministic so it can be unit-tested.
  Duration _durationToNextSlot(DateTime from) {
    var next = DateTime(from.year, from.month, from.day, _hourOfDay, _minuteOfHour);
    if (!next.isAfter(from)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(from);
  }

  /// Runs one prefetch cycle. Safe to call manually (e.g. right after login).
  /// No-ops when already prefetched for today's date or when offline.
  Future<bool> prefetchOnce() async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    if (_lastPrefetchedDate == key) {
      AppLogger.d('DailyQuizPrefetch: already cached for $key');
      return false;
    }
    try {
      final courseId = await _resolveCourseId();
      if (courseId == null) {
        AppLogger.w('DailyQuizPrefetch: no resolvable course id in /quiz/daily');
        return false;
      }
      await _fetchAndCache(courseId);
      _lastPrefetchedDate = key;
      return true;
    } on DioException catch (e) {
      // Offline / unreachable — expected while device has no network. Stay quiet.
      AppLogger.i('DailyQuizPrefetch skipped (network): ${e.type}');
      return false;
    } catch (e) {
      AppLogger.w('DailyQuizPrefetch failed: $e');
      return false;
    }
  }

  /// Reads `GET /quiz/daily` and tolerantly extracts a course id from the
  /// schedule payload (deployments vary: schedule.quiz_id / course_id / id).
  Future<String?> _resolveCourseId() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/daily');
    final body = res.data;
    if (body == null) return null;
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    final schedule = data['schedule'] is Map<String, dynamic>
        ? data['schedule'] as Map<String, dynamic>
        : data;
    for (final k in const ['quiz_id', 'course_id', 'quiz_course_id', 'id']) {
      final v = schedule[k];
      if (v != null && int.tryParse('$v') != null) return '$v';
    }
    return null;
  }

  /// Fetches the session for [courseId] and persists questions to Drift.
  Future<void> _fetchAndCache(String courseId) async {
    final dto = await _remote.getQuizSession(courseId);
    await _local.cacheSession(dto);
    AppLogger.i('DailyQuizPrefetch: cached ${dto.questions.length} questions '
        'for course $courseId');
  }
}

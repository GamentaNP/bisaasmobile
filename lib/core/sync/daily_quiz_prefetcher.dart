

/// Midnight daily-quiz prefetch.
///
/// Warms the Drift `Questions` cache with today's daily quiz so offline practice
/// has content ready before the user opens the quiz tab.
///
/// Uses `GET /api/v1/mobile/daily-quiz-pack` (`Mobile\DailyQuizPackController`),
/// which returns exactly the published daily questions — id, body, options,
/// image URL — in one call. It deliberately carries **no answer key**, so nothing
/// is ever graded or minted on-device; offline attempts reconcile through the
/// server (AGENTS.md boundary rule).
///
/// This replaced a two-step `GET /quiz/daily` + `GET /quiz/courses/{id}/questions`
/// that guessed a course id from four possible keys and then cached an entire
/// course session — a different question set from the daily quiz. An earlier
/// docblock here claimed the pack endpoint "does not yet exist"; that was stale.
///
/// Scheduling model: an in-app [Timer] that fires at the next local midnight
/// and reschedules itself. True OS-background execution (workmanager /
/// BGTaskScheduler) is still deferred — those native plugins are excluded from
/// the appbundle build (see docs/GOLDEN_PATH_RUNBOOK.md).
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/quiz/data/datasources/quiz_local_data_source.dart';
import '../logging/app_logger.dart';

/// Prefetches and caches the daily quiz pack into Drift.
class DailyQuizPrefetcher {
  DailyQuizPrefetcher({
    required Dio dio,
    required QuizLocalDataSource local,
    int hourOfDay = 0,
    int minuteOfHour = 0,
    Timer Function(Duration, void Function())? timerFactory,
  })  : _local = local,
        _dio = dio,
        _hourOfDay = hourOfDay,
        _minuteOfHour = minuteOfHour,
        _timerFactory = timerFactory ?? Timer.new;

  final Dio _dio;
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
    final now = DateTime.now();
    // Zero-padded because this string is now SENT to the server, which
    // validates `date` with `date_format:Y-m-d`. `${now.month}` yields e.g. 9,
    // producing "2026-9-28" and a 422. It was harmless when the key was only
    // compared in memory.
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_lastPrefetchedDate == key) {
      AppLogger.d('DailyQuizPrefetch: already cached for $key');
      return false;
    }
    try {
      // One call, no guessing. The pack endpoint exists — the previous code
      // read `GET /quiz/daily`, guessed a course id from four possible keys
      // (`quiz_id` / `course_id` / `quiz_course_id` / `id`) and then fetched a
      // whole course session, which is not the same question set as the daily
      // quiz. A docblock here claimed the endpoint "does not yet exist"; that was
      // stale — `Mobile\DailyQuizPackController` ships it.
      final res = await _dio.get<Map<String, dynamic>>(
        '/mobile/daily-quiz-pack',
        queryParameters: {'date': key},
      );
      final data = _packData(res.data);
      if (data == null) {
        AppLogger.w('DailyQuizPrefetch: unparseable pack payload');
        return false;
      }
      final quizId = data['quiz_id'];
      final questions = data['questions'];
      if (quizId == null || questions is! List || questions.isEmpty) {
        // No schedule published for that date — a legitimate state, not a fault.
        AppLogger.i('DailyQuizPrefetch: no daily pack published for $key');
        return false;
      }
      await _local.cacheDailyPack(
        quizId: quizId.toString(),
        questions: questions.whereType<Map<String, dynamic>>().toList(),
      );
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

  /// Unwraps `{success, data:{quiz_id, valid_for_date, already_completed,
  /// questions, question_image_urls}}`, tolerating a bare `data`.
  Map<String, dynamic>? _packData(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  // `_resolveCourseId` and `_fetchAndCache` were removed on 2026-09-28. They
  // read `GET /quiz/daily`, guessed a course id from four possible keys and then
  // pulled an entire course session — which is not the daily quiz's question set.
  // `GET /api/v1/mobile/daily-quiz-pack` (Mobile\DailyQuizPackController) returns
  // exactly today's questions, with no answer key, in one call.
}

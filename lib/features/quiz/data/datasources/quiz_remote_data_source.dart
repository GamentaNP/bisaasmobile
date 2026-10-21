// ignore_for_file: omit_local_variable_types, unnecessary_lambdas, use_null_aware_elements

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../models/attempt_dto.dart';
import '../models/quiz_dto.dart';
import '../models/quiz_funnel_dto.dart';
import '../../../../app/localization/l10n.dart';

/// Verified server routes (`php artisan route:list --path=api/v1` in C:\laragon\www\bisaas):
/// - GET  /quiz/courses                          → list courses (public catalog)
/// - GET  /quiz/courses/{course}/questions       → cursor-paginated questions for course (AUTH)
/// - GET  /quiz/questions                        → cursor-paginated cross-domain search (AUTH)
/// - POST /quiz/attempts/start                   → start attempt (auth, Idempotency-Key)
/// - POST /quiz/attempts/{attempt}/answer        → submit answer (auth, {question_id:int, answer:string})
/// - POST /quiz/attempts/{attempt}/complete      → complete + score (auth)
/// - GET  /quiz/attempts/{attempt}/results       → results detail (auth)
/// - GET  /quiz/attempts/history                 → cursor-paginated history (auth)
///
/// The question corpus requires a credential (server security plan W0.1) and is
/// throttled on its own bucket: 30/min, 300/hr, 1500/day. Only the catalog is
/// public, and it carries no question text.
///
/// **Cursor pagination.** `MOBILE_API_INTEGRATION_GUIDE.md` §4.1 moved
/// `/quiz/questions`, `/quiz/courses/{course}/questions` and
/// `/quiz/attempts/history` to the cursor shape; the server already defaults
/// to it (`ServesQuestionCollections::wantsCursorPagination`). Sending
/// `?page=2` to a cursor endpoint returns page one forever, so this data source
/// never sends `page` to those routes — it walks `next_cursor` instead.
///
/// Dio baseUrl already ends with /api/v1 — never add prefix.
/// All POSTs carry Idempotency-Key per-request via Options (never global).
class QuizRemoteDataSource {
  const QuizRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  /// Page size used when walking the cursor collection. The server caps
  /// `per_page` at 100 for the question collections.
  static const _perPage = 50;


  // ── Courses as quiz list (server has no /quiz/quizzes) ────────────────────

  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug}) async {
    // subjectSlug maps to course slug filter if needed — currently ignored, returns all courses
    final res = await _dio.get<Map<String, dynamic>>('/quiz/courses');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty course catalog response', endpoint: '/quiz/courses');
    }
    // Envelope: {success, data: [...], message, ...}
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    throw ContractViolation(
      'Expected a course list under `data`',
      endpoint: '/quiz/courses',
    );
  }

  // ── Session: questions for a course → QuizSessionDto ───────────────────────

  /// Builds a playable session for [quizId].
  ///
  /// [questionLimit] caps how many questions are pulled. The session seeds the
  /// attempt with exactly the question ids it fetched (the server grades those
  /// ids), so the cap is a deliberate product limit, not a pagination
  /// artefact — the walk underneath it is a full cursor walk, so the cap is
  /// never the reason a course looks empty.
  Future<QuizSessionDto> getQuizSession(
    String quizId, {
    int? categoryId,
    int questionLimit = 20,
  }) async {
    // quizId is courseId (string int) from getQuizList
    final courseId = int.tryParse(quizId);
    if (courseId != null) {
      var raw = await getCourseQuestions(
        courseId,
        categoryId: categoryId,
        limit: questionLimit,
      );

      if (raw.isEmpty) {
        // Fallback: try global search if course has no questions
        raw = await getQuestionSearch(
          search: null,
          courseId: courseId,
          limit: questionLimit,
        );
      }

      final questions = raw.map((j) {
        // Map QuizQuestionResource shape → QuestionDto shape
        // Resource: {id:int, question_text:string, options:list, difficulty:string, points:int}
        // Dto expects: {id:string, body:string, options:[{id,text,position}], difficulty:int, marks_positive:int}
        final id = (j['id'] ?? '').toString();
        final body = (j['question_text'] ?? j['body'] ?? '') as String;
        final opts = j['options'];
        final optList = <Map<String, dynamic>>[];
        if (opts is List) {
          for (var i = 0; i < opts.length; i++) {
            final o = opts[i];
            if (o is Map<String, dynamic>) {
              optList.add({
                'id': (o['id'] ?? o['key'] ?? o['value'] ?? 'opt_$i').toString(),
                'text': (o['text'] ?? o['label'] ?? o['value'] ?? '').toString(),
                'position': o['position'] is int ? o['position'] : i,
              });
            } else if (o is String) {
              optList.add({'id': 'opt_$i', 'text': o, 'position': i});
            }
          }
        }
        // difficulty: string easy|medium|hard → int 1|2|3
        int diff = 1;
        final d = j['difficulty'];
        if (d is int) diff = d;
        if (d is String) {
          if (d == 'medium') diff = 2;
          if (d == 'hard') diff = 3;
          if (d == 'expert') diff = 4;
        }
        return {
          'id': id,
          'body': body,
          'options': optList,
          'subject_slug': (j['course'] is Map ? (j['course'] as Map)['slug'] : null) ?? '',
          'difficulty': diff,
          'marks_positive': (j['points'] as int?) ?? 4,
          'marks_negative': 0,
          // Answer keys and explanations are never read from a pre-answer
          // response. The server does not send them (QuizQuestionResource
          // exposure policy) and the client must not be built to accept them:
          // an ingestion point here is what turns one careless API change into
          // a published answer bank. They arrive only from the results stage,
          // or from an encrypted offline pack (security plan W4.8).
          'explanation': null,
          'correct_option_id': null,
          'quiz_id': quizId,
        };
      }).toList();

      // Fetch course name for title
      var title = 'Quiz';
      try {
        final courses = await getQuizList();
        for (final c in courses) {
          if ((c['id']?.toString() ?? '') == quizId) {
            title = (c['name'] ?? c['title'] ?? 'Quiz') as String;
            break;
          }
        }
      } catch (_) {
        // The title is cosmetic; a failed catalog read must not fail the
        // session. The questions themselves are already in hand.
      }

      return QuizSessionDto(
        id: quizId,
        title: title,
        questions: questions.map((m) => QuestionDto.fromJson(m)).toList(),
        durationSeconds: questions.length * 90, // 90s per question default
        subjectSlug: null,
      );
    }

    // Non-numeric quizId — fallback to global search
    final raw = await getQuestionSearch(search: quizId, limit: questionLimit);
    return QuizSessionDto(
      id: quizId,
      title: appL10n().quiz,
      questions: raw.map((j) => QuestionDto.fromJson({
            'id': (j['id'] ?? '').toString(),
            'body': (j['question_text'] ?? '') as String,
            'options': j['options'],
            'difficulty': 1,
          })).toList(),
      durationSeconds: 20 * 60,
    );
  }

  // ── Funnel (guest tier) ────────────────────────────────────────────────────

  /// The authenticated guest-tier funnel bundle.
  ///
  /// `GET /quiz/funnel?item_limit=8` — the same public bundle the web
  /// carousel renders: sampled public questions, live taxonomy counts and a
  /// fresh-content promo. Never answer keys.
  ///
  /// The server validates `item_limit` as 1..12 and answers 422 when it is
  /// out of range — never a silent clamp.
  Future<QuizFunnelDto> getFunnel({int itemLimit = 8}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/funnel',
      queryParameters: {'item_limit': itemLimit},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty funnel response',
        endpoint: '/quiz/funnel',
      );
    }
    final data = requireDataMap(body, endpoint: '/quiz/funnel');
    return QuizFunnelDto.fromJson(data);
  }

  /// The public guest funnel bundle.
  ///
  /// `GET /quiz/guest-funnel?item_limit=8` — the pre-registration sampler.
  /// The guest ceiling is 8; anything above it is a 422.
  Future<QuizFunnelDto> getGuestFunnel({int itemLimit = 8}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/guest-funnel',
      queryParameters: {'item_limit': itemLimit},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty guest funnel response',
        endpoint: '/quiz/guest-funnel',
      );
    }
    final data = requireDataMap(body, endpoint: '/quiz/guest-funnel');
    return QuizFunnelDto.fromJson(data);
  }

  // ── Cursor walks ────────────────────────────────────────────────────────────

  /// Walks `GET /quiz/courses/{courseId}/questions` until [limit] questions
  /// are collected or the cursor runs out.
  ///
  /// The endpoint is cursor-paginated (`MOBILE_API_INTEGRATION_GUIDE.md` §4.1);
  /// `next_cursor` is opaque and is round-tripped verbatim.
  Future<List<Map<String, dynamic>>> getCourseQuestions(
    int courseId, {
    int? categoryId,
    int limit = 100,
    int perPage = _perPage,
  }) async {
    final collected = <Map<String, dynamic>>[];
    String? cursor;

    while (collected.length < limit) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/quiz/courses/$courseId/questions',
        queryParameters: cursorQuery(
          cursor: cursor,
          perPage: perPage,
          extra: {
            if (categoryId != null) 'category_id': categoryId,
          },
        ),
      );
      final body = res.data;
      if (body == null) break;

      final page = parsePage<Map<String, dynamic>>(
        body,
        (row) => row,
        endpoint: '/quiz/courses/$courseId/questions',
      );
      collected.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;

      final next = page.nextCursor;
      if (next == null || next.isEmpty) break;
      cursor = next;
    }

    if (collected.length > limit) {
      return collected.sublist(0, limit);
    }
    return collected;
  }

  /// Walks `GET /quiz/questions` until [limit] questions are collected or the
  /// cursor runs out.
  ///
  /// The canonical filter grammar is `filter[<name>]`; the bare spellings are
  /// legacy aliases the server still honours
  /// (`LibraryApiController`, `QuizQuestionApiController`).
  Future<List<Map<String, dynamic>>> getQuestionSearch({
    String? search,
    int? courseId,
    int? categoryId,
    String? difficulty,
    int limit = 100,
    int perPage = _perPage,
  }) async {
    final collected = <Map<String, dynamic>>[];
    String? cursor;

    while (collected.length < limit) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/quiz/questions',
        queryParameters: cursorQuery(
          cursor: cursor,
          perPage: perPage,
          extra: {
            if (search != null && search.isNotEmpty) 'search': search,
            if (courseId != null) 'course_id': courseId,
            if (categoryId != null) 'category_id': categoryId,
            if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
          },
        ),
      );
      final body = res.data;
      if (body == null) break;

      final page = parsePage<Map<String, dynamic>>(
        body,
        (row) => row,
        endpoint: '/quiz/questions',
      );
      collected.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;

      final next = page.nextCursor;
      if (next == null || next.isEmpty) break;
      cursor = next;
    }

    if (collected.length > limit) {
      return collected.sublist(0, limit);
    }
    return collected;
  }

  // ── Start attempt ──────────────────────────────────────────────────────────

  Future<String> startAttempt({
    required String quizId,
    String? idempotencyKey,
    List<int>? questionIds,
    int questionCount = 20,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final courseId = int.tryParse(quizId);
    // question_ids is the only seeding mode this client may use: the server
    // grades exactly the ids sent here, so they must be the session's own
    // questions. course_id/question_count is the degenerate fallback when the
    // session somehow yielded none.
    final noIds = questionIds == null || questionIds.isEmpty;
    final data = <String, dynamic>{
      if (!noIds) 'question_ids': questionIds,
      if (noIds && courseId != null) 'course_id': courseId,
      if (noIds) 'question_count': questionCount,
      'mode': 'standard',
    };

    final res = await _dio.post<Map<String, dynamic>>(
      // Canonical resource form. `/quiz/attempts/start` is registered as
      // `attempts.start.transition-alias` and is additive-only until the
      // grammar freeze (routes/api/v1/quiz.php:174-179).
      '/quiz/attempts',
      data: data,
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) throw Exception('Attempt ID missing from server response');
    Map<String, dynamic>? d;
    if (body['data'] is Map<String, dynamic>) {
      d = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        d = env.data;
      } catch (_) {}
    }
    if (d == null) throw Exception('Attempt ID missing');
    final id = d['attempt_id'] ?? d['id'] ?? d['attemptId'];
    if (id == null) throw Exception('Attempt ID missing from server response');
    return id.toString();
  }

  // ── Submit answer ──────────────────────────────────────────────────────────

  Future<AttemptResultDto> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
    String? idempotencyKey,
    int? timeTakenSeconds,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final qId = int.tryParse(questionId) ?? questionId;
    // Backend expects {question_id:int, answer:string, time_taken_seconds?:int}
    // per SubmitAnswerRequest. The duration is the server's integrity signal, so
    // it is measured per question on-device and sent on every answer.
    final res = await _dio.post<Map<String, dynamic>>(
      // Canonical plural collection form; the singular `/answer` is
      // `attempts.answer.transition-alias` (quiz.php:181-186).
      '/quiz/attempts/$attemptId/answers',
      data: <String, dynamic>{
        'question_id': qId is int ? qId : int.tryParse(questionId) ?? questionId,
        'answer': selectedOptionId,
        if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    // The API answer endpoint always answers {success:true, message} with no
    // data — grading is computed but withheld until complete/results (server
    // exposure policy). Empty correctOptionId is the pending marker the
    // attempt screen renders as a neutral "submitted" state, never as
    // right/wrong.
    if (body == null) {
      return AttemptResultDto(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: 'Answer saved — the breakdown unlocks on the results screen.',
      );
    }
    Map<String, dynamic>? d;
    if (body['data'] is Map<String, dynamic>) {
      d = body['data'] as Map<String, dynamic>;
    }
    if (d == null || d.isEmpty) {
      return AttemptResultDto(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: 'Answer saved — the breakdown unlocks on the results screen.',
      );
    }
    // If server ever returns grading payload, map it
    try {
      return AttemptResultDto.fromJson({
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
        'is_correct': d['is_correct'] ?? d['isCorrect'] ?? false,
        'xp_earned': d['xp_earned'] ?? 0,
        'coins_earned': d['coins_earned'] ?? 0,
        'correct_option_id': d['correct_option_id'] ?? '',
        'explanation': d['explanation'],
      });
    } catch (_) {
      return AttemptResultDto(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: 'Answer saved — the breakdown unlocks on the results screen.',
      );
    }
  }

  // ── Complete attempt ───────────────────────────────────────────────────────

  Future<QuizResultDto> finishAttempt(String attemptId) async {
    // Idempotency-Key is mandatory on completion (server 422s without it —
    // same middleware as start/answer).
    final res = await _dio.put<Map<String, dynamic>>(
      // Canonical transition verb is PUT; the POST `/complete` form is
      // `attempts.complete.transition-alias` (quiz.php:187-192).
      '/quiz/attempts/$attemptId/completion',
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/quiz/attempts/{attempt}/completion',
      );
    }
    Map<String, dynamic>? d;
    if (body['data'] is Map<String, dynamic>) {
      d = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        d = env.data;
      } on Object catch (e) {
        throw ContractViolation(
          'Quiz result payload not understood: $e',
          endpoint: '/quiz/attempts/{attempt}/completion',
        );
      }
    }
    if (d == null) {
      throw const ContractViolation(
        'Quiz result payload not understood',
        endpoint: '/quiz/attempts/{attempt}/completion',
      );
    }
    // Backend complete returns {attempt_id, score, correct_count, wrong_count, skipped_count, completed_at}
    // Map to QuizResultDto tolerant shape: totalQuestions, correctAnswers, etc.
    final correct = (d['correct_count'] as int?) ?? (d['correct'] as int?) ?? 0;
    final wrong = (d['wrong_count'] as int?) ?? (d['wrong'] as int?) ?? 0;
    final skipped = (d['skipped_count'] as int?) ?? (d['skipped'] as int?) ?? 0;
    // The total is the sum of what the server counted. It used to fall back to
    // a hard-coded 20, which meant a user who skipped 17 of 20 questions saw
    // "3 of 3 correct" and a 100 % accuracy ring. The client does not know
    // how many questions the attempt had, so it reports what it can count.
    final total = (d['total_questions'] as int?) ??
        (d['total'] as int?) ??
        (correct + wrong + skipped);
    return QuizResultDto.fromJson({
      'attempt_id': (d['attempt_id'] ?? d['id'] ?? attemptId).toString(),
      'stats': {
        'total_questions': total,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
      },
      'total_xp_earned': d['total_xp_earned'] ?? d['xp_earned'] ?? 0,
      'total_coins_earned': d['total_coins_earned'] ?? d['coins_earned'] ?? 0,
      'duration_seconds': d['duration_seconds'] ?? 0,
    });
  }

  // ── Results detail (optional) ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAttemptResults(String attemptId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/attempts/$attemptId/results');
    final body = res.data;
    if (body == null) {
  throw const ContractViolation(
    'Empty response body',
  );
}
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      return env.data;
    } catch (_) {
      return null;
    }
  }
}

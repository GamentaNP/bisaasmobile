// ignore_for_file: omit_local_variable_types, unnecessary_lambdas, unnecessary_non_null_assertion, use_null_aware_elements, avoid_dynamic_calls

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/attempt_dto.dart';
import '../models/quiz_dto.dart';

/// Verified server routes (`php artisan route:list --path=api/v1` in C:\laragon\www\bisaas):
/// - GET  /quiz/courses                          → list courses (public)
/// - GET  /quiz/courses/{course}/questions       → paginated questions for course (public)
/// - GET  /quiz/questions                        → cross-domain search (public)
/// - POST /quiz/attempts/start                   → start attempt (auth, Idempotency-Key)
/// - POST /quiz/attempts/{attempt}/answer        → submit answer (auth, {question_id:int, answer:string})
/// - POST /quiz/attempts/{attempt}/complete      → complete + score (auth)
/// - GET  /quiz/attempts/{attempt}/results       → results detail (auth)
/// - GET  /quiz/attempts/history                 → offset paginated history (auth)
///
/// Dio baseUrl already ends with /api/v1 — never add prefix.
/// All POSTs carry Idempotency-Key per-request via Options (never global).
class QuizRemoteDataSource {
  const QuizRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  // ── Courses as quiz list (server has no /quiz/quizzes) ────────────────────

  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug}) async {
    // subjectSlug maps to course slug filter if needed — currently ignored, returns all courses
    final res = await _dio.get<Map<String, dynamic>>('/quiz/courses');
    final body = res.data;
    if (body == null) return [];
    // Envelope: {success, data: [...], message, ...}
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return json.cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return env.data ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Session: questions for a course → QuizSessionDto ───────────────────────

  Future<QuizSessionDto> getQuizSession(String quizId) async {
    // quizId is courseId (string int) from getQuizList
    final courseId = int.tryParse(quizId);
    if (courseId != null) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/quiz/courses/$courseId/questions',
        queryParameters: {'per_page': 20},
      );
      final body = res.data;
      if (body == null) throw Exception('Quiz session data missing');

      // Paginated envelope: data: {items: [...], pagination: ...} OR data: [...]
      List<Map<String, dynamic>> raw = [];
      if (body['data'] is Map<String, dynamic>) {
        final d = body['data'] as Map<String, dynamic>;
        if (d['items'] is List) raw = (d['items'] as List).cast<Map<String, dynamic>>();
      } else if (body['data'] is List) {
        raw = (body['data'] as List).cast<Map<String, dynamic>>();
      } else {
        try {
          final env = ApiResponse.fromJson(body, (json) {
            if (json is List) return json.cast<Map<String, dynamic>>();
            if (json is Map<String, dynamic> && json['items'] is List) {
              return (json['items'] as List).cast<Map<String, dynamic>>();
            }
            return <Map<String, dynamic>>[];
          });
          raw = env.data ?? [];
        } catch (_) {}
      }

      if (raw.isEmpty) {
        // Fallback: try global search if course has no questions
        final fb = await _dio.get<Map<String, dynamic>>(
          '/quiz/questions',
          queryParameters: {'per_page': 20, 'course_id': courseId},
        );
        final fbData = fb.data?['data'];
        if (fbData is Map<String, dynamic> && fbData['items'] is List) {
          raw = (fbData['items'] as List).cast<Map<String, dynamic>>();
        } else if (fbData is List) {
          raw = fbData.cast<Map<String, dynamic>>();
        }
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
          'explanation': j['explanation'],
          'correct_option_id': j['correct_option_id'],
          'quiz_id': quizId,
        };
      }).toList();

      // Fetch course name for title
      var title = 'Quiz';
      try {
        final courseRes = await _dio.get<Map<String, dynamic>>('/quiz/courses');
        final courses = courseRes.data?['data'];
        if (courses is List) {
          for (final c in courses.cast<Map<String, dynamic>>()) {
            if ((c['id']?.toString() ?? '') == quizId) {
              title = (c['name'] ?? c['title'] ?? 'Quiz') as String;
              break;
            }
          }
        }
      } catch (_) {}

      return QuizSessionDto(
        id: quizId,
        title: title,
        questions: questions.map((m) => QuestionDto.fromJson(m)).toList(),
        durationSeconds: questions.length * 90, // 90s per question default
        subjectSlug: null,
      );
    }

    // Non-numeric quizId — fallback to global search
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/questions',
      queryParameters: {'per_page': 20, 'search': quizId},
    );
    final body = res.data;
    final raw = <Map<String, dynamic>>[];
    if (body?['data'] is Map && (body!['data'] as Map)['items'] is List) {
      raw.addAll(((body!['data'] as Map)['items'] as List).cast<Map<String, dynamic>>());
    } else if (body?['data'] is List) {
      raw.addAll((body!['data'] as List).cast<Map<String, dynamic>>());
    }
    return QuizSessionDto(
      id: quizId,
      title: 'Quiz',
      questions: raw.map((j) => QuestionDto.fromJson({
            'id': (j['id'] ?? '').toString(),
            'body': (j['question_text'] ?? '') as String,
            'options': j['options'],
            'difficulty': 1,
          })).toList(),
      durationSeconds: 20 * 60,
    );
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
    final data = <String, dynamic>{
      if (questionIds != null && questionIds.isNotEmpty) 'question_ids': questionIds,
      if (questionIds == null || questionIds.isEmpty)
        if (courseId != null) 'course_id': courseId,
      if (questionIds == null || questionIds.isEmpty) 'question_count': questionCount,
      'mode': 'standard',
    };

    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/start',
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
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final qId = int.tryParse(questionId) ?? questionId;
    // Backend expects {question_id:int, answer:string} per SubmitAnswerRequest:23
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/answer',
      data: {
        'question_id': qId is int ? qId : int.tryParse(questionId) ?? questionId,
        'answer': selectedOptionId,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    // Backend answer endpoint returns {success:true, message} with no data for exam modes.
    // Return synthetic pending result; real grading happens on complete.
    if (body == null) {
      return AttemptResultDto(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: null,
      );
    }
    Map<String, dynamic>? d;
    if (body['data'] is Map<String, dynamic>) {
      d = body['data'] as Map<String, dynamic>;
    }
    if (d == null || d.isEmpty) {
      // No grading data — synthetic (server will grade on complete)
      return AttemptResultDto(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        isCorrect: false,
        xpEarned: 0,
        coinsEarned: 0,
        correctOptionId: '',
        explanation: null,
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
        explanation: null,
      );
    }
  }

  // ── Complete attempt ───────────────────────────────────────────────────────

  Future<QuizResultDto> finishAttempt(String attemptId) async {
    final res = await _dio.post<Map<String, dynamic>>('/quiz/attempts/$attemptId/complete');
    final body = res.data;
    if (body == null) throw Exception('Quiz result missing');
    Map<String, dynamic>? d;
    if (body['data'] is Map<String, dynamic>) {
      d = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
        d = env.data;
      } catch (_) {}
    }
    if (d == null) throw Exception('Quiz result missing');
    // Backend complete returns {attempt_id, score, correct_count, wrong_count, skipped_count, completed_at}
    // Map to QuizResultDto tolerant shape: totalQuestions, correctAnswers, etc.
    final correct = (d['correct_count'] as int?) ?? (d['correct'] as int?) ?? 0;
    final wrong = (d['wrong_count'] as int?) ?? (d['wrong'] as int?) ?? 0;
    final skipped = (d['skipped_count'] as int?) ?? (d['skipped'] as int?) ?? 0;
    final total = correct + wrong + skipped == 0 ? 20 : correct + wrong + skipped;
    return QuizResultDto.fromJson({
      'attempt_id': (d['attempt_id'] ?? d['id'] ?? attemptId).toString(),
      'stats': {
        'total_questions': total,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
      },
      'total_xp_earned': 0,
      'total_coins_earned': 0,
      'duration_seconds': 0,
    });
  }

  // ── Results detail (optional) ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAttemptResults(String attemptId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/attempts/$attemptId/results');
    final body = res.data;
    if (body == null) return null;
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      return env.data;
    } catch (_) {
      return null;
    }
  }
}

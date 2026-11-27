import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../core/consent/consent_gate.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../app/providers.dart';
import '../../data/datasources/battle_remote_data_source.dart';
import '../../data/models/battle_payload.dart';
import '../../data/repositories/battle_repository_impl.dart';
import '../../domain/entities/battle.dart';
import '../../domain/repositories/battle_repository.dart';

final battleRemoteDataSourceProvider = Provider<BattleRemoteDataSource>((ref) {
  return BattleRemoteDataSource(ref.watch(dioProvider));
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return BattleRepositoryImpl(ref.watch(battleRemoteDataSourceProvider));
});

/// Errors are rendered from the locale, never by printing `e.toString()` —
/// a raw `ContractViolation(...)` or Dio message is not a user-facing copy.
String battleErrorMessage(Object error) {
  final l = appL10n();
  if (error is ContractViolation) return l.errContractDrift;
  if (error is ApiException) {
    return switch (error.code) {
      ApiErrorCode.authUnauthenticated ||
      ApiErrorCode.authTokenExpired ||
      ApiErrorCode.authTokenRevoked => l.errSessionExpired,
      ApiErrorCode.rateLimitExceeded => l.errRateLimited,
      ApiErrorCode.maintenanceMode => l.errMaintenance,
      ApiErrorCode.notFound => l.errNotFound,
      ApiErrorCode.validationError => l.errValidationRejected,
      ApiErrorCode.serviceUnavailable ||
      ApiErrorCode.internalError => l.errUnreachable,
      ApiErrorCode.insufficientCoins => l.errInsufficientCoins,
      ApiErrorCode.forbidden => l.errForbidden,
      _ => l.errRequestFailed,
    };
  }
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => l.errTimeout,
      DioExceptionType.connectionError => l.errUnreachable,
      DioExceptionType.badCertificate => l.errBadCertificate,
      DioExceptionType.cancel => l.errCancelled,
      _ => l.errRequestFailed,
    };
  }
  return l.errRequestFailed;
}

enum BattlePhase { idle, fetchingToken, connectingFirebase, searching, countdown, inProgress, answered, finished, error }

class BattleState {
  const BattleState({
    this.phase = BattlePhase.idle,
    this.token,
    this.match,
    this.currentQuestionIndex = 0,
    this.selectedOptionId,
    this.opponentAnsweredThisQ = false,
    this.secondsLeftInQuestion = 0,
    this.error,
    this.winnerUid,
    this.myUid,
  });
  final BattlePhase phase;
  final BattleToken? token;
  final BattleMatch? match;
  final int currentQuestionIndex;
  final String? selectedOptionId;
  final bool opponentAnsweredThisQ;
  final int secondsLeftInQuestion;
  final String? error;
  final String? winnerUid;

  /// Firebase uid of the signed-in user, or the canonical `me.uid` when the
  /// SDK could not report one. Screens use it to mark "You" in a team roster.
  final String? myUid;

  /// Sentinel so an explicitly-passed `null` still clears a field. Every
  /// non-nullable-safe field in [BattleState] needs this: a bare
  /// `error: null` means "clear the error" at call sites like
  /// `copyWith(phase: BattlePhase.fetchingToken, error: null)`, so plain
  /// `error ?? this.error` would make that clear impossible and
  /// `error: this.error` would wipe the winner on the next unrelated update.
  static const Object _unset = Object();

  BattleState copyWith({
    BattlePhase? phase,
    BattleToken? token,
    BattleMatch? match,
    int? currentQuestionIndex,
    String? selectedOptionId,
    bool? opponentAnsweredThisQ,
    int? secondsLeftInQuestion,
    Object? error = _unset,
    Object? winnerUid = _unset,
    String? myUid,
  }) =>
      BattleState(
        phase: phase ?? this.phase,
        token: token ?? this.token,
        match: match ?? this.match,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        selectedOptionId: selectedOptionId ?? this.selectedOptionId,
        opponentAnsweredThisQ: opponentAnsweredThisQ ?? this.opponentAnsweredThisQ,
        secondsLeftInQuestion: secondsLeftInQuestion ?? this.secondsLeftInQuestion,
        error: identical(error, _unset) ? this.error : error as String?,
        winnerUid: identical(winnerUid, _unset) ? this.winnerUid : winnerUid as String?,
        myUid: myUid ?? this.myUid,
      );
}

class BattleController extends Notifier<BattleState> {
  StreamSubscription<DatabaseEvent>? _rtdbSub;
  Timer? _ticker;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  String? _myUid;

  /// One clock anchor per match. A battle created before join has
  /// `started_at: null`; re-reading `DateTime.now()` in every tick would keep
  /// resetting the question index to zero.
  DateTime? _clockAnchor;

  /// Last matchmaking parameters, kept so an error state can offer a real
  /// retry instead of dropping the user back to a fresh screen.
  int? _lastCategoryId;
  int _lastTotalQuestions = 10;
  String _lastMode = '1v1';

  @override
  BattleState build() {
    ref.onDispose(() {
      _rtdbSub?.cancel();
      _ticker?.cancel();
    });
    return const BattleState();
  }

  Future<void> fetchToken() async {
    state = state.copyWith(phase: BattlePhase.fetchingToken, error: null);
    try {
      final repo = ref.read(battleRepositoryProvider);
      final t = await repo.getFirebaseToken();
      if (t.token.isEmpty) throw const ContractViolation('Empty Firebase token');
      state = state.copyWith(phase: BattlePhase.idle, token: t);
      try {
        await ref.read(analyticsProvider).log(
              AnalyticsEvents.battleMatchSearch,
              params: {'step': 'token_fetched'},
            );
      } catch (_) {}
    } on Object catch (e) {
      state = state.copyWith(
        phase: BattlePhase.error,
        error: battleErrorMessage(e),
      );
    }
  }

  /// Signs in with the **fresh** token just returned by create/join. A failure
  /// is terminal for this attempt: the arena cannot follow RTDB anonymously.
  /// It is surfaced as localized copy and the UI offers Retry.
  Future<void> _connectFirebase(String token) async {
    state = state.copyWith(phase: BattlePhase.connectingFirebase, error: null);
    if (token.isEmpty) {
      throw const ContractViolation('Battle payload has no firebase token');
    }
    final cred = await _auth.signInWithCustomToken(token);
    _myUid = cred.user?.uid;
  }

  Future<void> findMatch({
    int? categoryId,
    int totalQuestions = 10,
    String mode = '1v1',
  }) async {
    _lastCategoryId = categoryId;
    _lastTotalQuestions = totalQuestions;
    _lastMode = mode;
    state = state.copyWith(phase: BattlePhase.searching, error: null, match: null);
    try {
      try {
        await ref.read(analyticsProvider).log(
              AnalyticsEvents.battleMatchSearch,
              params: {'category': categoryId?.toString() ?? 'any', 'mode': mode},
            );
      } catch (_) {}

      final repo = ref.read(battleRepositoryProvider);
      final m = await repo.findMatch(
        categoryId: categoryId,
        totalQuestions: totalQuestions,
        mode: mode,
      );

      // The fresh token from create/join is the only credential accepted by
      // signInWithCustomToken. The repository fails closed when it is absent.
      final token = m.firebaseToken;
      await _connectFirebase(token);
      _clockAnchor = m.startedAt ?? DateTime.now();
      state = state.copyWith(
        token: BattleToken(token: token, expiresAt: null),
        match: m,
        myUid: m.meUid.isNotEmpty ? m.meUid : _myUid,
      );

      if (m.questions.isEmpty) {
        // The battle exists but the questions node is not published yet.
        // Stay in matchmaking and let the RTDB snapshot promote us.
        _subscribeRtdb(m);
        return;
      }
      state = state.copyWith(phase: BattlePhase.inProgress, currentQuestionIndex: 0);
      try {
        await ref.read(analyticsProvider).log(
              AnalyticsEvents.battleMatchFound,
              params: {'match_id': m.rtdbId},
            );
      } catch (_) {}
      _subscribeRtdb(m);
    } on Object catch (e, st) {
      AppLogger.w('battle matchmaking failed: $e', e, st);
      state = state.copyWith(
        phase: BattlePhase.error,
        error: battleErrorMessage(e),
      );
    }
  }

  /// Re-runs the last matchmaking attempt with the same mode and questions.
  Future<void> retry() => findMatch(
        categoryId: _lastCategoryId,
        totalQuestions: _lastTotalQuestions,
        mode: _lastMode,
      );

  void _subscribeRtdb(BattleMatch match) {
    _rtdbSub?.cancel();
    _ticker?.cancel();
    final battleRef = _rtdb.ref('battles/${match.rtdbId}');
    _rtdbSub = battleRef.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map) return;
      final data = {
        for (final entry in value.entries)
          entry.key.toString(): entry.value,
      };
      if (BattlePayload.isTerminalSnapshot(data)) {
        unawaited(_finish(data));
        return;
      }
      _mergeSnapshot(data);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// RTDB writes arrive before the REST payload sometimes (questions are set
  /// once the room fills). Merge what the server published into the match;
  /// an empty snapshot is never treated as "no questions from server".
  void _mergeSnapshot(Map<String, dynamic> data) {
    final m = state.match;
    if (m == null) return;
    final parsed = BattlePayload.parse(
      data,
      endpoint: 'battles/${m.rtdbId}',
      base: m,
      requireQuestions: false,
    );
    final unchanged = parsed.status == m.status &&
        parsed.questions.length == m.questions.length &&
        parsed.players.length == m.players.length &&
        parsed.winnerUid == m.winnerUid &&
        _sameScores(parsed.players, m.players);
    if (unchanged) return;

    state = state.copyWith(match: parsed);

    // The RTDB `players/{auth.uid}` map is the authoritative presence node.
    // Use the canonical `me.uid`, not the Firebase SDK's local uid, to decide
    // who "me" is; every other player is the opposition for progress hints.
    final meUid = parsed.meUid.isNotEmpty ? parsed.meUid : (state.myUid ?? '');
    if (meUid.isNotEmpty) {
      final mine = parsed.allPlayers.where((p) => p.uid == meUid).firstOrNull;
      final myIdx = mine?.currentIdx ?? state.currentQuestionIndex;
      final someoneAhead = parsed.allPlayers.any(
        (p) => p.uid != meUid && p.currentIdx > myIdx,
      );
      if (someoneAhead && !state.opponentAnsweredThisQ) {
        state = state.copyWith(opponentAnsweredThisQ: true);
      }
    }

    if (state.phase == BattlePhase.searching && parsed.questions.isNotEmpty) {
      state = state.copyWith(
        phase: BattlePhase.inProgress,
        currentQuestionIndex: 0,
        secondsLeftInQuestion: parsed.perQuestionSeconds,
      );
    }
  }

  bool _sameScores(List<BattlePlayer> a, List<BattlePlayer> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].score != b[i].score || a[i].currentIdx != b[i].currentIdx) {
        return false;
      }
    }
    return true;
  }

  Future<void> _finish(Map<String, dynamic> snapshot) async {
    if (state.phase == BattlePhase.finished) return;
    final m = state.match;
    if (m == null) return;
    String? normalize(Object? raw) {
      final value = BattlePayload.winnerUid(raw);
      if (value == null) return null;
      // `winner` is a uid string; `winner_id` is the numeric id. A numeric
      // winner equal to me.id maps back to the canonical me.uid.
      if (BattlePayload.intOf(raw) == m.currentUserId && m.meUid.isNotEmpty) {
        return m.meUid;
      }
      return value;
    }

    var winner = normalize(snapshot['winner'] ?? snapshot['winner_id']) ??
        m.winnerUid;
    if (winner == null) {
      // RTDB has no winner node on some servers: the REST result is the
      // authoritative fallback, never a client-side score comparison.
      try {
        final results = await ref
            .read(battleRepositoryProvider)
            .getBattleResults(m.rtdbId);
        winner = normalize(results['winner'] ?? results['winner_id']);
      } on Object catch (e, st) {
        AppLogger.w('battle result lookup failed: $e', e, st);
      }
    }
    state = state.copyWith(
      phase: BattlePhase.finished,
      winnerUid: winner,
      match: m.copyWith(status: 'finished', winnerUid: winner),
    );
    unawaited(_rtdbSub?.cancel());
    _ticker?.cancel();
    try {
      await ref.read(analyticsProvider).log(
            AnalyticsEvents.battleFinished,
            params: {'match_id': m.rtdbId},
          );
    } on Object catch (_) {}
  }

  /// One continuous clock anchored on the server's `started_at`. Re-basing on
  /// `DateTime.now()` here is what froze the question index at zero.
  void _tick() {
    final m = state.match;
    if (m == null ||
        (state.phase != BattlePhase.inProgress &&
            state.phase != BattlePhase.answered)) {
      return;
    }
    final total = m.questionCount;
    if (total <= 0) return;
    final per = m.perQuestionSeconds > 0 ? m.perQuestionSeconds : 30;
    final started = m.startedAt ?? _clockAnchor ?? DateTime.now();
    final elapsed = DateTime.now().difference(started).inSeconds;
    if (elapsed < 0) return;
    final idx = (elapsed ~/ per).clamp(0, total - 1);
    final left = per - (elapsed % per);
    if (idx != state.currentQuestionIndex) {
      // Answered is not terminal: the next question window re-arms it.
      state = state.copyWith(
        currentQuestionIndex: idx,
        secondsLeftInQuestion: left,
        selectedOptionId: null,
        opponentAnsweredThisQ: false,
        phase: BattlePhase.inProgress,
      );
    } else {
      state = state.copyWith(secondsLeftInQuestion: left);
    }
  }

  Future<void> submitAnswer(String optionId) async {
    if (state.phase != BattlePhase.inProgress) return;
    final m = state.match;
    if (m == null) return;
    final q = state.currentQuestionIndex < m.questions.length
        ? m.questions[state.currentQuestionIndex]
        : null;
    if (q == null) return;

    final option = q.options.where((o) => o.id == optionId).firstOrNull;
    final order = option?.order;
    final selected = order != null ? order + 1 : (int.tryParse(optionId) ?? 0);
    final questionId = int.tryParse(q.id) ?? q.index + 1;
    if (questionId <= 0 || selected <= 0) {
      state = state.copyWith(
        phase: BattlePhase.error,
        error: appL10n().errRequestFailed,
      );
      return;
    }

    state = state.copyWith(
      selectedOptionId: optionId,
      phase: BattlePhase.answered,
    );
    final timeTakenMs = ((m.perQuestionSeconds - state.secondsLeftInQuestion)
            .clamp(0, m.perQuestionSeconds)) *
        1000;
    try {
      final dio = ref.read(dioProvider);
      // PUT, not POST: the server registers this transition canonically as PUT
      // and keeps POST only as `answer.transition-alias` until the freeze.
      await dio.put<dynamic>(
        '/quiz/battles/${m.rtdbId}/answer',
        data: {
          'question_id': questionId,
          'question_index': state.currentQuestionIndex,
          'selected_option': selected,
          'time_taken_ms': timeTakenMs,
        },
        options: Options(
          headers: {
            'Idempotency-Key': '${m.id}:${state.currentQuestionIndex}',
          },
        ),
      );
      try {
        await ref.read(analyticsProvider).log(
              AnalyticsEvents.battleAnswerSubmit,
              params: {'match_id': m.rtdbId, 'q': state.currentQuestionIndex},
            );
      } catch (_) {}
    } on Object catch (e, st) {
      AppLogger.w('battle answer failed: $e', e, st);
      state = state.copyWith(
        phase: BattlePhase.error,
        error: battleErrorMessage(e),
      );
    }
  }

  void reset() {
    _rtdbSub?.cancel();
    _ticker?.cancel();
    _rtdbSub = null;
    _ticker = null;
    _myUid = null;
    _clockAnchor = null;
    state = const BattleState();
  }
}

final battleControllerProvider =
    NotifierProvider<BattleController, BattleState>(BattleController.new);

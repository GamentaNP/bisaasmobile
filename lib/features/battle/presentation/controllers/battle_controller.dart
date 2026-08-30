// ignore_for_file: unused_element, unnecessary_parenthesis, cast_nullable_to_non_nullable, strict_raw_type

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/battle_remote_data_source.dart';
import '../../data/repositories/battle_repository_impl.dart';
import '../../domain/entities/battle.dart';
import '../../domain/repositories/battle_repository.dart';

final battleRemoteDataSourceProvider = Provider<BattleRemoteDataSource>((ref) {
  return BattleRemoteDataSource(DioClient.instance.dio);
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return BattleRepositoryImpl(ref.watch(battleRemoteDataSourceProvider));
});

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

  BattleState copyWith({
    BattlePhase? phase,
    BattleToken? token,
    BattleMatch? match,
    int? currentQuestionIndex,
    String? selectedOptionId,
    bool? opponentAnsweredThisQ,
    int? secondsLeftInQuestion,
    String? error,
    String? winnerUid,
  }) =>
      BattleState(
        phase: phase ?? this.phase,
        token: token ?? this.token,
        match: match ?? this.match,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        selectedOptionId: selectedOptionId ?? this.selectedOptionId,
        opponentAnsweredThisQ: opponentAnsweredThisQ ?? this.opponentAnsweredThisQ,
        secondsLeftInQuestion: secondsLeftInQuestion ?? this.secondsLeftInQuestion,
        error: error,
        winnerUid: winnerUid ?? this.winnerUid,
      );
}

class BattleController extends Notifier<BattleState> {
  StreamSubscription<DatabaseEvent>? _rtdbSub;
  Timer? _ticker;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  String? _myUid;

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
      if (t.token.isEmpty) throw Exception('Empty Firebase custom token — check backend Firebase config');
      state = state.copyWith(phase: BattlePhase.idle, token: t);
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchSearch, params: {'step': 'token_fetched'}); } catch (_) {}
    } catch (e) {
      state = state.copyWith(phase: BattlePhase.error, error: e.toString());
    }
  }

  Future<void> _connectFirebase() async {
    state = state.copyWith(phase: BattlePhase.connectingFirebase, error: null);
    try {
      final cred = await _auth.signInWithCustomToken(state.token!.token);
      _myUid = cred.user?.uid;
    } catch (e) {
      // Firebase may not be initialised (no google-services.json). The arena
      // still works for rejoin via REST; the matchmaking flow needs Firebase.
      state = state.copyWith(phase: BattlePhase.error, error: 'Firebase sign-in failed: $e');
      rethrow;
    }
  }

  Future<void> findMatch({String? category}) async {
    state = state.copyWith(phase: BattlePhase.searching, error: null);
    try {
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchSearch, params: {'category': category ?? 'any'}); } catch (_) {}
      final repo = ref.read(battleRepositoryProvider);
      final m = await repo.findMatch(category: category);
      state = state.copyWith(phase: BattlePhase.inProgress, match: m, currentQuestionIndex: 0);
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchFound, params: {'match_id': m.id}); } catch (_) {}
      _subscribeRtdb(m.id);
    } catch (e) {
      state = state.copyWith(phase: BattlePhase.error, error: e.toString());
    }
  }

  void _subscribeRtdb(String matchId) {
    _rtdbSub?.cancel();
    _ticker?.cancel();
    final ref = _rtdb.ref('battles/$matchId');
    _rtdbSub = ref.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map) return;
      final data = (value).cast<Object?, Object?>().map((k, v) => MapEntry(k.toString(), v));
      final status = data['status']?.toString();
      if (status == 'finished') {
        state = state.copyWith(
          phase: BattlePhase.finished,
          winnerUid: data['winner']?.toString(),
        );
        _rtdbSub?.cancel();
        _ticker?.cancel();
        return;
      }
      // Opponent progress
      if (_myUid != null) {
        final oppKey = (data['player1'] is Map && (data['player1'] as Map)['uid']?.toString() != _myUid) ? 'player1' : 'player2';
        final opp = data[oppKey] as Map?;
        if (opp != null) {
          final oppIdx = (opp['current_idx'] as int?) ?? 0;
          final me = data[oppKey == 'player1' ? 'player2' : 'player1'] as Map?;
          final myIdx = (me?['current_idx'] as int?) ?? 0;
          if (oppIdx > myIdx) {
            state = state.copyWith(opponentAnsweredThisQ: true);
          }
        }
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final m = state.match;
      if (m == null || state.phase != BattlePhase.inProgress) return;
      final started = DateTime.fromMillisecondsSinceEpoch(m.startedAtMs ?? DateTime.now().millisecondsSinceEpoch);
      final elapsedSec = DateTime.now().difference(started).inSeconds;
      final intoQuestion = elapsedSec % m.perQuestionSeconds;
      final left = m.perQuestionSeconds - intoQuestion;
      final idx = elapsedSec ~/ m.perQuestionSeconds;
      if (idx != state.currentQuestionIndex && idx < m.questions.length) {
        state = state.copyWith(currentQuestionIndex: idx, secondsLeftInQuestion: left, selectedOptionId: null, opponentAnsweredThisQ: false);
      } else {
        state = state.copyWith(secondsLeftInQuestion: left);
      }
    });
  }

  Future<void> submitAnswer(String optionId) async {
    if (state.phase != BattlePhase.inProgress) return;
    final m = state.match;
    if (m == null) return;
    state = state.copyWith(selectedOptionId: optionId, phase: BattlePhase.answered);
    try {
      final dio = DioClient.instance.dio;
      await dio.put<dynamic>('/quiz/battles/${m.id}/answers', data: {
        'question_idx': state.currentQuestionIndex,
        'option_id': optionId,
      }, options: Options(headers: {'Idempotency-Key': '${m.id}:${state.currentQuestionIndex}'}));
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleAnswerSubmit, params: {'match_id': m.id, 'q': state.currentQuestionIndex}); } catch (_) {}
    } catch (e) {
      state = state.copyWith(phase: BattlePhase.error, error: 'Answer failed: $e');
    }
  }

  void reset() {
    _rtdbSub?.cancel();
    _ticker?.cancel();
    _rtdbSub = null;
    _ticker = null;
    state = const BattleState();
  }
}

final battleControllerProvider = NotifierProvider<BattleController, BattleState>(BattleController.new);

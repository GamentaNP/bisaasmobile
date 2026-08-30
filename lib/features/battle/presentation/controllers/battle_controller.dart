import 'dart:async';

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

enum BattlePhase { idle, fetchingToken, matchmaking, inBattle, error }

class BattleState {
  const BattleState({
    this.phase = BattlePhase.idle,
    this.token,
    this.match,
    this.error,
  });
  final BattlePhase phase;
  final BattleToken? token;
  final BattleMatch? match;
  final String? error;

  BattleState copyWith({BattlePhase? phase, BattleToken? token, BattleMatch? match, String? error}) => BattleState(
        phase: phase ?? this.phase,
        token: token ?? this.token,
        match: match ?? this.match,
        error: error,
      );
}

class BattleController extends Notifier<BattleState> {
  @override
  BattleState build() => const BattleState();

  Future<void> fetchToken() async {
    state = state.copyWith(phase: BattlePhase.fetchingToken, error: null);
    try {
      final repo = ref.read(battleRepositoryProvider);
      final t = await repo.getFirebaseToken();
      if (t.token.isEmpty) throw Exception('Empty Firebase custom token — check backend Firebase config');
      state = state.copyWith(phase: BattlePhase.idle, token: t);
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchSearch, params: {'step': 'token_fetched'}); } catch (_) {}
    } catch (e) {
      state = BattleState(phase: BattlePhase.error, error: e.toString());
    }
  }

  Future<void> findMatch() async {
    state = state.copyWith(phase: BattlePhase.matchmaking, error: null);
    try {
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchSearch); } catch (_) {}
      final repo = ref.read(battleRepositoryProvider);
      final m = await repo.findMatch();
      state = state.copyWith(phase: BattlePhase.inBattle, match: m);
      try { await ref.read(analyticsProvider)?.log(AnalyticsEvents.battleMatchFound, params: {'match_id': m.id}); } catch (_) {}
    } catch (e) {
      state = BattleState(phase: BattlePhase.error, error: e.toString());
    }
  }

  void reset() => state = const BattleState();
}

final battleControllerProvider = NotifierProvider<BattleController, BattleState>(BattleController.new);

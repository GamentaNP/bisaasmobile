import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/live_events_remote_data_source.dart';
import '../../data/repositories/live_events_repository_impl.dart';
import '../../domain/entities/live_event.dart';
import '../../domain/repositories/live_events_repository.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final liveEventsRemoteDataSourceProvider = Provider<LiveEventsRemoteDataSource>((ref) {
  return LiveEventsRemoteDataSource(DioClient.instance.dio);
});

final liveEventsRepositoryProvider = Provider<LiveEventsRepository>((ref) {
  return LiveEventsRepositoryImpl(ref.watch(liveEventsRemoteDataSourceProvider));
});

// ── List state ──────────────────────────────────────────────────────────────

class LiveEventsState {
  const LiveEventsState({this.items = const [], this.isLoading = false, this.error});

  final List<LiveEvent> items;
  final bool isLoading;
  final String? error;

  LiveEventsState copyWith({List<LiveEvent>? items, bool? isLoading, Object? error = const Object()}) => LiveEventsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error == const Object() ? this.error : error as String?,
      );
}

class LiveEventsController extends Notifier<LiveEventsState> {
  @override
  LiveEventsState build() => const LiveEventsState();

  LiveEventsRepository get _repo => ref.read(liveEventsRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchLiveEvents({int limit = 25}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getLiveEvents(limit: limit);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e, st) {
      AppLogger.w('live-events fetch failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }
}

// ── Detail state ────────────────────────────────────────────────────────────

class LiveEventDetailState {
  const LiveEventDetailState({
    this.detail,
    this.isLoading = false,
    this.error,
    this.isRegistering = false,
    this.registerError,
    this.isCheckingIn = false,
    this.checkInError,
    this.snapshot,
    this.isSnapshotLoading = false,
    this.snapshotError,
    this.isAnswering = false,
    this.answerError,
    this.lastParticipant,
  });

  final LiveEventDetail? detail;
  final bool isLoading;
  final String? error;

  final bool isRegistering;
  final String? registerError;

  final bool isCheckingIn;
  final String? checkInError;

  final LiveEventSnapshot? snapshot;
  final bool isSnapshotLoading;
  final String? snapshotError;

  final bool isAnswering;
  final String? answerError;
  final LiveEventParticipant? lastParticipant;

  LiveEventDetailState copyWith({
    Object? detail = const Object(),
    bool? isLoading,
    Object? error = const Object(),
    bool? isRegistering,
    Object? registerError = const Object(),
    bool? isCheckingIn,
    Object? checkInError = const Object(),
    Object? snapshot = const Object(),
    bool? isSnapshotLoading,
    Object? snapshotError = const Object(),
    bool? isAnswering,
    Object? answerError = const Object(),
    Object? lastParticipant = const Object(),
  }) =>
      LiveEventDetailState(
        detail: detail == const Object() ? this.detail : detail as LiveEventDetail?,
        isLoading: isLoading ?? this.isLoading,
        error: error == const Object() ? this.error : error as String?,
        isRegistering: isRegistering ?? this.isRegistering,
        registerError: registerError == const Object() ? this.registerError : registerError as String?,
        isCheckingIn: isCheckingIn ?? this.isCheckingIn,
        checkInError: checkInError == const Object() ? this.checkInError : checkInError as String?,
        snapshot: snapshot == const Object() ? this.snapshot : snapshot as LiveEventSnapshot?,
        isSnapshotLoading: isSnapshotLoading ?? this.isSnapshotLoading,
        snapshotError: snapshotError == const Object() ? this.snapshotError : snapshotError as String?,
        isAnswering: isAnswering ?? this.isAnswering,
        answerError: answerError == const Object() ? this.answerError : answerError as String?,
        lastParticipant: lastParticipant == const Object() ? this.lastParticipant : lastParticipant as LiveEventParticipant?,
      );
}

class LiveEventDetailController extends Notifier<LiveEventDetailState> {
  @override
  LiveEventDetailState build() => const LiveEventDetailState();

  LiveEventsRepository get _repo => ref.read(liveEventsRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _repo.getLiveEvent(id);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (e, st) {
      AppLogger.w('live-event $id detail failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> register(int id) async {
    state = state.copyWith(isRegistering: true, registerError: null);
    try {
      final p = await _repo.register(id);
      state = state.copyWith(isRegistering: false, lastParticipant: p);
      await fetchDetail(id);
      return true;
    } catch (e, st) {
      AppLogger.w('live-event $id register failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isRegistering: false, registerError: _msg(e));
      return false;
    }
  }

  Future<bool> unregister(int id) async {
    state = state.copyWith(isRegistering: true, registerError: null);
    try {
      await _repo.unregister(id);
      state = state.copyWith(isRegistering: false);
      await fetchDetail(id);
      return true;
    } catch (e, st) {
      AppLogger.w('live-event $id unregister failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isRegistering: false, registerError: _msg(e));
      return false;
    }
  }

  Future<bool> checkIn(int id) async {
    state = state.copyWith(isCheckingIn: true, checkInError: null);
    try {
      final p = await _repo.checkIn(id);
      state = state.copyWith(isCheckingIn: false, lastParticipant: p);
      await fetchDetail(id);
      return true;
    } catch (e, st) {
      AppLogger.w('live-event $id checkIn failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCheckingIn: false, checkInError: _msg(e));
      return false;
    }
  }

  Future<void> fetchSnapshot(int id) async {
    state = state.copyWith(isSnapshotLoading: true, snapshotError: null);
    try {
      final snap = await _repo.getSnapshot(id);
      state = state.copyWith(snapshot: snap, isSnapshotLoading: false);
    } catch (e, st) {
      AppLogger.w('live-event $id snapshot failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isSnapshotLoading: false, snapshotError: _msg(e));
    }
  }

  Future<LiveEventParticipant?> submitAnswer(int id, {required int questionIndex, required String answer}) async {
    state = state.copyWith(isAnswering: true, answerError: null);
    try {
      final p = await _repo.submitAnswer(id, questionIndex: questionIndex, answer: answer);
      state = state.copyWith(isAnswering: false, lastParticipant: p);
      // Refresh snapshot and detail after answer
      await Future.wait([fetchSnapshot(id), fetchDetail(id)]);
      return p;
    } catch (e, st) {
      AppLogger.w('live-event $id answer failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isAnswering: false, answerError: _msg(e));
      return null;
    }
  }

  void clearErrors() => state = state.copyWith(error: null, registerError: null, checkInError: null, snapshotError: null, answerError: null);
}

final liveEventsControllerProvider = NotifierProvider<LiveEventsController, LiveEventsState>(LiveEventsController.new);
final liveEventDetailControllerProvider = NotifierProvider<LiveEventDetailController, LiveEventDetailState>(LiveEventDetailController.new);

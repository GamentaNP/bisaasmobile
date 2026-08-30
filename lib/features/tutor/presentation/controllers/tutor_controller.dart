import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/tutor_remote_data_source.dart';
import '../../data/repositories/tutor_repository_impl.dart';
import '../../domain/entities/tutor.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../../../../app/providers.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final tutorRemoteDataSourceProvider = Provider<TutorRemoteDataSource>((ref) {
  return TutorRemoteDataSource(DioClient.instance.dio);
});

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  return TutorRepositoryImpl(ref.watch(tutorRemoteDataSourceProvider));
});

// Future providers for read-only surfaces
final tutorPlanProvider = FutureProvider<TutorPlan>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getPlan();
});

final tutorTodayProvider = FutureProvider<TutorToday>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getToday();
});

final tutorWeakAreasProvider = FutureProvider<List<WeakArea>>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getWeakAreas();
});

final tutorProjectedScoreProvider = FutureProvider<ProjectedScore>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getProjectedScore();
});

final tutorWeeklyReportProvider = FutureProvider<WeeklyReport>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getWeeklyReport();
});

final tutorRevisionsDueProvider = FutureProvider<List<RevisionItem>>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getRevisionsDue();
});

// ── Chat state ──────────────────────────────────────────────────────────────

class TutorChatState {
  const TutorChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.degraded = false,
    this.sentinel,
  });

  final List<TutorMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool degraded;
  final String? sentinel;

  bool get isNoData => sentinel == 'NO_DATA';
  bool get isRetrievalFailed => sentinel == 'RETRIEVAL_FAILED';
  bool get hasDegradedBanner => degraded || isNoData || isRetrievalFailed;

  TutorChatState copyWith({
    List<TutorMessage>? messages,
    bool? isLoading,
    bool? isSending,
    Object? error = const Object(),
    bool? degraded,
    Object? sentinel = const Object(),
  }) =>
      TutorChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: error == const Object() ? this.error : error as String?,
        degraded: degraded ?? this.degraded,
        sentinel: sentinel == const Object() ? this.sentinel : sentinel as String?,
      );
}

class TutorChatController extends Notifier<TutorChatState> {
  @override
  TutorChatState build() => const TutorChatState();

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  String _msg(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  Future<void> send(String prompt, {bool useLegacy = false}) async {
    if (prompt.trim().isEmpty) return;
    final user = TutorMessage(role: 'user', content: prompt.trim(), timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, user],
      isSending: true,
      error: null,
      degraded: false,
      sentinel: null,
    );
    try {
      if (useLegacy) {
        final answer = await _repo.askLegacyTutor(prompt, history: state.messages);
        final assistant = TutorMessage(
          role: 'assistant',
          content: answer.isEmpty ? 'No response (tutor offline).' : answer,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, assistant],
          isSending: false,
        );
        try {
          await ref.read(analyticsProvider)?.log('tutor_message_sent', params: {'legacy': '1'});
        } catch (_) {}
        return;
      }

      final result = await _repo.chat(prompt, history: state.messages);
      final content = result.answer.isEmpty
          ? (result.isNoData
              ? 'Not enough history yet — complete a few quizzes and try again.'
              : result.isRetrievalFailed
                  ? 'Temporarily unavailable — showing your deterministic study plan instead.'
                  : 'No response.')
          : result.answer;
      final assistant = TutorMessage(role: 'assistant', content: content, timestamp: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, assistant],
        isSending: false,
        degraded: result.degraded,
        sentinel: result.sentinel,
      );
      try {
        await ref.read(analyticsProvider)?.log('tutor_message_sent', params: {
          if (result.degraded) 'degraded': '1',
          if (result.sentinel != null) 'sentinel': result.sentinel!,
        });
      } catch (_) {}
    } catch (e, st) {
      AppLogger.w('tutor chat failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      // If primary chat fails, do not crash — surface error banner keep history
      state = state.copyWith(isSending: false, error: _msg(e));
    }
  }

  void clear() => state = const TutorChatState();
  void clearError() => state = state.copyWith(error: null);
}

// ── Plan / Today controller ─────────────────────────────────────────────────

class TutorPlanState {
  const TutorPlanState({
    this.plan,
    this.today,
    this.isPlanLoading = false,
    this.isTodayLoading = false,
    this.isCompletingDay = false,
    this.isAdjusting = false,
    this.error,
    this.planError,
    this.todayError,
  });

  final TutorPlan? plan;
  final TutorToday? today;
  final bool isPlanLoading;
  final bool isTodayLoading;
  final bool isCompletingDay;
  final bool isAdjusting;
  final String? error;
  final String? planError;
  final String? todayError;

  bool get isLoading => isPlanLoading || isTodayLoading;

  TutorPlanState copyWith({
    Object? plan = const Object(),
    Object? today = const Object(),
    bool? isPlanLoading,
    bool? isTodayLoading,
    bool? isCompletingDay,
    bool? isAdjusting,
    Object? error = const Object(),
    Object? planError = const Object(),
    Object? todayError = const Object(),
  }) =>
      TutorPlanState(
        plan: plan == const Object() ? this.plan : plan as TutorPlan?,
        today: today == const Object() ? this.today : today as TutorToday?,
        isPlanLoading: isPlanLoading ?? this.isPlanLoading,
        isTodayLoading: isTodayLoading ?? this.isTodayLoading,
        isCompletingDay: isCompletingDay ?? this.isCompletingDay,
        isAdjusting: isAdjusting ?? this.isAdjusting,
        error: error == const Object() ? this.error : error as String?,
        planError: planError == const Object() ? this.planError : planError as String?,
        todayError: todayError == const Object() ? this.todayError : todayError as String?,
      );
}

class TutorPlanController extends Notifier<TutorPlanState> {
  @override
  TutorPlanState build() => const TutorPlanState();

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchPlan() async {
    state = state.copyWith(isPlanLoading: true, planError: null);
    try {
      final plan = await _repo.getPlan();
      state = state.copyWith(plan: plan, isPlanLoading: false);
    } catch (e, st) {
      AppLogger.w('tutor fetchPlan failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isPlanLoading: false, planError: _msg(e));
    }
  }

  Future<void> fetchToday() async {
    state = state.copyWith(isTodayLoading: true, todayError: null);
    try {
      final today = await _repo.getToday();
      state = state.copyWith(today: today, isTodayLoading: false);
    } catch (e, st) {
      AppLogger.w('tutor fetchToday failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isTodayLoading: false, todayError: _msg(e));
    }
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchPlan(), fetchToday()]);
  }

  Future<bool> completeDay({String? dayId, int? dayIndex}) async {
    state = state.copyWith(isCompletingDay: true, error: null);
    try {
      await _repo.completeDay(dayId: dayId, dayIndex: dayIndex);
      state = state.copyWith(isCompletingDay: false);
      // Refresh today + plan
      await fetchAll();
      try {
        await ref.read(analyticsProvider)?.log('tutor_complete_day');
      } catch (_) {}
      return true;
    } catch (e, st) {
      AppLogger.w('tutor completeDay failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCompletingDay: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> adjustPlan(Map<String, dynamic> adjustments) async {
    state = state.copyWith(isAdjusting: true, error: null);
    try {
      await _repo.adjustPlan(adjustments);
      state = state.copyWith(isAdjusting: false);
      await fetchPlan();
      return true;
    } catch (e, st) {
      AppLogger.w('tutor adjustPlan failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isAdjusting: false, error: _msg(e));
      return false;
    }
  }

  void clearErrors() => state = state.copyWith(error: null, planError: null, todayError: null);
}

// ── Onboarding controller ───────────────────────────────────────────────────

class TutorOnboardingState {
  const TutorOnboardingState({
    this.session,
    this.isStarting = false,
    this.isCompleting = false,
    this.error,
    this.startError,
    this.completeError,
    this.isCompleted = false,
  });

  final TutorOnboardingSession? session;
  final bool isStarting;
  final bool isCompleting;
  final String? error;
  final String? startError;
  final String? completeError;
  final bool isCompleted;

  TutorOnboardingState copyWith({
    Object? session = const Object(),
    bool? isStarting,
    bool? isCompleting,
    Object? error = const Object(),
    Object? startError = const Object(),
    Object? completeError = const Object(),
    bool? isCompleted,
  }) =>
      TutorOnboardingState(
        session: session == const Object() ? this.session : session as TutorOnboardingSession?,
        isStarting: isStarting ?? this.isStarting,
        isCompleting: isCompleting ?? this.isCompleting,
        error: error == const Object() ? this.error : error as String?,
        startError: startError == const Object() ? this.startError : startError as String?,
        completeError: completeError == const Object() ? this.completeError : completeError as String?,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class TutorOnboardingController extends Notifier<TutorOnboardingState> {
  @override
  TutorOnboardingState build() => const TutorOnboardingState();

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> start({Map<String, dynamic>? payload}) async {
    state = state.copyWith(isStarting: true, startError: null);
    try {
      final session = await _repo.startOnboarding(payload: payload);
      state = state.copyWith(session: session, isStarting: false);
      try {
        await ref.read(analyticsProvider)?.log('tutor_onboarding_start');
      } catch (_) {}
    } catch (e, st) {
      AppLogger.w('tutor onboarding start failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isStarting: false, startError: _msg(e));
    }
  }

  Future<bool> complete({Map<String, dynamic>? payload}) async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      state = state.copyWith(completeError: 'No onboarding session — start first.');
      return false;
    }
    state = state.copyWith(isCompleting: true, completeError: null);
    try {
      await _repo.completeOnboarding(sessionId, payload: payload);
      state = state.copyWith(isCompleting: false, isCompleted: true);
      try {
        await ref.read(analyticsProvider)?.log('tutor_onboarding_complete');
      } catch (_) {}
      return true;
    } catch (e, st) {
      AppLogger.w('tutor onboarding complete failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCompleting: false, completeError: _msg(e));
      return false;
    }
  }

  void reset() => state = const TutorOnboardingState();
}

final tutorChatControllerProvider =
    NotifierProvider<TutorChatController, TutorChatState>(TutorChatController.new);

final tutorPlanControllerProvider =
    NotifierProvider<TutorPlanController, TutorPlanState>(TutorPlanController.new);

final tutorOnboardingControllerProvider =
    NotifierProvider<TutorOnboardingController, TutorOnboardingState>(TutorOnboardingController.new);

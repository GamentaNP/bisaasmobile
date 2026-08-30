import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../tutor/presentation/controllers/tutor_controller.dart';
import '../../data/datasources/coaching_remote_data_source.dart';
import '../../data/repositories/coaching_repository_impl.dart';
import '../../domain/entities/coaching.dart';
import '../../domain/repositories/coaching_repository.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final coachingRemoteDataSourceProvider = Provider<CoachingRemoteDataSource>((ref) {
  return CoachingRemoteDataSource(DioClient.instance.dio);
});

final coachingRepositoryProvider = Provider<CoachingRepository>((ref) {
  return CoachingRepositoryImpl(
    ref.watch(coachingRemoteDataSourceProvider),
    ref.watch(tutorRepositoryProvider),
  );
});

final coachingDashboardProvider =
    FutureProvider.family<CoachingDashboardData, String?>((ref, goalId) async {
  final repo = ref.watch(coachingRepositoryProvider);
  return repo.getDashboard(goalId: goalId);
});

// ── Controller for explicit refresh / readiness ─────────────────────────────

class CoachingState {
  const CoachingState({
    this.dashboard,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedGoalId,
  });

  final CoachingDashboardData? dashboard;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? selectedGoalId;

  CoachingState copyWith({
    Object? dashboard = const Object(),
    bool? isLoading,
    bool? isRefreshing,
    Object? error = const Object(),
    Object? selectedGoalId = const Object(),
  }) =>
      CoachingState(
        dashboard: dashboard == const Object() ? this.dashboard : dashboard as CoachingDashboardData?,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        error: error == const Object() ? this.error : error as String?,
        selectedGoalId: selectedGoalId == const Object() ? this.selectedGoalId : selectedGoalId as String?,
      );
}

class CoachingController extends Notifier<CoachingState> {
  @override
  CoachingState build() => const CoachingState();

  CoachingRepository get _repo => ref.read(coachingRepositoryProvider);

  Future<void> load({String? goalId}) async {
    state = state.copyWith(isLoading: true, error: null, selectedGoalId: goalId ?? state.selectedGoalId);
    try {
      final data = await _repo.getDashboard(goalId: goalId ?? state.selectedGoalId);
      state = state.copyWith(dashboard: data, isLoading: false);
    } catch (e, st) {
      AppLogger.w('coaching load failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final data = await _repo.getDashboard(goalId: state.selectedGoalId);
      state = state.copyWith(dashboard: data, isRefreshing: false);
    } catch (e, st) {
      AppLogger.w('coaching refresh failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isRefreshing: false, error: e.toString());
    }
  }

  void setGoal(String? goalId) {
    state = state.copyWith(selectedGoalId: goalId);
  }

  void clearError() => state = state.copyWith(error: null);
}

final coachingControllerProvider =
    NotifierProvider<CoachingController, CoachingState>(CoachingController.new);

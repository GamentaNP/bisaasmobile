import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/learning_remote_data_source.dart';
import '../../data/repositories/learning_repository_impl.dart';
import '../../domain/entities/learning.dart';
import '../../domain/repositories/learning_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final learningRemoteDataSourceProvider = Provider<LearningRemoteDataSource>((ref) {
  return LearningRemoteDataSource(DioClient.instance.dio);
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepositoryImpl(ref.watch(learningRemoteDataSourceProvider));
});

final learningTracksProvider = FutureProvider<List<LearningTrack>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getTracks();
});

final learningGoalsProvider = FutureProvider<List<LearningGoal>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getGoals();
});

final todayPlanProvider = FutureProvider<DailyPlan?>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getToday();
});

final reviewsDueProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getReviewsDue();
});

// ── State for mutable controllers ────────────────────────────────────────────

class LearningState {
  const LearningState({
    this.isLoading = false,
    this.error,
    this.isCreatingGoal = false,
    this.createGoalError,
    this.isDeletingGoal = false,
    this.deleteGoalError,
    this.isCompletingItem = false,
    this.completeItemError,
    this.isGrading = false,
    this.gradeError,
    this.isAskingTutor = false,
    this.tutorError,
    this.lastTutorReply,
  });

  final bool isLoading;
  final String? error;
  final bool isCreatingGoal;
  final String? createGoalError;
  final bool isDeletingGoal;
  final String? deleteGoalError;
  final bool isCompletingItem;
  final String? completeItemError;
  final bool isGrading;
  final String? gradeError;
  final bool isAskingTutor;
  final String? tutorError;
  final TutorReply? lastTutorReply;

  static const _sentinel = Object();

  LearningState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    bool? isCreatingGoal,
    Object? createGoalError = _sentinel,
    bool? isDeletingGoal,
    Object? deleteGoalError = _sentinel,
    bool? isCompletingItem,
    Object? completeItemError = _sentinel,
    bool? isGrading,
    Object? gradeError = _sentinel,
    bool? isAskingTutor,
    Object? tutorError = _sentinel,
    Object? lastTutorReply = _sentinel,
  }) {
    return LearningState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      isCreatingGoal: isCreatingGoal ?? this.isCreatingGoal,
      createGoalError: createGoalError == _sentinel ? this.createGoalError : createGoalError as String?,
      isDeletingGoal: isDeletingGoal ?? this.isDeletingGoal,
      deleteGoalError: deleteGoalError == _sentinel ? this.deleteGoalError : deleteGoalError as String?,
      isCompletingItem: isCompletingItem ?? this.isCompletingItem,
      completeItemError: completeItemError == _sentinel ? this.completeItemError : completeItemError as String?,
      isGrading: isGrading ?? this.isGrading,
      gradeError: gradeError == _sentinel ? this.gradeError : gradeError as String?,
      isAskingTutor: isAskingTutor ?? this.isAskingTutor,
      tutorError: tutorError == _sentinel ? this.tutorError : tutorError as String?,
      lastTutorReply: lastTutorReply == _sentinel ? this.lastTutorReply : lastTutorReply as TutorReply?,
    );
  }
}

class LearningController extends Notifier<LearningState> {
  @override
  LearningState build() => const LearningState();

  LearningRepository get _repo => ref.read(learningRepositoryProvider);
  static const _uuid = Uuid();

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<LearningGoal?> createGoal({
    required int trackId,
    String? targetDate,
    int? dailyMinutes,
    String? intensity,
    Map<String, dynamic>? placementMeta,
  }) async {
    state = state.copyWith(isCreatingGoal: true, createGoalError: null);
    try {
      final goal = await _repo.createGoal(
        trackId: trackId,
        targetDate: targetDate,
        dailyMinutes: dailyMinutes,
        intensity: intensity,
        placementMeta: placementMeta,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isCreatingGoal: false);
      ref.invalidate(learningGoalsProvider);
      ref.invalidate(todayPlanProvider);
      return goal;
    } catch (e, st) {
      AppLogger.w('learning createGoal failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCreatingGoal: false, createGoalError: _msg(e));
      return null;
    }
  }

  Future<bool> deleteGoal(int goalId) async {
    state = state.copyWith(isDeletingGoal: true, deleteGoalError: null);
    try {
      await _repo.deleteGoal(goalId);
      state = state.copyWith(isDeletingGoal: false);
      ref.invalidate(learningGoalsProvider);
      ref.invalidate(todayPlanProvider);
      return true;
    } catch (e, st) {
      AppLogger.w('learning deleteGoal $goalId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isDeletingGoal: false, deleteGoalError: _msg(e));
      return false;
    }
  }

  // ── Today ───────────────────────────────────────────────────────────────────

  Future<DailyPlan?> completeItem(int planId, int itemIndex) async {
    state = state.copyWith(isCompletingItem: true, completeItemError: null);
    try {
      final updated = await _repo.completeTodayItem(planId, itemIndex, idempotencyKey: _uuid.v4());
      state = state.copyWith(isCompletingItem: false);
      ref.invalidate(todayPlanProvider);
      ref.invalidate(reviewsDueProvider);
      return updated;
    } catch (e, st) {
      AppLogger.w('learning completeItem $planId/$itemIndex failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCompletingItem: false, completeItemError: _msg(e));
      return null;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<ReviewItem?> gradeReview(int reviewId, String outcome) async {
    state = state.copyWith(isGrading: true, gradeError: null);
    try {
      final res = await _repo.gradeReview(reviewId, outcome, idempotencyKey: _uuid.v4());
      state = state.copyWith(isGrading: false);
      ref.invalidate(reviewsDueProvider);
      ref.invalidate(todayPlanProvider);
      return res;
    } catch (e, st) {
      AppLogger.w('learning gradeReview $reviewId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isGrading: false, gradeError: _msg(e));
      return null;
    }
  }

  // ── Tutor ───────────────────────────────────────────────────────────────────

  Future<TutorReply?> askTutor({
    required String topic,
    required String question,
    String? learnerAnswer,
    String? misconception,
  }) async {
    state = state.copyWith(isAskingTutor: true, tutorError: null, lastTutorReply: null);
    try {
      final reply = await _repo.askTutor(
        topic: topic,
        question: question,
        learnerAnswer: learnerAnswer,
        misconception: misconception,
        idempotencyKey: _uuid.v4(),
      );
      state = state.copyWith(isAskingTutor: false, lastTutorReply: reply);
      return reply;
    } catch (e, st) {
      AppLogger.w('learning askTutor failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isAskingTutor: false, tutorError: _msg(e));
      return null;
    }
  }

  void clearErrors() {
    state = state.copyWith(error: null, createGoalError: null, deleteGoalError: null, completeItemError: null, gradeError: null, tutorError: null);
  }
}

final learningControllerProvider = NotifierProvider<LearningController, LearningState>(LearningController.new);

// ── Goal detail providers ─────────────────────────────────────────────────────

final learningGoalDetailProvider = FutureProvider.family<LearningGoal, int>((ref, goalId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getGoal(goalId);
});

final learningGoalReadinessProvider = FutureProvider.family<LearningGoalReadiness, int>((ref, goalId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getGoalReadiness(goalId);
});

// ── Tutor chat state (legacy compatibility with learning_home_screen) ─────────

class TutorState {
  const TutorState({this.messages = const [], this.loading = false, this.error});
  final List<TutorMessage> messages;
  final bool loading;
  final String? error;
}

class TutorController extends Notifier<TutorState> {
  @override
  TutorState build() => const TutorState();

  Future<void> send(String prompt) async {
    if (prompt.trim().isEmpty) return;
    final user = TutorMessage(role: 'user', content: prompt.trim());
    state = TutorState(messages: [...state.messages, user], loading: true);
    try {
      final repo = ref.read(learningRepositoryProvider);
      final answer = await repo.askTutorLegacy(prompt, history: state.messages);
      final assistant = TutorMessage(role: 'assistant', content: answer.isEmpty ? 'No response (tutor offline).' : answer);
      state = TutorState(messages: [...state.messages, assistant]);
    } catch (e) {
      state = TutorState(messages: state.messages, error: e.toString());
      state = TutorState(messages: state.messages, error: e.toString());
    }
  }

  void clear() => state = const TutorState();
}

final tutorControllerProvider = NotifierProvider<TutorController, TutorState>(TutorController.new);

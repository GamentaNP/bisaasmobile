import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/learning_remote_data_source.dart';
import '../../data/repositories/learning_repository_impl.dart';
import '../../domain/entities/learning.dart';
import '../../domain/repositories/learning_repository.dart';

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

final todayPlanProvider = FutureProvider<TodayPlan>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getToday();
});

final reviewsDueProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getReviewsDue();
});

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
      final answer = await repo.askTutor(prompt, history: state.messages);
      final assistant = TutorMessage(role: 'assistant', content: answer.isEmpty ? 'No response (tutor offline).' : answer);
      state = TutorState(messages: [...state.messages, assistant]);
    } catch (e) {
      state = TutorState(messages: state.messages, error: e.toString());
      // keep history + show error banner
      state = TutorState(messages: state.messages, error: e.toString());
    }
  }

  void clear() => state = const TutorState();
}

final tutorControllerProvider = NotifierProvider<TutorController, TutorState>(TutorController.new);

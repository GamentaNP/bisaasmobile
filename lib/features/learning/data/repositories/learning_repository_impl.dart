import '../../domain/entities/learning.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_remote_data_source.dart';

class LearningRepositoryImpl implements LearningRepository {
  const LearningRepositoryImpl(this._remote);
  final LearningRemoteDataSource _remote;

  @override
  Future<List<LearningTrack>> getTracks() async {
    final dtos = await _remote.getTracks();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<TodayPlan> getToday() async {
    final dto = await _remote.getToday();
    return dto.toDomain();
  }

  @override
  Future<List<ReviewItem>> getReviewsDue() async {
    final dtos = await _remote.getReviewsDue();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<String> askTutor(String prompt, {List<TutorMessage>? history}) async {
    final hist = history?.map((m) => {'role': m.role, 'content': m.content}).toList();
    return _remote.askTutor(prompt, history: hist);
  }
}

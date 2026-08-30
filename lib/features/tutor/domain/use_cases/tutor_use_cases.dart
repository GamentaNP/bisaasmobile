import '../entities/tutor.dart';
import '../repositories/tutor_repository.dart';

class StartTutorOnboarding {
  const StartTutorOnboarding(this._repo);
  final TutorRepository _repo;
  Future<TutorOnboardingSession> call({Map<String, dynamic>? payload}) =>
      _repo.startOnboarding(payload: payload);
}

class CompleteTutorOnboarding {
  const CompleteTutorOnboarding(this._repo);
  final TutorRepository _repo;
  Future<void> call(String sessionId, {Map<String, dynamic>? payload}) =>
      _repo.completeOnboarding(sessionId, payload: payload);
}

class SendTutorMessage {
  const SendTutorMessage(this._repo);
  final TutorRepository _repo;
  Future<TutorChatResult> call(String message, {List<TutorMessage>? history}) =>
      _repo.chat(message, history: history);
}

class GetTutorPlan {
  const GetTutorPlan(this._repo);
  final TutorRepository _repo;
  Future<TutorPlan> call() => _repo.getPlan();
}

class GetTutorToday {
  const GetTutorToday(this._repo);
  final TutorRepository _repo;
  Future<TutorToday> call() => _repo.getToday();
}

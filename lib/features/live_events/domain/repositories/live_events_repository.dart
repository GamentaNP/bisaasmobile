import '../entities/live_event.dart';

abstract class LiveEventsRepository {
  Future<List<LiveEvent>> getLiveEvents({int limit = 25});
  Future<LiveEventDetail> getLiveEvent(int id);
  Future<LiveEventParticipant> register(int eventId, {String? idempotencyKey});
  Future<void> unregister(int eventId);
  Future<LiveEventParticipant> checkIn(int eventId, {String? idempotencyKey});
  Future<LiveEventSnapshot> getSnapshot(int eventId);
  Future<LiveEventParticipant> submitAnswer(int eventId, {required int questionIndex, required String answer, String? idempotencyKey});
}

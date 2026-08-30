import '../../domain/entities/live_event.dart';
import '../../domain/repositories/live_events_repository.dart';
import '../datasources/live_events_remote_data_source.dart';

class LiveEventsRepositoryImpl implements LiveEventsRepository {
  const LiveEventsRepositoryImpl(this._remote);
  final LiveEventsRemoteDataSource _remote;

  @override
  Future<List<LiveEvent>> getLiveEvents({int limit = 25}) async {
    final dtos = await _remote.getLiveEvents(limit: limit);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<LiveEventDetail> getLiveEvent(int id) async {
    final dto = await _remote.getLiveEvent(id);
    return dto.toDomain();
  }

  @override
  Future<LiveEventParticipant> register(int eventId, {String? idempotencyKey}) async {
    final dto = await _remote.register(eventId, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<void> unregister(int eventId) => _remote.unregister(eventId);

  @override
  Future<LiveEventParticipant> checkIn(int eventId, {String? idempotencyKey}) async {
    final dto = await _remote.checkIn(eventId, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<LiveEventSnapshot> getSnapshot(int eventId) async {
    final dto = await _remote.getSnapshot(eventId);
    return dto.toDomain();
  }

  @override
  Future<LiveEventParticipant> submitAnswer(int eventId, {required int questionIndex, required String answer, String? idempotencyKey}) async {
    final dto = await _remote.submitAnswer(eventId, questionIndex: questionIndex, answer: answer, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }
}

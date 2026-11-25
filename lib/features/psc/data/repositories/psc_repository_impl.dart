import '../../domain/entities/psc.dart';
import '../../domain/repositories/psc_repository.dart';
import '../psc_remote_data_source.dart';

/// Thin repository over the existing PSC data source.
///
/// The data source keeps ownership of the envelope checks and of throwing on
/// an unreadable 2xx body; mapping a map to an entity here does not turn a
/// contract drift into an empty catalogue.
class PscRepositoryImpl implements PscRepository {
  const PscRepositoryImpl(this._remote);

  final PscRemoteDataSource _remote;

  @override
  Future<List<PscBlueprint>> getBlueprints() async {
    final rows = await _remote.getBlueprints();
    return rows.map(PscBlueprint.new).toList(growable: false);
  }

  @override
  Future<PscExam?> startExam(String id) async {
    final raw = await _remote.startExam(id);
    return raw == null ? null : PscExam(raw);
  }

  @override
  Future<PscSubmission?> submit(String id, Map<String, dynamic> payload) async {
    final raw = await _remote.submit(id, payload);
    return raw == null ? null : PscSubmission(raw);
  }
}

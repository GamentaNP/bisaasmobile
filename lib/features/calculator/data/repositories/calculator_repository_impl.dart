import '../../../../core/logging/app_logger.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../domain/entities/calculator.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../datasources/calculator_remote_data_source.dart';
import '../models/calculator_dto.dart';

class CalculatorRepositoryImpl implements CalculatorRepository {
  const CalculatorRepositoryImpl(this._remote, [this._queue]);

  final CalculatorRemoteDataSource _remote;

  /// Optional so tests and the calculator-only paths can construct this without a
  /// database. When absent, a calculation simply is not snapshotted — the
  /// result still computes, which is the part the user is waiting on.
  final SyncQueueService? _queue;

  @override
  Future<CalculatorCatalogDto> getCatalog() => _remote.getCatalog();

  @override
  Future<CalculatorConfig> getConfig(String domain, String slug) => _remote.getConfig(domain, slug);

  /// Calculates, then records the result to `PUT /api/v1/calculation-snapshots`.
  ///
  /// The controller's comment used to claim this persistence was "handled in
  /// repo". It was not: nothing was ever written, so a user's calculation
  /// history was in-memory only and vanished on every cold start, and the
  /// server's snapshot collection stayed empty.
  ///
  /// Recorded **after** the result is in hand and never allowed to delay it.
  /// A snapshot that fails to record costs history, not correctness, so the
  /// error is swallowed deliberately - but it is logged, because a silent
  /// failure here looks exactly like "the feature was never implemented".
  @override
  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
  }) async {
    final result = await _remote.calculate(
      domain: domain,
      slug: slug,
      inputs: inputs,
    );
    await _recordSnapshot(domain: domain, slug: slug, inputs: inputs, result: result);
    return result;
  }

  Future<void> _recordSnapshot({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
    required CalculationResult result,
  }) async {
    final queue = _queue;
    if (queue == null) return;
    try {
      await queue.enqueueSnapshot(
        domain: domain,
        calculatorSlug: slug,
        inputs: inputs,
        // `CalculationResult.data` is already a Map<String, dynamic>, which is
        // exactly what the server requires of result_payload.
        result: result.data,
      );
    } on Object catch (error) {
      AppLogger.w('calculation snapshot not queued', error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug) => _remote.getHistory(domain, slug);
}

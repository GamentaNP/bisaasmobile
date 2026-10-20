import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/consent/consent_gate.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/calculator_remote_data_source.dart';
import '../../data/repositories/calculator_repository_impl.dart';
import '../../domain/entities/calculator.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../../data/models/calculator_dto.dart';
import 'calculator_request_idempotency.dart';

// ──Providers──────────────────────────────────────────────────────────────
final calculatorRemoteDataSourceProvider = Provider<CalculatorRemoteDataSource>(
  (ref) {
    return CalculatorRemoteDataSource(DioClient.instance.dio);
  },
);

final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  // The queue is what makes a calculation outlive the session: the repository
  // records every result to the sync queue and `SyncManager` replays it to
  // PUT /api/v1/calculation-snapshots. A controller comment used to claim this
  // happened "in repo" while the repository did neither.
  return CalculatorRepositoryImpl(
    ref.watch(calculatorRemoteDataSourceProvider),
    ref.watch(syncQueueServiceProvider),
  );
});

final calculatorCatalogProvider = FutureProvider<CalculatorCatalogDto>((
  ref,
) async {
  final repo = ref.watch(calculatorRepositoryProvider);
  return repo.getCatalog();
});

final calculatorConfigProvider =
    FutureProvider.family<CalculatorConfig, ({String domain, String slug})>((
      ref,
      key,
    ) async {
      final repo = ref.watch(calculatorRepositoryProvider);
      return repo.getConfig(key.domain, key.slug);
    });

// ── Calculate state ─────────────────────────────────────────────────────
@immutable
class CalcHistoryEntry {
  const CalcHistoryEntry({
    required this.label,
    required this.data,
    required this.createdAt,
  });
  final String label;
  final Map<String, dynamic> data;
  final DateTime createdAt;
}

class CalcState {
  const CalcState({
    this.loading = false,
    this.result,
    this.error,
    this.fieldErrors,
    this.history = const [],
    this.historyLoading = false,
  });

  final bool loading;
  final CalculationResult? result;
  final String? error;
  final Map<String, dynamic>? fieldErrors;
  final List<CalcHistoryEntry> history;
  final bool historyLoading;

  CalcState copyWith({
    bool? loading,
    CalculationResult? result,
    Object? error = const Object(),
    Map<String, dynamic>? fieldErrors,
    List<CalcHistoryEntry>? history,
    bool? historyLoading,
  }) => CalcState(
    loading: loading ?? this.loading,
    result: result ?? this.result,
    error: error == const Object() ? this.error : error as String?,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    history: history ?? this.history,
    historyLoading: historyLoading ?? this.historyLoading,
  );
}

class CalculatorController extends Notifier<CalcState> {
  final CalculatorRequestIdempotency _requestIdempotency =
      CalculatorRequestIdempotency();

  @override
  CalcState build() => const CalcState();

  Future<void> calculate(
    String domain,
    String slug,
    Map<String, dynamic> inputs,
  ) async {
    state = state.copyWith(loading: true, error: null, fieldErrors: null);
    try {
      final repo = ref.read(calculatorRepositoryProvider);
      final idempotencyKey = _requestIdempotency.keyFor(
        domain: domain,
        slug: slug,
        inputs: inputs,
      );
      final r = await repo.calculate(
        domain: domain,
        slug: slug,
        inputs: inputs,
        idempotencyKey: idempotencyKey,
      );
      _requestIdempotency.complete();
      // Push to the in-memory history the History sheet reads. Durability is the
      // repository's job: it queues every result to the sync queue, which
      // SyncManager replays to PUT /api/v1/calculation-snapshots.
      final newEntry = CalcHistoryEntry(
        label: '$slug · ${DateTime.now().toIso8601String().substring(0, 16)}',
        data: {...inputs, 'result': r.data},
        createdAt: DateTime.now(),
      );
      state = CalcState(
        loading: false,
        result: r,
        history: [newEntry, ...state.history],
      );
      try {
        await ref
            .read(analyticsProvider)
            .log(
              AnalyticsEvents.calculatorCalculate,
              params: {'domain': domain, 'slug': slug},
            );
      } catch (_) {}
    } on DioException catch (e) {
      final apiErr = e.error;
      if (apiErr is ApiException && apiErr.errors != null) {
        state = state.copyWith(
          loading: false,
          error: apiErr.message,
          fieldErrors: apiErr.errors,
        );
      } else if (apiErr is ApiException) {
        state = state.copyWith(loading: false, error: apiErr.message);
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['errors'] is Map) {
          state = state.copyWith(
            loading: false,
            error: (data['message'] as String?) ?? 'Validation failed',
            fieldErrors: (data['errors'] as Map).cast<String, dynamic>(),
          );
        } else {
          state = state.copyWith(
            loading: false,
            error: e.message ?? 'Calculation failed',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadHistory(String domain, String slug) async {
    state = state.copyWith(historyLoading: true);
    try {
      final rows = await ref
          .read(calculatorRepositoryProvider)
          .getHistory(domain, slug);
      final entries = rows.map((row) {
        final createdAt =
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now();
        return CalcHistoryEntry(
          label: '$slug · ${createdAt.toIso8601String().substring(0, 16)}',
          data: row,
          createdAt: createdAt,
        );
      }).toList();
      state = state.copyWith(historyLoading: false, history: entries);
    } catch (e) {
      // Keep useful session results visible while making the server failure
      // explicit instead of pretending history loaded successfully.
      final local = state.history
          .where((e) => e.label.startsWith('$slug · '))
          .toList();
      state = state.copyWith(
        historyLoading: false,
        history: local,
        error: e.toString(),
      );
    }
  }

  void clear() {
    _requestIdempotency.complete();
    state = CalcState(history: state.history);
  }
}

final calculatorControllerProvider =
    NotifierProvider<CalculatorController, CalcState>(CalculatorController.new);

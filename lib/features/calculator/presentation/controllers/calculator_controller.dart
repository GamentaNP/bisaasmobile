import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../app/providers.dart';
import '../../data/datasources/calculator_remote_data_source.dart';
import '../../data/repositories/calculator_repository_impl.dart';
import '../../domain/entities/calculator.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../../data/models/calculator_dto.dart';

// ──Providers──────────────────────────────────────────────────────────────
final calculatorRemoteDataSourceProvider = Provider<CalculatorRemoteDataSource>((ref) {
  return CalculatorRemoteDataSource(DioClient.instance.dio);
});

final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  return CalculatorRepositoryImpl(ref.watch(calculatorRemoteDataSourceProvider));
});

final calculatorCatalogProvider = FutureProvider<CalculatorCatalogDto>((ref) async {
  final repo = ref.watch(calculatorRepositoryProvider);
  return repo.getCatalog();
});

final calculatorConfigProvider = FutureProvider.family<CalculatorConfig, ({String domain, String slug})>((ref, key) async {
  final repo = ref.watch(calculatorRepositoryProvider);
  return repo.getConfig(key.domain, key.slug);
});

// ── Calculate state ─────────────────────────────────────────────────────
@immutable
class CalcHistoryEntry {
  const CalcHistoryEntry({required this.label, required this.data, required this.createdAt});
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
  }) =>
      CalcState(
        loading: loading ?? this.loading,
        result: result ?? this.result,
        error: error == const Object() ? this.error : error as String?,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        history: history ?? this.history,
        historyLoading: historyLoading ?? this.historyLoading,
      );
}

class CalculatorController extends Notifier<CalcState> {
  @override
  CalcState build() => const CalcState();

  Future<void> calculate(String domain, String slug, Map<String, dynamic> inputs) async {
    state = state.copyWith(loading: true, error: null, fieldErrors: null);
    try {
      final repo = ref.read(calculatorRepositoryProvider);
      final r = await repo.calculate(domain: domain, slug: slug, inputs: inputs);
      // Push to local history (drift persistence + server sync handled in repo).
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
        await ref.read(analyticsProvider)?.log(AnalyticsEvents.calculatorCalculate, params: {'domain': domain, 'slug': slug});
      } catch (_) {}
    } on DioException catch (e) {
      final apiErr = e.error;
      if (apiErr is ApiException && apiErr.errors != null) {
        state = state.copyWith(loading: false, error: apiErr.message, fieldErrors: apiErr.errors);
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
          state = state.copyWith(loading: false, error: e.message ?? 'Calculation failed');
        }
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadHistory(String domain, String slug) async {
    state = state.copyWith(historyLoading: true);
    // TODO(agent-b): replace with `GET /calculators/{domain}/{slug}/history`
    // when the endpoint ships. For now we filter the in-memory history by slug.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final filtered = state.history.where((e) => e.label.startsWith('$slug · ')).toList();
    state = state.copyWith(historyLoading: false, history: filtered);
  }

  void clear() => state = CalcState(history: state.history);
}

final calculatorControllerProvider =
    NotifierProvider<CalculatorController, CalcState>(CalculatorController.new);

import 'dart:async';

import 'package:dio/dio.dart';
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
class CalcState {
  const CalcState({
    this.loading = false,
    this.result,
    this.error,
    this.fieldErrors,
  });

  final bool loading;
  final CalculationResult? result;
  final String? error;
  final Map<String, dynamic>? fieldErrors;

  CalcState copyWith({
    bool? loading,
    CalculationResult? result,
    Object? error = const Object(),
    Map<String, dynamic>? fieldErrors,
  }) =>
      CalcState(
        loading: loading ?? this.loading,
        result: result ?? this.result,
        error: error == const Object() ? this.error : error as String?,
        fieldErrors: fieldErrors ?? this.fieldErrors,
      );
}

class CalculatorController extends Notifier<CalcState> {
  @override
  CalcState build() => const CalcState();

  Future<void> calculate(String domain, String slug, Map<String, dynamic> inputs) async {
    state = const CalcState(loading: true);
    try {
      final repo = ref.read(calculatorRepositoryProvider);
      final r = await repo.calculate(domain: domain, slug: slug, inputs: inputs);
      state = CalcState(result: r);
      try {
        await ref.read(analyticsProvider)?.log(AnalyticsEvents.calculatorCalculate, params: {'domain': domain, 'slug': slug});
      } catch (_) {}
    } on DioException catch (e) {
      final apiErr = e.error;
      if (apiErr is ApiException && apiErr.errors != null) {
        state = CalcState(error: apiErr.message, fieldErrors: apiErr.errors);
      } else if (apiErr is ApiException) {
        state = CalcState(error: apiErr.message);
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['errors'] is Map) {
          state = CalcState(
            error: (data['message'] as String?) ?? 'Validation failed',
            fieldErrors: (data['errors'] as Map).cast<String, dynamic>(),
          );
        } else {
          state = CalcState(error: e.message ?? 'Calculation failed');
        }
      }
    } catch (e) {
      state = CalcState(error: e.toString());
    }
  }

  void clear() => state = const CalcState();
}

final calculatorControllerProvider =
    NotifierProvider<CalculatorController, CalcState>(CalculatorController.new);

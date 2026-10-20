import 'dart:typed_data';

import 'package:bisaasmobile/features/calculator/data/datasources/calculator_remote_data_source.dart';
import 'package:bisaasmobile/features/calculator/data/models/calculator_dto.dart';
import 'package:bisaasmobile/features/calculator/domain/entities/calculator.dart';
import 'package:bisaasmobile/features/calculator/domain/entities/calculator_assistant.dart';
import 'package:bisaasmobile/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:bisaasmobile/features/calculator/presentation/controllers/calculator_controller.dart';
import 'package:bisaasmobile/features/calculator/presentation/controllers/calculator_request_idempotency.dart';
import 'package:bisaasmobile/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingCalculatorRepository implements CalculatorRepository {
  final List<String> idempotencyKeys = [];

  @override
  Future<CalculatorCatalogDto> getCatalog() => throw UnimplementedError();

  @override
  Future<CalculatorConfig> getConfig(String domain, String slug) =>
      throw UnimplementedError();

  @override
  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
    required String idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
    throw DioException(
      requestOptions: RequestOptions(path: '/$domain/$slug/calculate'),
      type: DioExceptionType.connectionError,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug) =>
      throw UnimplementedError();

  @override
  Future<CalculatorAssistant> assist({
    required String message,
    String? domain,
    String? slug,
    String? name,
    List<Map<String, dynamic>>? fields,
    Map<String, dynamic>? currentInputs,
  }) =>
      throw UnimplementedError();
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  final List<ResponseBody> responses;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responses.removeAt(0);
  }
}

ResponseBody _response(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  group('CalculatorRequestIdempotency', () {
    test('reuses a key for the same payload despite map key order', () {
      final operation = CalculatorRequestIdempotency();

      final first = operation.keyFor(
        domain: 'civil',
        slug: 'beam-deflection',
        inputs: {
          'length': 5,
          'loads': {'dead': 10, 'live': 20},
        },
      );
      final retry = operation.keyFor(
        domain: 'civil',
        slug: 'beam-deflection',
        inputs: {
          'loads': {'live': 20, 'dead': 10},
          'length': 5,
        },
      );

      expect(retry, first);
      expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
    });

    test('changed calculator or payload starts a new operation', () {
      final operation = CalculatorRequestIdempotency();
      final inputs = {'length': 5};

      final first = operation.keyFor(
        domain: 'civil',
        slug: 'beam-deflection',
        inputs: inputs,
      );
      final changedPayload = operation.keyFor(
        domain: 'civil',
        slug: 'beam-deflection',
        inputs: {'length': 6},
      );
      final changedCalculator = operation.keyFor(
        domain: 'structural',
        slug: 'beam-deflection',
        inputs: {'length': 6},
      );

      expect(changedPayload, isNot(first));
      expect(changedCalculator, isNot(changedPayload));
    });

    test(
      'completed calculation does not reuse its key on a later submission',
      () {
        final operation = CalculatorRequestIdempotency();
        final inputs = {'length': 5};

        final first = operation.keyFor(
          domain: 'civil',
          slug: 'beam-deflection',
          inputs: inputs,
        );
        operation.complete();
        final next = operation.keyFor(
          domain: 'civil',
          slug: 'beam-deflection',
          inputs: inputs,
        );

        expect(next, isNot(first));
      },
    );
  });

  test(
    'controller reuses a failed request key and changes it with its inputs',
    () async {
      final repository = _FailingCalculatorRepository();
      final container = ProviderContainer(
        overrides: [calculatorRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(calculatorControllerProvider.notifier);

      await controller.calculate('civil', 'beam-deflection', {'length': 5});
      await controller.calculate('civil', 'beam-deflection', {'length': 5});
      await controller.calculate('civil', 'beam-deflection', {'length': 6});

      expect(repository.idempotencyKeys, hasLength(3));
      expect(repository.idempotencyKeys[1], repository.idempotencyKeys[0]);
      expect(
        repository.idempotencyKeys[2],
        isNot(repository.idempotencyKeys[1]),
      );
    },
  );

  test(
    'calculator retry reuses its idempotency key on the replayed POST',
    () async {
      const key = '9fd94fe4-936e-4c85-98ca-13a533042921';
      final adapter = _ScriptedAdapter([
        _response(500, '{"message":"temporary failure"}'),
        _response(200, '{"success":true,"data":{"result":25}}'),
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 1,
          baseDelay: Duration.zero,
        ),
      );

      final source = CalculatorRemoteDataSource(dio);
      final result = await source.calculate(
        domain: 'civil',
        slug: 'beam-deflection',
        inputs: {'length': 5},
        idempotencyKey: key,
      );

      expect(result.data['result'], 25);
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.map((request) => request.headers['Idempotency-Key']),
        everyElement(key),
      );
    },
  );
}

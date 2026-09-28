import 'package:bisaasmobile/core/connectivity/api_reachability.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException transport(DioExceptionType type) => DioException(
      requestOptions: RequestOptions(path: '/quiz/streak'),
      type: type,
    );

void main() {
  late ApiReachability reachability;

  setUp(() => reachability = ApiReachability());
  tearDown(() => reachability.dispose());

  group('a response of any status proves reachability', () {
    // The bug: any HTTP response means bytes came back over a working
    // connection. Treating a 401/500 as "offline" is what made the banner lie.
    test('a successful response is reachable', () {
      reachability.observeResponse(
        Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: 200),
      );
      expect(reachability.isReachable, isTrue);
      expect(reachability.hasEvidence, isTrue);
    });

    test('a 401 is reachable, not offline', () {
      reachability.observeError(transport(DioExceptionType.badResponse));
      expect(reachability.isReachable, isTrue);
    });

    test('a 500 is reachable, not offline', () {
      reachability.observeError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 500,
          ),
        ),
      );
      expect(reachability.isReachable, isTrue);
    });

    test('a validation error is reachable', () {
      reachability.observeError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 422,
          ),
        ),
      );
      expect(reachability.isReachable, isTrue);
    });
  });

  group('transport failures mean unreachable', () {
    test('connection error', () {
      reachability.observeError(transport(DioExceptionType.connectionError));
      expect(reachability.isReachable, isFalse);
    });

    test('connect timeout', () {
      reachability.observeError(transport(DioExceptionType.connectionTimeout));
      expect(reachability.isReachable, isFalse);
    });

    test('receive timeout', () {
      reachability.observeError(transport(DioExceptionType.receiveTimeout));
      expect(reachability.isReachable, isFalse);
    });
  });

  test('a cancelled request proves nothing about the network', () {
    // A user navigating away mid-request must not be told the API is down.
    reachability.observeError(transport(DioExceptionType.cancel));
    expect(reachability.isReachable, isTrue);
  });

  test('a decode failure means the server answered, so it is reachable', () {
    // Claiming "offline" here would mask a real parsing bug.
    reachability.observeError(transport(DioExceptionType.transformTimeout));
    expect(reachability.isReachable, isTrue);
  });

  test('an unclassified error does not accuse the API of being down', () {
    reachability.observeError(transport(DioExceptionType.unknown));
    expect(reachability.isReachable, isTrue);
  });

  group('evidence', () {
    test('starts optimistic so a first launch shows no offline strip', () {
      expect(reachability.isReachable, isTrue);
      expect(reachability.hasEvidence, isFalse);
    });

    test('recovers when a later request succeeds', () {
      reachability.observeError(transport(DioExceptionType.connectionError));
      expect(reachability.isReachable, isFalse);
      reachability.observeResponse(
        Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: 200),
      );
      expect(reachability.isReachable, isTrue);
    });
  });

  group('onChanged', () {
    test('emits on the first piece of evidence', () async {
      final seen = <bool>[];
      reachability.onChanged.listen(seen.add);
      reachability.observeError(transport(DioExceptionType.connectionError));
      await Future<void>.delayed(Duration.zero);
      expect(seen, [false]);
    });

    test('does not re-emit while the state is unchanged', () async {
      final seen = <bool>[];
      reachability.onChanged.listen(seen.add);
      reachability.observeError(transport(DioExceptionType.connectionError));
      reachability.observeError(transport(DioExceptionType.connectionError));
      reachability.observeError(transport(DioExceptionType.receiveTimeout));
      await Future<void>.delayed(Duration.zero);
      expect(seen, [false]);
    });

    test('emits again on a genuine recovery', () async {
      final seen = <bool>[];
      reachability.onChanged.listen(seen.add);
      reachability.observeError(transport(DioExceptionType.connectionError));
      reachability.observeResponse(
        Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: 200),
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, [false, true]);
    });
  });
}

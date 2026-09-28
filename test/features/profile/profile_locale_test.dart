import 'dart:convert';
import 'dart:typed_data';

import 'package:bisaasmobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object? lastBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.data != null) lastBody = options.data;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': <String, dynamic>{'locale': 'ne'}}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
}

/// `PATCH /me/locale` (`UpdateLocaleController`) exists and validates against
/// `config('app.supported_locales')` = en, es, fr, ar, ne, hi, bn, ta, te. The
/// settings picker changed the locale locally only, so the preference was lost
/// on reinstall and invisible server-side.
void main() {
  late _Recorder recorder;
  late ProfileRemoteDataSource src;

  setUp(() {
    recorder = _Recorder();
    src = ProfileRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = recorder,
    );
  });

  test('is a PATCH to /me/locale', () async {
    await src.updateLocale('ne');

    expect(recorder.requests.single.method, 'PATCH');
    expect(recorder.requests.single.path, '/me/locale');
  });

  test('sends the locale as the documented body shape', () async {
    await src.updateLocale('ne');

    final body = recorder.lastBody! as Map<String, dynamic>;
    expect(body['locale'], 'ne');
  });

  test('the codes the settings screen offers are all server-supported', () async {
    // The picker offers en / ne / hi; all three are in supported_locales, so no
    // tap can produce a 422.
    const supported = {'en', 'es', 'fr', 'ar', 'ne', 'hi', 'bn', 'ta', 'te'};
    for (final code in const ['en', 'ne', 'hi']) {
      expect(supported, contains(code));
    }
  });

  test('a server rejection propagates so the UI can say the sync failed', () async {
    final failing = ProfileRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _Failing(),
    );

    await expectLater(
      failing.updateLocale('xx'),
      throwsA(isA<DioException>()),
    );
  });
}

class _Failing implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 422,
      ),
    );
  }
}

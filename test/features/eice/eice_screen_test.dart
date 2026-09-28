import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:bisaasmobile/features/eice/presentation/eice_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> ok(Map<String, dynamic>? data) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: <String, dynamic>{'success': true, 'data': data},
    );

void main() {
  late _MockDio dio;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() => dio = _MockDio());

  Widget host() => ProviderScope(
        overrides: [eiceRemoteProvider.overrideWithValue(EiceRemoteDataSource(dio))],
        child: const MaterialApp(home: EiceScreen()),
      );

  // The screen is a ListView of four cards; the default 800x600 test surface
  // leaves the last one unbuilt, which would read as "section missing".
  Future<void> pumpTall(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  testWidgets('renders all four sections for a healthy account', (tester) async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => ok({'exam_id': 5, 'mode': 'cover', 'items': <dynamic>[]}),
    );

    await pumpTall(tester, host());

    expect(find.text('Coach — your plan'), findsOneWidget);
    expect(find.text('Triage — cover or skip'), findsOneWidget);
    expect(find.text('Sprint — 7-day recall queue'), findsOneWidget);
    expect(find.text('Weekly report'), findsOneWidget);
  });

  testWidgets('triage is called with the exam id the coach returned', (
    tester,
  ) async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => ok({'exam_id': 12, 'mode': 'sprint'}),
    );

    await pumpTall(tester, host());

    verify(() => dio.get<Map<String, dynamic>>('/quiz/study-planner/12/triage')).called(1);
  });

  testWidgets("shows the server's own message, not a raw exception", (
    tester,
  ) async {
    // Mirrors what AuthInterceptor actually rejects with: a DioException whose
    // `error` is the mapped ApiException.
    final apiEx = ApiException.fromJson(404, {
      'error': {
        'code': 'NOT_FOUND',
        'message': 'No active target exam found.',
      },
    });
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/quiz/coach'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/quiz/coach'),
          statusCode: 404,
        ),
        error: apiEx,
      ),
    );

    await pumpTall(tester, host());

    // The real server response when a user has no target exam. It has to be
    // legible, and it must not look like an empty-but-working account.
    expect(find.text('No active target exam found.'), findsWidgets);
    expect(find.textContaining('ApiException'), findsNothing);
  });

  testWidgets('every failing section offers a Retry', (tester) async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );

    await pumpTall(tester, host());

    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('never prints the endpoint path on screen', (tester) async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => ok({'exam_id': 3}),
    );

    await pumpTall(tester, host());

    expect(find.textContaining('GET /'), findsNothing);
    expect(find.textContaining('study-planner'), findsNothing);
  });
}

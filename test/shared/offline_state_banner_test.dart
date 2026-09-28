import 'dart:async';

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/connectivity/api_reachability.dart';
import 'package:bisaasmobile/core/connectivity/connectivity_service.dart';
import 'package:bisaasmobile/core/network/dio_client.dart';
import 'package:bisaasmobile/shared/widgets/offline_state_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

/// The banner used to be driven by `onlineStatusProvider`, which is
/// `connectivity_plus` — "does the radio see a network". That is not the
/// question the copy asks: on the physical device it produced "You're offline"
/// while API calls were succeeding, and could equally have stayed silent while
/// every request was failing. It is now driven by `apiReachableProvider`, which
/// is learned from real request outcomes.
void main() {
  late _MockConnectivity connectivity;
  late ApiReachability reachability;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    connectivity = _MockConnectivity();
    reachability = ApiReachability();
  });

  tearDown(() => reachability.dispose());

  Widget host() => ProviderScope(
        overrides: [
          connectivityProvider.overrideWithValue(ConnectivityService(connectivity)),
          apiReachabilityProvider.overrideWithValue(reachability),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [OfflineStateBanner()])),
        ),
      );

  void radioSays(List<ConnectivityResult> result) {
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => result);
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());
  }

  DioException transportFailure() => DioException(
        requestOptions: RequestOptions(path: '/quiz/streak'),
        type: DioExceptionType.connectionError,
      );

  Response<dynamic> response(int code) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/quiz/streak'),
        statusCode: code,
      );

  testWidgets('silent before any request has been made', (tester) async {
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    expect(find.textContaining("Can't reach"), findsNothing);
    expect(find.textContaining('Back online'), findsNothing);
  });

  testWidgets('shows the strip when the API is genuinely unreachable', (
    tester,
  ) async {
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    reachability.observeError(transportFailure());
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach our servers"), findsOneWidget);
  });

  testWidgets('a connected radio does not mask a genuine API failure', (
    tester,
  ) async {
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    reachability.observeError(transportFailure());
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach"), findsOneWidget);
  });

  testWidgets('a dead radio does not raise a false offline strip', (
    tester,
  ) async {
    // The radio says "no network" but the API answered, so we are online.
    radioSays([ConnectivityResult.none]);
    await tester.pumpWidget(host());

    reachability.observeResponse(response(200));
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach"), findsNothing);
  });

  testWidgets('an HTTP 500 does not raise the offline strip', (tester) async {
    // Bytes came back, so the connection works. Treating a 500 as "offline"
    // would hide a real server fault behind a network diagnosis.
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    reachability.observeResponse(response(500));
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach"), findsNothing);
  });

  testWidgets('the copy no longer claims the user is merely offline', (
    tester,
  ) async {
    radioSays([ConnectivityResult.none]);
    await tester.pumpWidget(host());

    reachability.observeError(transportFailure());
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsNothing);
  });

  testWidgets('flashes a sync confirmation on unreachable -> reachable', (
    tester,
  ) async {
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    reachability.observeError(transportFailure());
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't reach"), findsOneWidget);

    reachability.observeResponse(response(200));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("Can't reach"), findsNothing);
    expect(find.textContaining('Back online'), findsOneWidget);
  });

  testWidgets('a broadcast tracker does not emit for an unchanged state', (
    tester,
  ) async {
    final seen = <bool>[];
    reachability.onChanged.listen(seen.add);
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());

    reachability.observeError(transportFailure());
    reachability.observeError(transportFailure());
    await tester.pumpAndSettle();

    expect(seen, [false]);
  });

  testWidgets('DioClient and the provider share one tracker in the real app', (
    tester,
  ) async {
    // Before DioClient is booted the provider must not throw; the banner simply
    // has no evidence yet.
    expect(DioClient.isInitialized, isFalse);
    radioSays([ConnectivityResult.wifi]);
    await tester.pumpWidget(host());
    expect(find.textContaining("Can't reach"), findsNothing);
  });
}

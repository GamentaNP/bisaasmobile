/// App-wide Riverpod glue — feature layers keep their own scoped providers
/// (see e.g. auth/presentation/controllers/auth_controller.dart).
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/analytics/analytics_service.dart';
import '../core/connectivity/api_reachability.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/network/dio_client.dart';
import '../core/notifications/local_notification_service.dart';
import 'config/app_config.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/security/app_lock.dart';
import '../core/security/biometric_auth.dart';
import '../core/storage/database/app_database.dart';
import '../core/storage/database/daos/sync_queue_dao.dart';
import '../core/storage/preferences.dart';
import '../core/consent/consent_gate.dart';
import '../core/sync/sync_manager.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_worker.dart';
import '../core/sync/daily_quiz_prefetcher.dart';
import '../features/quiz/data/datasources/quiz_local_data_source.dart';

final dioProvider = Provider<Dio>((ref) {
  if (!DioClient.isInitialized) {
    throw StateError('DioClient not init — see bootstrap.dart');
  }
  return DioClient.instance.dio;
});

/// Operator configuration from `GET /app/config`.
///
/// Starts `null` (not yet loaded) so nothing is gated on a value we do not
/// have. A failure leaves it `null` rather than substituting hardcoded
/// defaults: `feature_flags.dart` used to default `economy_enabled` to true
/// while the server said false, which is how an operator's kill-switch came to
/// be ignored.
final appConfigProvider = FutureProvider<AppConfig?>((ref) async {
  // Reuse the boot fetch rather than issuing a second identical request.
  final cached = AppConfigCache.value;
  if (cached != null) return cached;

  try {
    final config = await AppConfigDataSource(ref.watch(dioProvider)).fetch();
    AppConfigCache.value = config;
    return config;
  } on Object {
    // A config outage must not brick the app. `null` means "unknown", and every
    // consumer treats unknown as "not enforced" rather than guessing.
    return null;
  }
});

/// Synchronous view of the config, for widgets that would otherwise need a
/// nested AsyncValue. `null` until loaded or if unavailable.
final appConfigValueProvider = Provider<AppConfig?>((ref) {
  return ref.watch(appConfigProvider).value;
});

/// True only when the operator has explicitly put the app into maintenance.
/// Unknown config does NOT block: refusing to launch on a failed fetch would
/// turn a transient outage into a total outage.
final maintenanceProvider = Provider<bool>((ref) {
  return ref.watch(appConfigValueProvider)?.maintenance ?? false;
});

final preferencesProvider = Provider<Preferences>((_) => Preferences.instance);

final appDatabaseProvider = Provider<AppDatabase>((_) => AppDatabase.instance());

final syncQueueServiceProvider = Provider<SyncQueueService>(
  (ref) => SyncQueueService(SyncQueueDao(ref.watch(appDatabaseProvider))),
);

final connectivityProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(Connectivity()),
);

/// Live online/offline status. Seeds from a one-shot check then follows the
/// platform stream.
///
/// This is the *radio* state. It is deliberately NOT what the offline banner
/// shows, because "has an interface" and "can reach the API" are different
/// questions — see `apiReachableProvider`.
final onlineStatusProvider = StreamProvider<bool>((ref) async* {
  final svc = ref.watch(connectivityProvider);
  yield await svc.isOnline();
  yield* svc.onOnlineChanged;
});

/// Whether `/api/v1` is genuinely reachable, learned from real request
/// outcomes rather than from the radio.
final apiReachabilityProvider = Provider<ApiReachability>((ref) {
  // Owned by DioClient because the interceptors that feed it live there.
  if (DioClient.isInitialized) return DioClient.instance.reachability;
  // Not booted yet (tests, early startup) — an isolated instance is harmless.
  final tracker = ApiReachability();
  ref.onDispose(tracker.dispose);
  return tracker;
});

/// Banner-facing view of reachability. Optimistic until a request has actually
/// completed, so a first launch never flashes "You're offline".
final apiReachableProvider = StreamProvider<bool>((ref) async* {
  final tracker = ref.watch(apiReachabilityProvider);
  yield tracker.isReachable;
  yield* tracker.onChanged;
});

final syncManagerProvider = Provider<SyncManager>(
  (ref) {
    final manager = SyncManager(
      queue: ref.watch(syncQueueServiceProvider),
      dio: ref.watch(dioProvider),
      connectivity: ref.watch(connectivityProvider),
    );
    // Tear down the connectivity subscription when the provider is disposed
    // (tests, hot restart, app shutdown) — no leaked listeners.
    ref.onDispose(() => unawaited(manager.dispose()));
    return manager;
  },
);

final syncWorkerProvider = Provider<SyncWorker>(
  (ref) => SyncWorker(ref.watch(syncManagerProvider)),
);

/// Midnight daily-quiz prefetcher. Warms the Drift question cache so offline
/// practice has content. Started/stopped with the app lifecycle in app.dart.
final dailyQuizPrefetcherProvider = Provider<DailyQuizPrefetcher>((ref) {
  final dio = ref.watch(dioProvider);
  return DailyQuizPrefetcher(
    dio: dio,
    local: QuizLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

/// Analytics, gated on the user's consent choice.
///
/// Defined in `core/consent/consent_gate.dart` rather than here because the gate
/// and the provider have to live together: exporting a bare [AnalyticsService]
/// from this file is exactly how the ungated callsites came to exist.

/// Local notifications plugin — always available (even without Firebase).
final localNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>((_) => FlutterLocalNotificationsPlugin());

/// Lets the UI cancel the daily reminder once the daily quiz is done.
///
/// `bootstrap()` created its own instance as a local, so nothing outside it
/// could reach `cancelDaily()` and the 08:00 "keep the streak alive" nudge
/// fired even for a user who had already completed the daily.
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService(ref.watch(localNotificationsPluginProvider));
});

/// Null when Firebase is unavailable — FCM registration is skipped silently.
final pushServiceProvider = Provider<PushNotificationService?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return PushNotificationService(
    FirebaseMessaging.instance,
    ref.watch(dioProvider),
    localPlugin: ref.watch(localNotificationsPluginProvider),
    analytics: ref.watch(analyticsProvider),  );
});

final appLockProvider = Provider<AppLock>((ref) {
  final lock = AppLock(
    biometrics: BiometricAuth(LocalAuthentication()),
    lockEnabled: ref.watch(preferencesProvider).appLockEnabled,
  );
  lock.init();
  ref.onDispose(lock.dispose);
  return lock;
});

final appLinksProvider = Provider<AppLinks>((_) => AppLinks());

// ── Library feature ────────────────────────────────────────────────────────
// Library providers are defined in
// `lib/features/library/presentation/controllers/library_controller.dart`
// (libraryRemoteDataSourceProvider, libraryRepositoryProvider, libraryControllerProvider)
// and automatically use [dioProvider] via DioClient.instance.dio.
// Re-exported here for app-wide discoverability and to satisfy
// `lib/app/providers.dart` registration requirement per spec.

// ── Learning feature ───────────────────────────────────────────────────────
// Learning providers are defined in
// `lib/features/learning/presentation/controllers/learning_controller.dart`
// (learningRemoteDataSourceProvider, learningRepositoryProvider, learningControllerProvider,
//  learningTracksProvider, learningGoalsProvider, todayPlanProvider, reviewsDueProvider)
// and automatically use [dioProvider] via DioClient.instance.dio.

// ── Practice feature ───────────────────────────────────────────────────────
// Practice providers are defined in
// `lib/features/practice/presentation/controllers/practice_controller.dart`
// (practiceRemoteDataSourceProvider, practiceRepositoryProvider, practiceControllerProvider,
//  practiceBookmarksProvider, practiceAttemptHistoryProvider)
// and automatically use [dioProvider] via DioClient.instance.dio.

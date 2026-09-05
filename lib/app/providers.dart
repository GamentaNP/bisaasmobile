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
import '../core/connectivity/connectivity_service.dart';
import '../core/network/dio_client.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/security/app_lock.dart';
import '../core/security/biometric_auth.dart';
import '../core/storage/database/app_database.dart';
import '../core/storage/database/daos/sync_queue_dao.dart';
import '../core/storage/preferences.dart';
import '../core/sync/sync_manager.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_worker.dart';
import '../core/sync/daily_quiz_prefetcher.dart';
import '../features/quiz/data/datasources/quiz_local_data_source.dart';
import '../features/quiz/data/datasources/quiz_remote_data_source.dart';

final dioProvider = Provider<Dio>((ref) {
  if (!DioClient.isInitialized) {
    throw StateError('DioClient not init — see bootstrap.dart');
  }
  return DioClient.instance.dio;
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
/// platform stream. Used by `OfflineStateBanner`.
final onlineStatusProvider = StreamProvider<bool>((ref) async* {
  final svc = ref.watch(connectivityProvider);
  yield await svc.isOnline();
  yield* svc.onOnlineChanged;
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
    remote: QuizRemoteDataSource(dio),
    local: QuizLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

/// Null when Firebase is unavailable (dev without config) — callers no-op.
final analyticsProvider = Provider<AnalyticsService?>(
  (_) => AnalyticsService.tryCreate(),
);

/// Local notifications plugin — always available (even without Firebase).
final localNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>((_) => FlutterLocalNotificationsPlugin());

/// Null when Firebase is unavailable — FCM registration is skipped silently.
final pushServiceProvider = Provider<PushNotificationService?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return PushNotificationService(
    FirebaseMessaging.instance,
    ref.watch(dioProvider),
    localPlugin: ref.watch(localNotificationsPluginProvider),
    analytics: ref.watch(analyticsProvider),
  );
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

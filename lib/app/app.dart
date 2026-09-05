library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics_service.dart';
import '../core/logging/app_logger.dart';
import '../core/sync/daily_quiz_prefetcher.dart';
import '../core/sync/sync_worker.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/app_lock_overlay.dart';
import 'localization/locale_controller.dart';
import 'providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class CivilCalApp extends ConsumerStatefulWidget {
  const CivilCalApp({super.key});
  @override
  ConsumerState<CivilCalApp> createState() => _CivilCalAppState();
}

class _CivilCalAppState extends ConsumerState<CivilCalApp>
    with WidgetsBindingObserver {
  late final AppRouter _appRouter;
  StreamSubscription<Uri>? _deepLinkSub;
  StreamSubscription<String?>? _pushNavSub;
  SyncWorker? _syncWorker;
  DailyQuizPrefetcher? _prefetcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appRouter = AppRouter(ref.read(tokenManagerProvider));
    _startSync();
    _listenDeepLinks();
    _listenPushNavigation();
    _listenAuthForPushAndAnalytics();
  }

  void _startSync() {
    final manager = ref.read(syncManagerProvider);
    manager.start();
    final worker = ref.read(syncWorkerProvider);
    _syncWorker = worker;
    worker.start();
    final prefetcher = ref.read(dailyQuizPrefetcherProvider);
    _prefetcher = prefetcher;
    prefetcher.start();
  }

  void _listenDeepLinks() {
    try {
      _deepLinkSub = ref.read(appLinksProvider).uriLinkStream.listen(
            _onDeepLink,
            onError: (Object e) => AppLogger.w('Deep link stream error: $e'),
          );
    } catch (e) {
      AppLogger.w('Deep links unavailable on this platform: $e');
    }
  }

  void _onDeepLink(Uri uri) {
    final location = _appRouter.handleDeepLink(uri);
    if (location != null) _appRouter.router.go(location);
  }

  /// Push taps (FCM + local-notification mirrors) arrive as a router location
  /// (`/quiz`) or a deep-link URI (`civilcal://…`) — resolve and go.
  void _listenPushNavigation() {
    final push = ref.read(pushServiceProvider);
    if (push == null) return;
    _pushNavSub = push.navigationRequests.listen((payload) {
      if (payload == null || payload.isEmpty) return;
      final uri = Uri.tryParse(payload);
      if (uri != null && uri.scheme.isNotEmpty) {
        final location = _appRouter.handleDeepLink(uri);
        if (location != null) {
          _appRouter.router.go(location);
          return;
        }
      }
      if (payload.startsWith('/')) _appRouter.router.go(payload);
    });
  }

  /// FCM registration follows the auth session — register after login,
  /// delete on logout (`POST/DELETE /api/v1/device-tokens`).
  void _listenAuthForPushAndAnalytics() {
    ref.listenManual(authControllerProvider, (previous, next) {
      final wasIn = previous?.value != null;
      final isIn = next.value != null;
      if (wasIn == isIn) return;
      final analytics = ref.read(analyticsProvider);
      final push = ref.read(pushServiceProvider);
      if (isIn) {
        unawaited(analytics?.log(AnalyticsEvents.login));
        if (push != null) {
          unawaited(push.init().then((_) => push.registerToken()));
        }
      } else {
        unawaited(analytics?.log(AnalyticsEvents.logout));
        if (push != null) unawaited(push.unregisterToken());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final worker = _syncWorker;
    // Foreground-only polling — background work belongs to the OS worker.
    if (worker != null) {
      if (state == AppLifecycleState.paused) worker.stop();
      if (state == AppLifecycleState.resumed) worker.start();
    }
    final prefetcher = _prefetcher;
    if (prefetcher != null) {
      if (state == AppLifecycleState.paused) prefetcher.stop();
      if (state == AppLifecycleState.resumed) {
        prefetcher.start();
        // Opportunistically top-up the cache when returning to foreground.
        unawaited(prefetcher.prefetchOnce());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deepLinkSub?.cancel());
    unawaited(_pushNavSub?.cancel());
    _syncWorker?.stop();
    _prefetcher?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CivilCal',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Null → follow the system locale (falls back through supportedLocales).
      locale: ref.watch(localeProvider),
      builder: (context, child) => AppLockOverlay(
        lock: ref.watch(appLockProvider),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

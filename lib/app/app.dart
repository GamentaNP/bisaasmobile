library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/envelope.dart';
import '../core/notifications/notification_handler.dart';
import '../core/security/token_manager.dart';
import '../core/sync/daily_quiz_prefetcher.dart';
import '../core/sync/sync_worker.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../l10n/app_localizations.dart' show AppLocalizations;
import '../shared/widgets/app_lock_overlay.dart';
import 'localization/app_languages.dart';
import 'localization/locale_controller.dart';
import 'providers.dart';
import 'theme/appearance_controller.dart';
import 'package:bisaasmobile/core/consent/consent_controller.dart';
import 'package:bisaasmobile/core/consent/consent_gate.dart';
import 'package:bisaasmobile/core/consent/consent_screens.dart';
import 'force_update_screen.dart';
import 'maintenance_screen.dart';
import 'router/app_router.dart';
import 'tenant_failure_gate.dart';
import 'theme/app_theme.dart';

class LoveMcqApp extends ConsumerStatefulWidget {
  const LoveMcqApp({super.key});
  @override
  ConsumerState<LoveMcqApp> createState() => _LoveMcqAppState();
}

class _LoveMcqAppState extends ConsumerState<LoveMcqApp>
    with WidgetsBindingObserver {
  late final AppRouter _appRouter;

  /// Captured in initState — `ref` must not be used from `dispose()`, and the
  /// listener registered for session loss has to be removed there.
  late final TokenManager _tokenManager = ref.read(tokenManagerProvider);

  StreamSubscription<Uri>? _deepLinkSub;
  StreamSubscription<String?>? _pushNavSub;
  SyncWorker? _syncWorker;
  DailyQuizPrefetcher? _prefetcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appRouter = AppRouter(_tokenManager);
    _startSync();
    _listenDeepLinks();
    _listenPushNavigation();
    _listenAuthForPushAndAnalytics();
    _listenForSessionLoss();
    _askForConsentOnce();
    _warmAppConfigAfterFirstFrame();
    // Consent-gated: the gate drops this until the user has decided.
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.appOpen));
  }

  /// When the token disappears *without* the auth controller knowing — a
  /// failed mid-session refresh clears it inside the interceptor chain —
  /// re-resolve the controller so every screen watching it drops to the
  /// signed-out state instead of rendering a ghost user.
  ///
  /// Navigation itself is handled by the router's `refreshListenable`; this
  /// only keeps the provider state honest.
  void _listenForSessionLoss() {
    _tokenManager.addListener(_onSessionPresenceChanged);
  }

  Future<void> _onSessionPresenceChanged() async {
    if (!mounted) return;
    final token = await _tokenManager.readToken();
    if (mounted && (token == null || token.isEmpty)) {
      ref.invalidate(authControllerProvider);
    }
  }

  /// Starts `GET /app/config` once the first frame is on screen.
  ///
  /// It used to run in `bootstrap()`, awaited before `runApp`, which put a
  /// 578-byte request and its 15-second connect timeout between process start
  /// and first paint. Nothing about the config needed to be pre-frame: the
  /// maintenance and force-update gates are widgets that read it reactively, and
  /// `applyAppConfig` latches the version floor whenever the config lands.
  ///
  /// Warming it here rather than leaving it to first use keeps the request off
  /// the critical path without making it lazy-forever.
  void _warmAppConfigAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(appConfigProvider.future).catchError((Object _) => null),
      );
    });
  }

  /// Asks for consent the first time the app is opened, before any non-essential
  /// collection has happened.
  ///
  /// Non-essential collection is already blocked before this runs: the analytics
  /// gate reads an undecided state as "not granted". This only makes the choice
  /// available, which is the other half of the obligation. The sheet is not
  /// dismissible because there has to be a decision on record.
  ///
  /// The sheet is pushed through the go_router Navigator directly: the app
  /// root sits above that Navigator, so `showModalBottomSheet`'s
  /// `Navigator.of(context)` lookup would throw from here — and the platform
  /// error handler swallowed the throw, silently skipping first-run consent.
  Future<void> _askForConsentOnce() async {
    final consent = await ref.read(consentProvider.future);
    if (consent.decided) return;
    if (!mounted) return;
    NavigatorState? nav;
    // The router mounts with the first frame, which on a low-end device can
    // take seconds — a fixed short retry silently skipped first-run consent
    // on the QA phone. Poll up to 10s; this runs once per install.
    for (var attempt = 0; attempt < 20 && nav == null; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      nav = _appRouter.router.routerDelegate.navigatorKey.currentState;
    }
    if (!mounted) return;
    if (nav == null) {
      AppLogger.w('consent sheet skipped: navigator never mounted');
      return;
    }
    AppLogger.i('showing first-run consent sheet');
    await ConsentSheet.showWith(nav);
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
  /// (`/quiz`) or a deep-link URI (`lovemcq://…`, legacy `civilcal://…`) — resolve and go.
  void _listenPushNavigation() {
    final push = ref.read(pushServiceProvider);
    if (push == null) return;
    _pushNavSub = push.navigationRequests.listen((payload) {
      // Push payloads are untrusted — validate before handing them to the
      // router (no credential-bearing or arbitrary paths).
      final target = NotificationHandler.safeRoute(payload);
      if (target == null) return;
      final uri = Uri.tryParse(target);
      if (uri != null && uri.scheme.isNotEmpty) {
        final location = _appRouter.handleDeepLink(uri);
        if (location != null) {
          _appRouter.router.go(location);
          return;
        }
      }
      if (target.startsWith('/')) _appRouter.router.go(target);
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
        // Link events to the account behind the consent gate; without this
        // no per-user funnel or cross-session retention can be computed.
        unawaited(analytics.identifyUser(next.value?.id));
        unawaited(analytics.log(AnalyticsEvents.login));
        if (push != null) {
          unawaited(push.init().then((_) => push.registerToken()));
        }
        unawaited(_adoptAppearanceFromServer());
      } else {
        unawaited(analytics.identifyUser(null));
        unawaited(analytics.log(AnalyticsEvents.logout));
        if (push != null) unawaited(push.unregisterToken());
      }
    });
  }

  /// Sign-in is the one moment the server's `appearance` is worth reading:
  /// the web app writes the same field, so a user who picked a theme there
  /// expects it here. Strictly best-effort — an offline sign-in must still
  /// paint with the locally stored choice. [AppearanceController.adoptFromServer]
  /// ignores a null/unknown field rather than clearing that choice.
  Future<void> _adoptAppearanceFromServer() async {
    try {
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me');
      final data = requireDataMap(res.data, endpoint: '/me');
      await ref
          .read(appearanceProvider.notifier)
          .adoptFromServer(data['appearance'] as String?);
    } on Object catch (e, st) {
      AppLogger.w('appearance adoption failed: $e', e, st);
    }
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
    _tokenManager.removeListener(_onSessionPresenceChanged);
    unawaited(_deepLinkSub?.cancel());
    unawaited(_pushNavSub?.cancel());
    _syncWorker?.stop();
    _prefetcher?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No AppLocalizations lookup here — this widget sits ABOVE the
    // MaterialApp that registers the delegates, so the lookup is null on the
    // first frame and the release ErrorWidget (a plain grey screen) is all a
    // real device ever painted. The OS task-switcher title is the brand name
    // in every locale on purpose.
    const title = 'LoveMCQ';
    // The base font family is Latin-only, so the theme is rebuilt for the active
    // script. Switching language therefore re-themes the whole app rather than
    // only changing translated strings — otherwise Nepali/Chinese/Arabic text
    // renders as tofu because the styles still ask for InstrumentSans.
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(appearanceProvider);
    final light = AppTheme.forLocale(Brightness.light, languageCode: locale?.languageCode);
    final dark = AppTheme.forLocale(Brightness.dark, languageCode: locale?.languageCode);

    return MaterialApp.router(
      title: title,
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      routerConfig: _appRouter.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Driven by the language registry rather than a hand-maintained list, so
      // adding a language there is enough for Material's own strings (date
      // pickers, semantics) to localise too.
      supportedLocales: AppLanguages.supportedLocales,
      // Null → follow the system locale (falls back through supportedLocales).
      locale: locale,
      builder: (context, child) => AppLockOverlay(
        lock: ref.watch(appLockProvider),
        // Outside the lock. Force-update is the more specific condition — an
        // unsupported build cannot be repaired by waiting — so it is checked
        // first and the maintenance gate nests inside it.
        child: ForceUpdateGate(
          child: MaintenanceGate(
            // Tenant refusals are user-session scoped, so they sit inside the
            // operator-wide kill switches: a maintenance window or a forced
            // update wins over a closed workspace. The gate reads TenantStore
            // reactively and never re-fetches, so it cannot form a retry loop.
            child: TenantFailureGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}

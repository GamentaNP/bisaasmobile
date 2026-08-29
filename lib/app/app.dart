import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/token_manager.dart';
import '../l10n/app_localizations.dart';
import 'config/env.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class CivilCalApp extends ConsumerStatefulWidget {
  const CivilCalApp({super.key});
  @override
  ConsumerState<CivilCalApp> createState() => _CivilCalAppState();
}

class _CivilCalAppState extends ConsumerState<CivilCalApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(TokenManager());
  }

  @override
  Widget build(BuildContext context) {
    final env = currentEnv();
    // Touch env to ensure ApiConfig picks host early + bad-cert shim.
    final _ = env.host;
    return MaterialApp.router(
      title: 'CivilCal',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

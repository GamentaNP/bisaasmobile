import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'app/config/env.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/security/token_manager.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const ProviderScope(child: CivilCalApp()));
}

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
    // env is used by ApiConfig.baseUrl + Dio bad-cert shim
    final env = currentEnv();
    // ignore: unused_local_variable
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

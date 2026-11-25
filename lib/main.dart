import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  // Retry policy lives in RetryInterceptor only. Riverpod 3's default retry
  // would rebuild every failed network provider ~11 times on top of Dio's
  // retries, and hold the UI in AsyncLoading(retrying:true) so the error+retry
  // affordance never appears.
  runApp(
    const ProviderScope(
      retry: _noProviderRetry,
      child: CivilCalApp(),
    ),
  );
}

Duration? _noProviderRetry(int retryCount, Object error) => null;

/// Debug-only stack traces, in one place instead of a guard at every catch.
library;

import '../../core/logging/app_logger.dart';

/// Logs [stack] outside product builds.
///
/// `dart.vm.product` is false in debug **and profile**, matching the old
/// `if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);`
/// guards exactly; `AppLogger` itself suppresses debug output in release.
void debugStack(StackTrace stack) {
  if (!const bool.fromEnvironment('dart.vm.product')) {
    AppLogger.d(stack);
  }
}

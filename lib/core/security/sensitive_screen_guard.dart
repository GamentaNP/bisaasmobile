import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';

/// FLAG_SECURE guard for genuinely sensitive screens (security plan W2.7).
///
/// Scope is deliberately narrow: the official exam runner and premium content
/// readers wrap their body in [guard] and the flag is applied exactly while
/// that screen is on top. It is never applied app-wide — blanket
/// FLAG_SECURE breaks legitimate screenshots and accessibility tooling, and
/// a second device with a camera defeats it regardless (the plan rejects
/// parity promises for iOS, which has no screenshot-prevention API).
abstract final class SensitiveScreenGuard {
  static const _channel = MethodChannel('com.bisaas/security_screen');

  /// Holds the guard open for the duration of the returned scope:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return SensitiveScreenGuard.guard(
  ///     child: ExamRunnerScreen(...),
  ///   );
  /// }
  /// ```
  ///
  /// Android applies FLAG_SECURE while mounted; iOS and other platforms are
  /// no-ops (no prevention API exists — detection after the fact only).
  static Widget guard({required Widget child}) => _GuardedScope(child: child);

  /// Low-level switch. Prefer [guard]; exposed for screens that mount the
  /// sensitive surface conditionally inside an already-built widget.
  static Future<void> setSecure(bool secure) async {
    if (kIsWeb || !defaultTargetPlatform.supportsFlagSecure) return;
    try {
      await _channel.invokeMethod<void>('setFlagSecure', {'secure': secure});
    } on PlatformException catch (e) {
      // A missed flag degrades to "screenshot allowed" — never crash the
      // exam runner for it.
      AppLogger.w('SensitiveScreenGuard: setFlagSecure($secure) failed: $e');
    } on MissingPluginException {
      // Unit tests / non-Android shells.
    }
  }
}

extension on TargetPlatform {
  bool get supportsFlagSecure => this == TargetPlatform.android;
}

class _GuardedScope extends StatefulWidget {
  const _GuardedScope({required this.child});

  final Widget child;

  @override
  State<_GuardedScope> createState() => _GuardedScopeState();
}

class _GuardedScopeState extends State<_GuardedScope> {
  @override
  void initState() {
    super.initState();
    unawaited(SensitiveScreenGuard.setSecure(true));
  }

  @override
  void dispose() {
    unawaited(SensitiveScreenGuard.setSecure(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

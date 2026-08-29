import 'dart:async';

import 'sync_manager.dart';

/// Periodic background sync (poll every 30s when app foregrounded).
class SyncWorker {
  SyncWorker(this._manager);
  final SyncManager _manager;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _manager.syncNow());
  }

  void stop() => _timer?.cancel();
}

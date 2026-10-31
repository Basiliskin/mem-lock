import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../adapters/geolocator_location.dart';
import '../adapters/notification_reminders.dart';
import '../adapters/prefs_state_store.dart';
import 'watcher.dart';

/// Runs inside the foreground service's own isolate.
@pragma('vm:entry-point')
void watcherEntryPoint() => FlutterForegroundTask.setTaskHandler(_Handler());

class _Handler extends TaskHandler {
  Watcher? _watcher;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final reminders = NotificationReminders();
    await reminders.init();
    final watcher = Watcher(
      location: GeolocatorLocation(),
      store: PrefsStateStore(),
      reminders: reminders,
    );
    await watcher.start();
    _watcher = watcher;
    debugPrint('Watcher started by ${starter.name}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) => _watcher?.tick(timestamp);

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async =>
      _watcher?.stop();
}

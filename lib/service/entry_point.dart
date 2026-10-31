import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../adapters/foreground_host.dart';
import '../adapters/geolocator_location.dart';
import '../adapters/phone_health.dart';
import '../adapters/phone_reminder_output.dart';
import '../adapters/prefs_last_place.dart';
import '../adapters/prefs_quiet_places.dart';
import '../adapters/prefs_reminder_options.dart';
import '../adapters/prefs_state_store.dart';
import '../adapters/reminder_actions.dart';
import 'protection_monitor.dart';
import 'reminder_session.dart';
import 'watcher.dart';

/// Runs inside the foreground service's own isolate.
@pragma('vm:entry-point')
void watcherEntryPoint() => FlutterForegroundTask.setTaskHandler(_Handler());

class _Handler extends TaskHandler {
  Watcher? _watcher;
  ProtectionMonitor? _monitor;
  final _actions = ReceivePort();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final output = PhoneReminderOutput();
    await output.init();
    final session = ReminderSession(
      output: output,
      options: PrefsReminderOptions(),
    );
    registerActionPort(_actions.sendPort);
    _actions.listen((_) => session.stop());

    final watcher = Watcher(
      location: GeolocatorLocation(),
      store: PrefsStateStore(),
      reminders: session,
      places: PrefsLastPlace(),
      quiet: PrefsQuietPlaces(),
    );
    await watcher.start();
    _watcher = watcher;
    // A message sent before this point was dropped, so read once more.
    await watcher.syncQuietPlaces();
    final monitor = ProtectionMonitor(
      health: PhoneHealth(),
      notice: ServiceProtectionNotice(),
      onRecovered: watcher.restartLocation,
    );
    _monitor = monitor;
    await monitor.check();
    debugPrint('Watcher started by ${starter.name}');
  }

  @override
  void onReceiveData(Object data) {
    if (data == ForegroundHost.quietPlacesMessage) _watcher?.syncQuietPlaces();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _watcher?.tick(timestamp);
    _monitor?.check();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    removeActionPort();
    _actions.close();
    await _watcher?.stop();
  }
}

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../adapters/geolocator_location.dart';
import '../adapters/phone_reminder_output.dart';
import '../adapters/prefs_last_place.dart';
import '../adapters/prefs_reminder_options.dart';
import '../adapters/prefs_state_store.dart';
import '../adapters/reminder_actions.dart';
import 'reminder_session.dart';
import 'watcher.dart';

/// Runs inside the foreground service's own isolate.
@pragma('vm:entry-point')
void watcherEntryPoint() => FlutterForegroundTask.setTaskHandler(_Handler());

class _Handler extends TaskHandler {
  Watcher? _watcher;
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
    );
    await watcher.start();
    _watcher = watcher;
    debugPrint('Watcher started by ${starter.name}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) => _watcher?.tick(timestamp);

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    removeActionPort();
    _actions.close();
    await _watcher?.stop();
  }
}

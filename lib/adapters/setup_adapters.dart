import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ports/ports.dart';

class PhonePermissionGate implements PermissionGate {
  @override
  Future<PermissionState> check(SetupPermission p) async => switch (p) {
    SetupPermission.location => _state(await Permission.locationAlways.status),
    SetupPermission.notifications => _state(
      await Permission.notification.status,
    ),
    SetupPermission.activity => _state(
      await Permission.activityRecognition.status,
    ),
    SetupPermission.battery => await _batteryState(),
  };

  @override
  Future<PermissionState> request(SetupPermission p) async {
    switch (p) {
      case SetupPermission.location:
        // Android only offers "all the time" after "while using" is granted.
        final first = _state(await Permission.locationWhenInUse.request());
        if (first != PermissionState.granted) return first;
        return _state(await Permission.locationAlways.request());
      case SetupPermission.notifications:
        return _state(await Permission.notification.request());
      case SetupPermission.activity:
        return _state(await Permission.activityRecognition.request());
      case SetupPermission.battery:
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        return _batteryState();
    }
  }

  @override
  Future<void> openSettings() => openAppSettings();

  Future<PermissionState> _batteryState() async =>
      await FlutterForegroundTask.isIgnoringBatteryOptimizations
      ? PermissionState.granted
      : PermissionState.denied;

  PermissionState _state(PermissionStatus s) => s.isGranted
      ? PermissionState.granted
      : s.isPermanentlyDenied
      ? PermissionState.permanentlyDenied
      : PermissionState.denied;
}

class PrefsSetupStore implements SetupStore {
  static const _key = 'setup_done';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<bool> isDone() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> markDone() => _prefs.setBool(_key, true);
}

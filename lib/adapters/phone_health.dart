import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../ports/ports.dart';

class PrefsLocationStatus implements LocationStatusStore {
  static const _key = 'location_failing';
  final _prefs = SharedPreferencesAsync();

  Future<bool> isFailing() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> write({required bool failing}) => _prefs.setBool(_key, failing);
}

class PhoneHealth implements HealthCheck {
  final _location = PrefsLocationStatus();

  @override
  Future<ProtectionProblem?> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return ProtectionProblem.locationOff;
    }
    if (!await Permission.locationAlways.isGranted) {
      return ProtectionProblem.locationPermission;
    }
    if (!await Permission.notification.isGranted) {
      return ProtectionProblem.notifications;
    }
    if (!await Permission.activityRecognition.isGranted) {
      return ProtectionProblem.activityPermission;
    }
    if (await _location.isFailing()) {
      return ProtectionProblem.locationNotStarting;
    }
    return null;
  }

  @override
  Future<void> fix(ProtectionProblem problem) async {
    switch (problem) {
      case ProtectionProblem.locationOff:
      case ProtectionProblem.locationNotStarting:
        await Geolocator.openLocationSettings();
      case ProtectionProblem.locationPermission:
      case ProtectionProblem.notifications:
      case ProtectionProblem.activityPermission:
        await openAppSettings();
    }
  }
}

/// Tapping the service's notification opens the app, which offers the fix.
class ServiceProtectionNotice implements ProtectionNotice {
  @override
  Future<void> show({required bool protecting}) =>
      FlutterForegroundTask.updateService(
        notificationTitle: protecting
            ? Strings.serviceTitle
            : Strings.notProtecting,
        notificationText: protecting ? Strings.serviceText : Strings.tapToFix,
      );
}

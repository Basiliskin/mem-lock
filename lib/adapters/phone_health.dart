import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/strings.dart';
import '../ports/ports.dart';

class PhoneHealth implements HealthCheck {
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
    return null;
  }

  @override
  Future<void> fix(ProtectionProblem problem) async {
    switch (problem) {
      case ProtectionProblem.locationOff:
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

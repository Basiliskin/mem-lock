import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/strings.dart';
import '../ports/ports.dart';
import '../service/entry_point.dart';

class ForegroundHost implements BackgroundHost {
  static const _tickMilliseconds = 60000;

  static void init() => FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'watching',
      channelName: Strings.serviceTitle,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(_tickMilliseconds),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
    ),
  );

  @override
  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  /// A temporary permission flow, until guided setup arrives in S10. "Allow
  /// all the time" is required for the service to restart after a reboot.
  @override
  Future<bool> start() async {
    if (!await Permission.locationWhenInUse.request().isGranted) return false;
    if (!await Permission.locationAlways.request().isGranted) return false;
    await Permission.notification.request();
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: Strings.serviceTitle,
      notificationText: Strings.serviceText,
      callback: watcherEntryPoint,
    );
    return result is ServiceRequestSuccess;
  }
}

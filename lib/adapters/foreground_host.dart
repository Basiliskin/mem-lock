import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import 'prefs_language.dart';
import '../ports/ports.dart';
import '../service/entry_point.dart';

class ForegroundHost implements BackgroundHost, WatcherLink {
  /// The message sent to the service when the Quiet Places list changes.
  static const quietPlacesMessage = 'quiet_places_changed';

  /// The message sent to the service when the Reminder Places list changes.
  static const reminderPlacesMessage = 'reminder_places_changed';

  /// The message sent to the service when the Stay setting changes.
  static const detectionSettingsMessage = 'detection_settings_changed';

  /// The message sent to the service when the language changes.
  static const languageMessage = 'language_changed';

  /// The message sent to the service when the home Wi-Fi changes.
  static const homeWifiMessage = 'home_wifi_changed';

  static const _tickMilliseconds = 60000;

  static void init(String channelName) => FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'watching',
      channelName: channelName,
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

  @override
  void quietPlacesChanged() =>
      FlutterForegroundTask.sendDataToTask(quietPlacesMessage);

  @override
  void reminderPlacesChanged() =>
      FlutterForegroundTask.sendDataToTask(reminderPlacesMessage);

  @override
  void detectionSettingsChanged() =>
      FlutterForegroundTask.sendDataToTask(detectionSettingsMessage);

  @override
  void languageChanged() =>
      FlutterForegroundTask.sendDataToTask(languageMessage);

  @override
  void homeWifiChanged() =>
      FlutterForegroundTask.sendDataToTask(homeWifiMessage);

  /// Asks again for anything missing, because the main screen's button uses
  /// this after setup too. "Allow all the time" is required for the service to
  /// restart after a reboot.
  @override
  Future<bool> start() async {
    if (!await Permission.locationWhenInUse.request().isGranted) return false;
    if (!await Permission.locationAlways.request().isGranted) return false;
    await Permission.notification.request();
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    final text = await currentText();
    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: text.serviceTitle,
      notificationText: text.serviceText,
      callback: watcherEntryPoint,
    );
    return result is ServiceRequestSuccess;
  }
}

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/battery.dart';
import '../ports/ports.dart';
import 'prefs_language.dart';

class PhoneBattery implements BatterySource {
  final _battery = Battery();

  @override
  Future<BatteryReading> read() async {
    final percent = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    return BatteryReading(
      percent,
      charging: state == BatteryState.charging || state == BatteryState.full,
    );
  }
}

/// Needs the notifications plugin to be initialized in this isolate.
class PhoneLowBatteryNotice implements LowBatteryNotice {
  static const _id = 3;
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> show() async {
    final text = await currentText();
    await _plugin.show(
      id: _id,
      title: text.lowBattery,
      body: text.lowBatteryWhy,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'low_battery',
          text.lowBatteryChannel,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }
}

class PrefsLowBatteryStore implements LowBatteryStore {
  static const _key = 'low_battery_warned';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<bool> warned() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> setWarned(bool warned) => _prefs.setBool(_key, warned);
}

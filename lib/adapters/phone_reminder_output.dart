import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/reminder_options.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';
import 'default_tone.dart';
import 'reminder_actions.dart';

class PhoneReminderOutput implements ReminderOutput {
  static const _id = 1;
  final _plugin = FlutterLocalNotificationsPlugin();
  final _player = AudioPlayer();

  Future<void> init() => _plugin.initialize(
    settings: reminderNotificationSettings,
    onDidReceiveNotificationResponse: forwardAction,
    onDidReceiveBackgroundNotificationResponse: onBackgroundReminderAction,
  );

  @override
  Future<void> show({required bool alert}) => _plugin.show(
    id: _id,
    title: Strings.reminderTitle,
    body: Strings.reminderBody,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        // Sound comes from the audio player, so that it can use the alarm
        // channel. A channel's settings are fixed once created on a phone.
        'reminder_alerts',
        Strings.reminderChannel,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        playSound: false,
        enableVibration: true,
        onlyAlertOnce: !alert,
        ongoing: alert,
        autoCancel: false,
        actions: const [
          AndroidNotificationAction(
            actionHaveEverything,
            Strings.actionHaveEverything,
          ),
          AndroidNotificationAction(
            actionForgot,
            Strings.actionForgot,
            showsUserInterface: true,
          ),
        ],
      ),
    ),
  );

  /// The alarm channel plays through silent mode. The notification channel is
  /// muted by Android itself on silent, which gives "vibrate only" without
  /// having to detect the phone's sound mode.
  @override
  Future<void> play(String? customPath, SilentChoice silent) async {
    final path = customPath ?? await _defaultTonePath();
    await _player.stop();
    await _player.play(
      DeviceFileSource(path),
      ctx: AudioContext(
        android: AudioContextAndroid(
          usageType: silent == SilentChoice.aloud
              ? AndroidUsageType.alarm
              : AndroidUsageType.notification,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransient,
          stayAwake: true,
        ),
      ),
    );
  }

  Future<String> _defaultTonePath() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/default_reminder.wav');
    if (!file.existsSync()) await file.writeAsBytes(defaultToneWav());
    return file.path;
  }

  @override
  Future<void> stopSound() => _player.stop();

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);
}

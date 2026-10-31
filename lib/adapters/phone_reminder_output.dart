import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/reminder_options.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';
import 'default_tone.dart';
import 'reminder_actions.dart';

class PhoneReminderOutput implements ReminderOutput {
  /// [test] keeps a test separate from any real Reminder: it can be dismissed,
  /// and its buttons don't act on the real one.
  PhoneReminderOutput({bool test = false}) : _test = test;

  static const _id = 1;
  static const _testId = 2;
  final bool _test;
  final _plugin = FlutterLocalNotificationsPlugin();
  final _player = AudioPlayer();

  Future<void> init() => _plugin.initialize(
    settings: reminderNotificationSettings,
    onDidReceiveNotificationResponse: forwardAction,
    onDidReceiveBackgroundNotificationResponse: onBackgroundReminderAction,
  );

  @override
  Future<void> show({
    required bool alert,
    required ReminderOptions options,
  }) => _plugin.show(
    id: _test ? _testId : _id,
    title: options.title ?? Strings.reminderTitle,
    body: options.body ?? Strings.reminderBody,
    payload: _test ? testReminderPayload : null,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        // Sound comes from the audio player, so that it can use the alarm
        // channel. A channel's settings are fixed once created on a phone, so
        // each vibration choice has its own.
        _channelId(options.vibration),
        _channelName(options.vibration),
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        playSound: false,
        enableVibration: options.vibration != VibrationChoice.off,
        vibrationPattern: options.vibration == VibrationChoice.strong
            ? _strongPattern
            : null,
        onlyAlertOnce: !alert,
        ongoing: alert && !_test,
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
  Future<void> play(
    String? voicePath,
    ReminderTone tone,
    SilentChoice silent,
  ) async {
    if (voicePath != null && !File(voicePath).existsSync()) {
      throw StateError('Recording is missing');
    }
    final path = voicePath ?? await _tonePath(tone);
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

  Future<String> _tonePath(ReminderTone tone) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/tone_${tone.name}.wav');
    if (!file.existsSync()) await file.writeAsBytes(toneWav(tone));
    return file.path;
  }

  @override
  Future<void> stopSound() => _player.stop();

  @override
  Future<void> cancel() => _plugin.cancel(id: _test ? _testId : _id);

  static final _strongPattern = Int64List.fromList([
    0,
    800,
    300,
    800,
    300,
    800,
  ]);

  static String _channelId(VibrationChoice v) => switch (v) {
    VibrationChoice.normal => 'reminder_alerts',
    VibrationChoice.off => 'reminder_alerts_no_vibration',
    VibrationChoice.strong => 'reminder_alerts_strong',
  };

  static String _channelName(VibrationChoice v) => switch (v) {
    VibrationChoice.normal => Strings.reminderChannel,
    VibrationChoice.off => Strings.reminderChannelNoVibration,
    VibrationChoice.strong => Strings.reminderChannelStrong,
  };
}

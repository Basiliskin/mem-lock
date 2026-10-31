import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/detector.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';

/// The basic Reminder for S5: one fixed notification. Repeats, actions and
/// silent mode arrive in S6.
class NotificationReminders implements ReminderPlayer {
  static const _id = 1;
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  @override
  Future<void> start(StartReminder reminder) => _plugin.show(
    id: _id,
    title: Strings.reminderTitle,
    body: Strings.reminderBody,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        Strings.reminderChannel,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
      ),
    ),
  );

  @override
  Future<void> stop() => _plugin.cancel(id: _id);
}

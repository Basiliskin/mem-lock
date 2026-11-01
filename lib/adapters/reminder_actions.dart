import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const actionHaveEverything = 'have_everything';
const actionForgot = 'forgot';

/// Marks a test notification, whose buttons must not act on a real Reminder.
const testReminderPayload = 'test';
const _portName = 'leavecheck_reminder_actions';

/// Isolates in one process can reach each other through this name, which lets
/// a button tapped anywhere stop the Reminder running in the service.
void registerActionPort(SendPort port) {
  IsolateNameServer.removePortNameMapping(_portName);
  IsolateNameServer.registerPortWithName(port, _portName);
}

void removeActionPort() => IsolateNameServer.removePortNameMapping(_portName);

void forwardAction(NotificationResponse response) {
  final id = response.actionId;
  if (id == null || response.payload == testReminderPayload) return;
  IsolateNameServer.lookupPortByName(_portName)?.send(id);
}

/// Runs in its own isolate when a button is tapped with the app closed.
@pragma('vm:entry-point')
void onBackgroundReminderAction(NotificationResponse response) =>
    forwardAction(response);

const reminderNotificationSettings = InitializationSettings(
  android: AndroidInitializationSettings('@drawable/ic_notification'),
);

/// For the app's own isolate: "I forgot something" opens the app, including
/// from a cold start, and [onForgot] then shows the Last Place.
Future<void> initReminderActionsInApp(void Function() onForgot) async {
  void handle(NotificationResponse response) {
    forwardAction(response);
    if (response.actionId == actionForgot &&
        response.payload != testReminderPayload) {
      onForgot();
    }
  }

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: reminderNotificationSettings,
    onDidReceiveNotificationResponse: handle,
    onDidReceiveBackgroundNotificationResponse: onBackgroundReminderAction,
  );
  final launch = await plugin.getNotificationAppLaunchDetails();
  final response = launch?.notificationResponse;
  if (launch?.didNotificationLaunchApp == true && response != null) {
    handle(response);
  }
}

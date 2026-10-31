import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/reminder_actions.dart';
import 'l10n/strings.dart';
import 'ui/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundHost.init();
  await initReminderActionsInApp();
  runApp(
    MaterialApp(
      title: Strings.appName,
      home: MainScreen(host: ForegroundHost()),
    ),
  );
}

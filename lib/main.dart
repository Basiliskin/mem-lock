import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/prefs_last_place.dart';
import 'adapters/reminder_actions.dart';
import 'adapters/url_map_launcher.dart';
import 'l10n/strings.dart';
import 'ui/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundHost.init();
  final forgotRequests = ValueNotifier(0);
  await initReminderActionsInApp(() => forgotRequests.value++);
  runApp(
    MaterialApp(
      title: Strings.appName,
      home: MainScreen(
        host: ForegroundHost(),
        places: PrefsLastPlace(),
        map: UrlMapLauncher(),
        forgotRequests: forgotRequests,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'l10n/strings.dart';
import 'ui/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundHost.init();
  runApp(
    MaterialApp(
      title: Strings.appName,
      home: MainScreen(host: ForegroundHost()),
    ),
  );
}

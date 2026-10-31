import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/geolocator_location.dart';
import 'adapters/prefs_last_place.dart';
import 'adapters/prefs_quiet_places.dart';
import 'adapters/reminder_actions.dart';
import 'adapters/url_map_launcher.dart';
import 'l10n/strings.dart';
import 'ui/main_screen.dart';
import 'ui/quiet_places_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundHost.init();
  final forgotRequests = ValueNotifier(0);
  await initReminderActionsInApp(() => forgotRequests.value++);
  final host = ForegroundHost();
  runApp(
    MaterialApp(
      title: Strings.appName,
      home: MainScreen(
        host: host,
        places: PrefsLastPlace(),
        map: UrlMapLauncher(),
        forgotRequests: forgotRequests,
        helperSettings: (_) => QuietPlacesScreen(
          store: PrefsQuietPlaces(),
          location: GeolocatorLocation(),
          link: host,
        ),
      ),
    ),
  );
}

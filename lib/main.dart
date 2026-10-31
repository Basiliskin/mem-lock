import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/geolocator_location.dart';
import 'adapters/prefs_last_place.dart';
import 'adapters/phone_reminder_output.dart';
import 'adapters/prefs_quiet_places.dart';
import 'adapters/prefs_reminder_options.dart';
import 'adapters/reminder_actions.dart';
import 'adapters/url_map_launcher.dart';
import 'adapters/voice_recorder.dart';
import 'l10n/strings.dart';
import 'service/reminder_session.dart';
import 'ui/helper_settings_screen.dart';
import 'ui/main_screen.dart';
import 'ui/quiet_places_screen.dart';
import 'ui/reminder_options_screen.dart';

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
        helperSettings: (_) => HelperSettingsScreen(
          reminderOptions: (_) {
            final store = PrefsReminderOptions();
            return ReminderOptionsScreen(
              store: store,
              // This isolate's notifications are set up above, which keeps
              // the "I forgot something" handling in place.
              tester: ReminderSession(
                output: PhoneReminderOutput(test: true),
                options: store,
              ),
              recorder: PhoneVoiceRecorder(),
            );
          },
          quietPlaces: (_) => QuietPlacesScreen(
            store: PrefsQuietPlaces(),
            location: GeolocatorLocation(),
            link: host,
          ),
        ),
      ),
    ),
  );
}

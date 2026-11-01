import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/geolocator_location.dart';
import 'adapters/prefs_detection_settings.dart';
import 'adapters/prefs_last_place.dart';
import 'adapters/phone_battery.dart';
import 'adapters/phone_health.dart';
import 'adapters/phone_reminder_output.dart';
import 'adapters/plugin_activity.dart';
import 'adapters/prefs_language.dart';
import 'adapters/prefs_quiet_places.dart';
import 'adapters/prefs_reminder_options.dart';
import 'adapters/prefs_reminder_places.dart';
import 'adapters/reminder_actions.dart';
import 'adapters/setup_adapters.dart';
import 'adapters/url_map_launcher.dart';
import 'adapters/voice_recorder.dart';
import 'domain/language.dart';
import 'ports/ports.dart';
import 'service/reminder_session.dart';
import 'ui/app_root.dart';
import 'ui/advanced_settings_screen.dart';
import 'ui/helper_settings_screen.dart';
import 'ui/language_screen.dart';
import 'ui/localized_app.dart';
import 'ui/main_screen.dart';
import 'ui/quiet_places_screen.dart';
import 'ui/reminder_options_screen.dart';
import 'ui/reminder_places_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/stay_setting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundHost.init((await currentText()).serviceTitle);
  final languageStore = PrefsLanguage();
  final language = ValueNotifier<AppLanguage?>(
    await _savedLanguage(languageStore),
  );
  final forgotRequests = ValueNotifier(0);
  await initReminderActionsInApp(() => forgotRequests.value++);
  final host = ForegroundHost();
  final setupStore = PrefsSetupStore();

  Widget reminderOptions(BuildContext _) {
    final store = PrefsReminderOptions();
    return ReminderOptionsScreen(
      store: store,
      // This isolate's notifications are set up above, which keeps the
      // "I forgot something" handling in place.
      tester: ReminderSession(
        output: PhoneReminderOutput(test: true),
        options: store,
      ),
      recorder: PhoneVoiceRecorder(),
    );
  }

  Widget quietPlaces(BuildContext _) => QuietPlacesScreen(
    store: PrefsQuietPlaces(),
    reminderPlaces: PrefsReminderPlaces(),
    location: GeolocatorLocation(),
    link: host,
  );

  runApp(
    LocalizedApp(
      language: language,
      home: AppRoot(
        store: setupStore,
        setup: (onDone) => SetupScreen(
          gate: PhonePermissionGate(),
          host: host,
          store: setupStore,
          activityCheck: PlayServicesCheck(),
          quietPlaces: quietPlaces,
          reminderOptions: reminderOptions,
          onDone: onDone,
        ),
        main: (_) => MainScreen(
          host: host,
          places: PrefsLastPlace(),
          map: UrlMapLauncher(),
          forgotRequests: forgotRequests,
          health: PhoneHealth(),
          battery: PhoneBattery(),
          helperSettings: (_) => HelperSettingsScreen(
            reminderOptions: reminderOptions,
            staySetting: (_) =>
                StaySettingScreen(store: PrefsDetectionSettings(), link: host),
            advancedSettings: (_) => AdvancedSettingsScreen(
              store: PrefsDetectionSettings(),
              link: host,
            ),
            quietPlaces: quietPlaces,
            reminderPlaces: (_) => ReminderPlacesScreen(
              store: PrefsReminderPlaces(),
              quiet: PrefsQuietPlaces(),
              location: GeolocatorLocation(),
              link: host,
            ),
            language: (_) => LanguageScreen(
              store: languageStore,
              link: host,
              language: language,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Unreadable storage follows the phone.
Future<AppLanguage?> _savedLanguage(LanguageStore store) async {
  try {
    return await store.read();
  } on Object {
    return null;
  }
}

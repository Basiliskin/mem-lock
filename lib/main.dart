import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'adapters/foreground_host.dart';
import 'adapters/geolocator_location.dart';
import 'adapters/prefs_detection_settings.dart';
import 'adapters/prefs_last_place.dart';
import 'adapters/phone_battery.dart';
import 'adapters/phone_health.dart';
import 'adapters/phone_reminder_output.dart';
import 'adapters/phone_wifi.dart';
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
import 'features.dart';
import 'ports/ports.dart';
import 'service/reminder_session.dart';
import 'ui/app_root.dart';
import 'ui/advanced_settings_screen.dart';
import 'ui/helper_settings_screen.dart';
import 'ui/check_items_screen.dart';
import 'ui/check_screen.dart';
import 'ui/family_settings_screen.dart';
import 'ui/home_wifi_screen.dart';
import 'ui/forgot_screen.dart';
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
  final checkRequests = ValueNotifier(0);
  await initReminderActionsInApp(
    () => forgotRequests.value++,
    onOpen: homeWifiOnly ? () => checkRequests.value++ : null,
  );
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

  Widget homeWifi(BuildContext _) => HomeWifiScreen(
    store: PrefsHomeWifi(),
    wifi: PhoneWifi(),
    location: GeolocatorLocation(),
    link: host,
  );

  Widget languageScreen(BuildContext _) =>
      LanguageScreen(store: languageStore, link: host, language: language);

  // Home Wi-Fi mode's own family settings: a short list of pages.
  Widget familySettings(BuildContext _) => FamilySettingsScreen(
    home: PrefsHomeWifi(),
    items: PrefsCheckItems(),
    homeWifi: homeWifi,
    whatToCheck: (_) => CheckItemsScreen(store: PrefsCheckItems()),
    howToRemind: reminderOptions,
    language: languageScreen,
  );

  Widget check(BuildContext context) => CheckScreen(
    items: PrefsCheckItems(),
    onAllDone: () => sendReminderAction(actionHaveEverything),
    onGoBack: () async {
      sendReminderAction(actionForgot);
      final navigator = Navigator.of(context);
      final places = await PrefsLastPlace().read();
      if (places.isEmpty) {
        navigator.pop();
        return;
      }
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ForgotScreen(
            place: places.first,
            previous: places.length > 1 ? places[1] : null,
            map: UrlMapLauncher(),
          ),
        ),
      );
    },
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
          homeWifi: homeWifiOnly ? homeWifi : null,
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
          homeWifi: homeWifiOnly ? PrefsHomeWifi() : null,
          homeWifiScreen: homeWifiOnly ? homeWifi : null,
          checkRequests: homeWifiOnly ? checkRequests : null,
          checkScreen: homeWifiOnly ? check : null,
          helperSettings: homeWifiOnly
              ? familySettings
              : (_) => HelperSettingsScreen(
                  reminderOptions: reminderOptions,
                  // Switched off features keep their screens, without a link.
                  homeWifi: homeWifiOnly ? homeWifi : null,
                  staySetting: homeWifiOnly
                      ? null
                      : (_) => StaySettingScreen(
                          store: PrefsDetectionSettings(),
                          link: host,
                        ),
                  advancedSettings: homeWifiOnly
                      ? null
                      : (_) => AdvancedSettingsScreen(
                          store: PrefsDetectionSettings(),
                          link: host,
                        ),
                  quietPlaces: homeWifiOnly ? null : quietPlaces,
                  reminderPlaces: homeWifiOnly
                      ? null
                      : (_) => ReminderPlacesScreen(
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

/// Feature flags, set at build time from `.env`:
/// `flutter run --dart-define-from-file=.env`.
library;

/// Only the home Wi-Fi Reminder runs. Stays, Rides, Quiet Places and Reminder
/// Places are kept in the code but switched off and hidden.
const homeWifiOnly = bool.fromEnvironment('HOME_WIFI_ONLY', defaultValue: true);

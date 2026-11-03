# LeaveCheck

A phone app that reminds elderly people to check their belongings when they leave a place or get off a vehicle. It runs on Android, in Russian and English, and is still in testing: Reminders after a Stay and after a Ride are built, but field tests have not been run, and Ride timings are placeholders until they are tested on real rides.

A Helper sets the app up for the Wearer, and can also set Quiet Places, Reminder Places with their own message, custom Reminders, the language and advanced detection settings.

See `docs/idea.md`, `docs/requirements.md`, `docs/architecture.md` and `docs/design.md`.

```bash
flutter pub get
flutter run --dart-define-from-file=.env
flutter test
flutter analyze
```

`.env` holds build-time feature flags. `HOME_WIFI_ONLY=true` (also the default without the file) runs only the home Wi-Fi Reminder: the Helper marks the home Wi-Fi, and walking out as the phone loses it gives a Reminder. Set it to `false` for Stays, Rides, Quiet Places and Reminder Places.

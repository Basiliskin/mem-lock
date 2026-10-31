# Ride Probe (S1)

A throwaway app that measures how quickly Android notices someone got off a vehicle. It feeds the early FT-2 check, and nothing in `lib/` of the main app may import it.

## Run a journey

1. Install with `flutter run --release` on the test phone, then open the app and grant the permissions.
2. Tap **Start logging** before you travel.
3. Tap the vehicle type as you board, then lock the phone and keep it on your body.
4. At your first step after getting off, unlock and tap **I got off and started walking**. Keep walking normally for at least 2 minutes, with the phone back on your body.
5. Do not swipe the app away. Repeat for the next ride, and tap **Stop logging** at the end of the day.

Unlocking to tap is a compromise: it could slightly affect the reading, so note any odd rides. Aim for 10 rides overall, with a mix of the types you care about.

## Read the results

```bash
adb pull /sdcard/Android/data/com.geoalert.probe.ride_probe/files/ logs/
dart run tool/report.dart logs/files/*.jsonl
```

The report gives each ride's delay, whether a vehicle was seen, walking signals during the ride (each a possible false Reminder), results by type, the longest gap in the log, and the verdict. A gap well over 30 seconds means the phone paused the app, so treat that ride with caution.

**The logs hold real places you travelled.** `logs/` is ignored by git. Remove or shift the coordinates before saving any log as a test fixture in `test/fixtures/`.

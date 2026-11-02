# Steps Probe (S21)

A throwaway app that measures whether the phone's step and motion sensors notice walking clearly sooner than Activity Recognition (AC-14.1). Nothing in `lib/` of the main app may import it. It also checks the Unbroken Walk idea: walking without a pause over 3 seconds, with no direction. It logs no places and never the phone's running step total, only the steps since the previous signal.

## Run a session

Install on a real phone with `flutter run --release`, because emulators have no step sensor. Then open the app and follow it. It shows a checklist and the next activity, gives the instructions, vibrates when to start and when the minimum time is reached, and remembers progress between sessions. You can tap any activity to do it out of order, such as a vehicle ride when you happen to be on a bus. Stopping before the minimum discards that activity.

After the first walk, it warns you if the phone gave no step signals. Don't swipe the app away during an activity, because that activity is lost.

What it asks for first: 10 departures from home and 2 router restarts that drop Wi-Fi, with the phone on the home Wi-Fi at the start. Then: 10 normal walks of 2 minutes, 4 segments of sitting or riding of 5 minutes, 3 elderly walks of 2 minutes by an elderly person, ideally a real Wearer, and 8 hours of daily life without really leaving the place.

## Read the results

Tap **Show results** in the app, or **Share results** to send the report and a zip of the raw logs through any app on the phone, such as email or a messenger. The logs hold timing, activity and steps-per-signal data, but no places. Or copy the logs to a computer:

```bash
adb pull /sdcard/Android/data/com.leavecheck.probe.steps_probe/files/ logs/
dart run tool/report.dart logs/files/*.jsonl
```

The verdict is **keep** only if a sensor is seen on at least 90% of walks, has a median delay at least 15 s shorter than Activity Recognition, and gives false signals in no more still segments than Activity Recognition. Otherwise it is **drop**, and AC-14.2 applies. A gap well over 2 seconds in the log means the phone paused the app, so treat that session with caution.

**Leaving home** is a separate verdict. It **passes** only if Wi-Fi drops within 50 steps (about 30 m) of the door closing, with walking within 30 s of the drop, on at least 90% of departures, and no router restart looks like leaving. Only whether Wi-Fi is connected is logged, never the network's name.

**Unbroken Walk** is a separate verdict. It **passes** only if at least 90% of normal walks and at least 90% of elderly walks reach 40 unbroken steps, and daily life gives no more than 1 false walk at 40 steps per 16 waking hours. The report also shows other pauses and limits, for tuning. The main app builds this only if both verdicts allow it.

Record the report in `docs/qa-report.md`.

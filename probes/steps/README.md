# Steps Probe (S21)

A throwaway app that measures whether the phone's step and motion sensors notice walking clearly sooner than Activity Recognition (AC-14.1). Nothing in `lib/` of the main app may import it. It logs no places and no step counts, only that a signal happened.

## Run a session

1. Install on a real phone with `flutter run --release`, open the app and grant the permissions. Emulators have no step sensor, so their results don't count.
2. Tap **Start logging**. Don't swipe the app away.
3. **Walks (at least 10):** tap **Walk**, lock the phone, put it on your body and stand still. When it vibrates, start walking. Walk for at least 2 minutes, then tap **End**. Stand or sit for a minute between walks.
4. **Still segments (at least 4):** do the same with **Sit still** and **Ride in a vehicle**, for at least 5 minutes each, including a bumpy ride if you can. These measure false signals.
5. Tap **Stop logging**.

## Read the results

```bash
adb pull /sdcard/Android/data/com.leavecheck.probe.steps_probe/files/ logs/
dart run tool/report.dart logs/files/*.jsonl
```

The verdict is **keep** only if a sensor is seen on at least 90% of walks, has a median delay at least 15 s shorter than Activity Recognition, and gives false signals in no more still segments than Activity Recognition. Otherwise it is **drop**, and AC-14.2 applies. A gap well over 2 seconds in the log means the phone paused the app, so treat that session with caution.

Record the report in `docs/qa-report.md`.

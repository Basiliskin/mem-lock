# Decision Log

## 2026-10-31 · /product

- **Field test bars:** walks at least 9 of 10 within 100 m; trains at least 8 of 10 within 60 seconds of starting to walk, recorded by train type; if the train test fails, Ride detection leaves v1. Files: `docs/requirements.md`.
- **Last Place display:** the app shows the time and a button that opens the phone's map app, with no map inside the app. Files: `docs/requirements.md`, `docs/idea.md`.
- **Recorded voice:** in v1, moving to the first update if it cannot play reliably on a locked phone. Files: `docs/requirements.md`.
- **Scope cut:** confirmed as listed in `docs/requirements.md`. Files: `docs/requirements.md`.

## 2026-10-31 · /architect

- **Background:** Dart inside an Android foreground service, with native Kotlin as the fallback. Files: `docs/architecture.md`.
- **Silent mode:** the Helper chooses "play aloud" (default) or "vibrate only". Files: `docs/architecture.md`.
- **Ride detection:** Activity Recognition first, with GPS speed as a check. Files: `docs/architecture.md`.

## 2026-10-31 · /designer

- **UX:** Variant A, one big status with step-by-step setup. Files: `docs/design.md`, `prototypes/`.

## 2026-10-31 · /developer S1

- **Activity plugin:** `activity_recognition_flutter` for the probe, which requires minSdk 26. Files: `probes/ride/`, `docs/architecture.md`.

## 2026-10-31 · /developer S5

- **Wake on movement:** low-power location checks during a Stay, switching to precise when a reading looks outside the area. AC-9.1 reworded. Files: `docs/requirements.md`, `docs/architecture.md`, `lib/`.

## 2026-10-31 · /developer S8

- **Quiet Places sync:** the screens own the saved list; the service re-reads it on a message and at every start, so a change made while it is stopped isn't lost. One-off fix moved to its own `CurrentFixSource` port. Files: `docs/architecture.md`, `lib/`.
- **Helper entry:** S8 adds the 2-second long press from the design, opening Quiet Places directly. S10 builds the rest of protected settings. Files: `lib/ui/main_screen.dart`.

## 2026-10-31 · /developer S9

- **Recorded voice:** built before S2 has a recorded verdict; FT-5 on the real app is the gate, and a failure hides the option. Files: `lib/`, `android/app/src/main/AndroidManifest.xml`.
- **Sound choice:** three tones generated in the app, with no ringtone or file picker. Files: `lib/adapters/default_tone.dart`.
- **Vibration:** off, normal or strong, each with its own notification channel. Files: `lib/adapters/phone_reminder_output.dart`.

## 2026-10-31 · /developer S10

- **Protected settings:** the 2-second long press alone meets AC-7.5, so no code is added. Files: `lib/ui/main_screen.dart`.
- **Setup:** all four permissions block Next, as in the chosen prototype. Watching starts on the last step's button. Files: `lib/ui/setup_screen.dart`, `lib/ui/app_root.dart`.

## 2026-10-31 · /developer S11

- **Warnings:** the service checks health every minute and rewrites its persistent notification; the main screen checks on resume and every 5 seconds. Recovery restarts location readings. Activity and battery optimisation aren't checked, because Stay detection works without the first and the second is not a permission. Files: `lib/service/protection_monitor.dart`, `lib/adapters/phone_health.dart`, `lib/ui/main_screen.dart`.

## 2026-10-31 · /developer S12

- **Low battery warning:** the service posts one notification per low-battery period, and the main screen shows a note while the battery is low. Low is 20% or under and not charging; a period ends on charging or above 25%. The "warned" flag is saved, so a service restart can't warn again. Files: `lib/domain/battery.dart`, `lib/service/battery_monitor.dart`, `lib/adapters/phone_battery.dart`, `lib/ui/main_screen.dart`, `pubspec.yaml` (battery_plus).
- **Stay setting:** More often is 3 min / 75 m, Normal 5 min / 75 m, Less often 10 min / 100 m, to be tuned from the field tests. A Stay keeps the distance it began with, so changing the setting during a Stay can't start a false Reminder. Files: `lib/domain/detector.dart`, `lib/domain/detector_json.dart`, `lib/service/watcher.dart`, `lib/ui/stay_setting_screen.dart`.
- **Two Last Places:** the previous place has its own map button, added to the wireframe's design. Saved under the same key, and text saved as one place still reads. Files: `lib/domain/last_place_record.dart`, `lib/adapters/prefs_last_place.dart`, `lib/ui/forgot_screen.dart`, `docs/design.md`, `GLOSSARY.md`.

## 2026-10-31 · /qa

- **Ride:** build S4 logic against synthetic rides in the S1 log format, then confirm with real rides and FT-2. Setup makes no train or bus claim until FT-2 passes. Files: `lib/l10n/strings.dart`, `docs/qa-report.md`.
- **Fixes:** README, `pubspec.yaml` description and a stale test name corrected. Shared warning note and `_quietly` deferred. Files: `README.md`, `pubspec.yaml`, `test/service/watcher_test.dart`.

## 2026-10-31 · /developer S4

- **Ride rules, logic only:** built against synthetic rides in the S1 log format, because no real rides exist. S4's "done when" (real recorded rides) is still open. Files: `lib/domain/detector.dart`, `lib/domain/detector_json.dart`, `test/domain/ride_test.dart`, `test/domain/ride_replay_test.dart`, `test/fixtures/synthetic_ride_*.jsonl`.
- **Placeholder values, to retune from real rides:** a Ride starts at 75% vehicle confidence, other signals count from 50%, 30 seconds of walking confirms getting off, over 4 m/s between readings means still in the vehicle.
- **Missed ride ends:** with no sign of a vehicle for 15 minutes, the Ride ends with a Reminder, so Stay detection can't stay stuck. This may give a false Reminder on a long tunnel ride; check it in the logs.
- **Quiet Places:** a Ride ending at one gives no Reminder, as in the settled decisions.
- **Last Place:** the last trusted reading before walking began, which may be old after a tunnel. With no reading at all, the Reminder waits for the first one.

## 2026-10-31 · /architect

- **S14 added before S1 results:** no ride logs exist, so the `ActivitySource` slice goes ahead with S4's placeholder values. S1's rides, S4's real-ride check and FT-2 stay open, and FT-2 still decides whether Ride stays in v1. Files: `docs/architecture.md`.
- **Activity plugin in the service:** no plugin foreground service, and its health service and permission are removed from the manifest. Files: `docs/architecture.md`.
- **Play services check at setup:** the plugin doesn't report a failed registration to Dart, so setup checks directly. Files: `docs/architecture.md`.

## 2026-10-31 · /developer S14

- **Plugin patch:** a copy of activity_recognition_flutter 6.1.0 in `packages/`, because closing the screens would otherwise stop activity updates for the whole app. On detach, only the listening engine now stops them. Found by reading the code, not yet reproduced on a phone. Files: `packages/activity_recognition_flutter/`, `pubspec.yaml`.
- **Play services check:** google_api_availability, with the note on the activity step. A failing check shows no note, and the permission is still required. Files: `lib/adapters/plugin_activity.dart`, `lib/ui/setup_screen.dart`, `lib/l10n/strings.dart`.

## 2026-10-31 · /developer AC-8.2 fix

- **Activity permission warning:** removing it now shows "Not protecting you", replacing the S11 decision not to check it, because S14 makes Ride Reminders depend on it. Battery optimisation is still not checked. Files: `lib/adapters/phone_health.dart`, `lib/ports/ports.dart`, `lib/ui/main_screen.dart`, `lib/l10n/strings.dart`.
- **Recovery:** clearing any warning also makes the Watcher listen for activity again, because a failed registration isn't retried. Files: `lib/service/watcher.dart`, `lib/service/entry_point.dart`.

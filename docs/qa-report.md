# Geo Alert: QA Report

Run 2026-10-31 on commit 76b6afe. Verdict: **not ready for release.** See "Blocking gaps".

## Results

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 239 passed, 0 failed |
| Clean copy of the tracked files: `flutter pub get`, `flutter test`, `flutter build apk --release` | All passed; APK built |
| Release manifest | No `INTERNET` permission (supports AC-5.6); no health service or permission (S14) |
| Emulator smoke test (Android 16, Medium Phone API 36.1) | See "Emulator results" |
| S14 real ride | **Not reported:** the request still held a placeholder, so S14 stays open |
| Activity permission check on a real phone | **Not reported:** placeholder as above; checked on the emulator instead |
| FT-1 to FT-5 | **Not run:** no results are recorded anywhere |

## Emulator results

The emulator proves the app runs and its parts connect. It doesn't replace phone or field tests.

| Check | Build | Result |
|---|---|---|
| Launch, then all 9 setup steps with permissions granted through adb | Release | Pass; the service runs as a location foreground service |
| Activity updates register in the service | Release | Pass: "Registered for activity updates" |
| An activity event reaches the Watcher in the service isolate | Debug, temporary logging | Pass, with the screens open |
| Remove the activity permission | Release | Pass: Android restarted the service, and the notification and main screen both warn |
| Re-grant it | Release | Pass: updates registered again and the warning cleared |
| Turn location off | Release | Pass: the notification warned |
| Turn location back on | Release | Pass: with the app in the background, the notification warned within 30 s of turning location off and read "Защита работает" again within 65 s of turning it on. The main screen did the same. The service checks every 60 s, so a warning can take up to a minute |
| Refuse the location permission | Release | Pass: Next stays blocked with a reason, and after two refusals the button opens phone settings. No crash |
| Restart the phone without opening the app | Release | Pass: "Watcher started by system", foreground service running, notification "Защита работает" |
| Short tap, then 2.5 s press, on the Helper entry | Release | Pass: a short tap does nothing; the long press opens the Helper settings |
| Stay, leave, one Reminder, Last Place saved | Debug, **temporarily changed to `LocationManager` and GPS in both modes** | Pass |
| The same journey on the shipped location settings | Release | **Fail:** no Reminder and no fixes reached the Watcher. See blocking gap 0. Simulated fixes did reach the phone's fused location, so the failure is in the app's stream start, not the simulation |
| Activity updates keep arriving after the screens close (plugin patch) | Release | **Not proven:** the service stayed up with no errors, but no event was seen afterwards |

## Acceptance criteria

"Logic" means automated tests cover the logic with fakes, not the real phone.

| AC | Covered by | Status |
|---|---|---|
| 1.1, 1.2, 1.4, 1.5 | `test/domain/detector_test.dart`, `test/domain/replay_test.dart` | Logic; FT-1, FT-3 open |
| 1.3 | `detector_test.dart`, `test/service/watcher_test.dart` | Logic |
| 2.1, 2.2, 2.3 | `test/domain/ride_test.dart`, `test/domain/ride_replay_test.dart` (synthetic rides), `test/service/watcher_test.dart` (activity signals, with fakes) | Logic only; signal on a real phone, real rides and FT-2 open |
| 3.1, 3.2, 3.3 | `test/service/reminder_session_test.dart` | Logic |
| 3.4 | manual | **Open** |
| 3.5 | `reminder_session_test.dart`, `test/ui/setup_screen_test.dart` | Logic; phone open |
| 4.1, 4.3, 4.4 | `reminder_session_test.dart`, `test/ui/reminder_options_screen_test.dart` | Logic |
| 4.2 | manual, FT-5 | **Open** |
| 4.5 | `reminder_options_screen_test.dart` | Logic; hearing and feeling it open |
| 5.1, 5.2, 5.4 | `test/ui/forgot_screen_test.dart` | Logic |
| 5.3 | `ride_test.dart` | Logic only; showing a Ride's advice on the screen not checked |
| 5.5 | `test/domain/s12_test.dart` | Logic |
| 5.6 | `forgot_screen_test.dart`, release APK check | Pass |
| 6.1 to 6.4 | `test/ui/quiet_places_screen_test.dart`, `detector_test.dart`, `watcher_test.dart` | Logic |
| 7.1 to 7.4 | `setup_screen_test.dart` | Logic; fresh install open |
| Error table, D3: no Play services | `setup_screen_test.dart` (note), `test/adapters/plugin_activity_test.dart` (kinds) | Logic; a phone without Play services open |
| 7.5 | `test/widget_test.dart` (Helper entry group) | Logic |
| 8.1 | manual; `autoRunOnBoot` is set in `lib/adapters/foreground_host.dart:25` | Passed on the emulator; real phone open |
| 8.2 | `widget_test.dart`, `test/service/protection_monitor_test.dart` | Activity permission removed: passed on the emulator. Location off: warning passed. Real phone open |
| 8.3 | `widget_test.dart`, `test/service/protection_monitor_test.dart` | Logic; phone open |
| 8.4 | `widget_test.dart` | Logic; persistent notification open |
| 9.1 | `test/domain/location_mode_test.dart` | Logic; FT-4 open |
| 9.2 | `test/service/battery_monitor_test.dart`, `widget_test.dart` | Logic; phone open |
| 10.1, 10.2 | `s12_test.dart`, `watcher_test.dart`, `test/ui/stay_setting_screen_test.dart` | Logic; phone open |

## Blocking gaps

0. **Watching can silently stop, while the app says "Защита работает".** Found on the emulator with the shipped location settings (release build plus one temporary log line). The location stream failed at service start with "The location service on the device is disabled", although location was on, with or without test providers and with Wi-Fi scanning on or off. No fixes arrived. A 6-minute simulated Stay and walk of 330 m on the unmodified release build gave no Reminder. `Geolocator`'s settings check returns this error when it fails and has no activity to ask from (`FusedLocationClient.startPositionUpdates`). `lib/service/watcher.dart:47` ignores stream errors, no retry follows, and `lib/adapters/phone_health.dart` doesn't see it. The exact settings status wasn't captured, and how often real phones hit this is unknown.

   **Warning fixed (uncommitted), root cause not:** the service now retries every 60 s and warns. On the emulator, the fixed release build showed "Защита не работает" in the notification and main screen within about 2 minutes. There it still gets no fixes, so the Stay journey stays unproven. Clearing after a successful retry is covered only by a test with fakes.

1. **Ride detection is unproven on a phone.** S14 connects the activity signal, but tests use fakes. The emulator shows a signal reaching the service, but with the screens open and no real movement. The real-ride result wasn't reported, and the plugin patch is unproven.
2. **The shipped location settings are unproven.** The full journey only passed on the emulator with location settings changed temporarily. FT-1 must confirm it.
3. **No field or phone results.** FT-1 to FT-5 and the S1 and S2 gates have no recorded results. FT-2 still decides whether Ride stays in v1.

## Audit against the Engineering rules

| Rule | Result |
|---|---|
| Detection separate from Flutter and plugins | Pass: `test/architecture_test.dart` enforces it for `lib/domain` |
| Plugins only through thin wrappers | Pass, with the same two exceptions: `lib/service/entry_point.dart:4` and `lib/main.dart:2` use `flutter_foreground_task` directly. Both are start-up wiring. The new activity and Play services plugins are used only in `lib/adapters/plugin_activity.dart` |
| Location stays on the phone | Pass: no `INTERNET` permission in the release APK; the only exit is the `geo:` link in `lib/adapters/url_map_launcher.dart` |

Smaller findings:

- **Duplication:** the warning colour and note box are repeated in five screens, for example `lib/ui/main_screen.dart:286`, `lib/ui/forgot_screen.dart:99` and `lib/ui/setup_screen.dart:216`. `_quietly` is repeated in `lib/service/watcher.dart`, `lib/service/protection_monitor.dart`, `lib/service/reminder_session.dart` and `lib/ui/reminder_options_screen.dart`.
- **Vendored plugin:** `packages/activity_recognition_flutter` has iOS code the app doesn't use, and is excluded from `flutter analyze`.
- **Dead code:** no unused classes or unimported files found. This was a name search only, so unused methods aren't ruled out.
- **Test gap:** `lib/adapters/phone_health.dart:10` has no direct test, because it only wraps plugin calls. The emulator checks above exercised it for location off and the location permission, and the earlier run for the activity permission. Removing the notification permission hasn't been tried.
- **Warning delay:** the notification can take up to 60 s to warn (`lib/adapters/foreground_host.dart:15`). The requirements set no time limit.
- **Release signing:** `android/app/build.gradle.kts:37` signs release builds with the debug key.

Decisions on these findings:

| Finding | Decision |
|---|---|
| Release signing | Defer: fix just before the first Play upload |
| Repeated warning box and `_quietly` | Defer until after the field tests |
| Start-up plugin imports, vendored iOS code, no direct `phone_health` test, warning delay | Ignore |

## Release readiness

| Item | Status |
|---|---|
| README | Fixed |
| `pubspec.yaml` description | Fixed |
| Secrets | None found in tracked files |
| Env example | Not needed: no environment settings |
| Release signing | **Uses the debug key** (`android/app/build.gradle*`, line 37) |
| Play background location | Declaration not submitted; the risk in `docs/play-policy-check.md` is still open |

## Field test log

No real walks recorded yet, so S15 stays open.

S15 emulator check, 2026-11-01, uncommitted `LocationManager` fallback, release build, Android 16 emulator:

- **Fallback:** fused location's failed start moved to `LocationManager` at once, with no warning. Fixes reached the Watcher, the Stay was detected, and low-power mode began after 5 minutes. Before the fallback, no fixes arrived.
- **Walk on simulated GPS only:** no Reminder after 330 m. Low-power mode asks for balanced accuracy, which didn't use the simulated GPS, so the app's location stayed at the cafe.
- **Same walk on a test fused provider:** Reminder "Ваши вещи с вами?" within 3 readings, about 30 m further on. This bypasses Google's fused location, so it proves the app's logic and not how soon a real phone notices leaving.
- **Warning:** adding the test provider caused "Защита не работает". The next 60 s retry cleared it.
- **Open for the real walk:** whether low-power readings notice leaving within 100 m (FT-1), and whether real phones hit the failed start at all.

S16 emulator check, 2026-11-01, uncommitted, release build, Android 16 emulator with the phone set to Russian:

- **Nothing chosen:** screens and the service's own location warning were in Russian, so the service sees the phone's language.
- **English chosen:** screens and the service notification changed at once. After a Stay and a walk on a test fused provider, the Reminder and both its buttons were in English.
- **Warning recovery:** after location came back on, the warning took about 110 s to clear, because it takes two 60 s checks. The earlier report measured 65 s, before the S15 fallback.
- **Not run on the emulator:** a phone in another language, and a Reminder with custom text or a recording in the new language. These are covered by tests or existing code only.

## S21: Step experiment (AC-14.1 to 14.3)

**Status: open. No real walks yet, so no keep-or-drop decision.** Steps stay out of the release until there is one, and the main app has no step code or added permission.

- **Built:** `probes/steps`, with a report tool. Its logs hold no places and no step counts.
- **Rule for a clear benefit:** at least 10 walks and 4 still segments; seen on at least 90% of walks; median delay at least 15 s shorter than Activity Recognition; false signals in no more still segments than Activity Recognition.
- **Emulator check only:** over three short runs, the probe started and motion logging continued for about 40 s with the screen locked. The step stream reported "not available" once and stayed silent in the other two runs. One Activity Recognition signal arrived, in the first run only. No step or pedestrian signal has been seen, so the step path is untested, and this says nothing about the sensors' benefit.
- **First real session:** after one short walk, check that the report shows step, pedestrian and activity signals before doing the full set.
- **Real-walk results:** to be added here from `tool/report.dart`.

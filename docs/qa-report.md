# LeaveCheck: QA Report

## Latest run: 2026-11-01, full build (S1 to S22)

Run on `release/leavecheck` at 72be996 plus the uncommitted S20, S21 and S22 changes. Verdict: **not ready for release.** The code passes its checks, but the field tests, a real walk and the Play steps are still open. Sections below "Earlier run" are kept as history and use the old name; this section replaces their verdict.

### Results

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 394 passed, 0 failed |
| `probes/steps` tests | 14 passed, 0 failed |
| Clean copy of tracked and new files: `flutter pub get`, `flutter test`, `flutter build apk --release` | All passed; APK built |
| Release APK | `com.leavecheck.app`, target SDK 36, no `INTERNET` permission |
| Signed bundle | Built and signed with a throwaway key; no build signed with the real upload key yet |
| Listing validator | Passed; phone screenshots still missing |
| Secrets | No keystore, key properties or service account files in tracked or new files; a pattern search of `lib`, `android`, `fastlane` and `docs` found no credentials |

### Emulator results (release build, Android 16, simulated location)

| Check | Result |
|---|---|
| Fresh install, then all 9 setup steps, with permissions granted through adb | Pass; "Protection is on", location foreground service running |
| Location disclosure on step 2 | Pass: shown before the permission is granted |
| Stay, then walk at about 5 km/h on a test fused provider | Pass: one Reminder after 107 m from the Stay point, with both buttons |
| "I have everything" on the Reminder's notification | Pass: the Reminder cleared |
| Remove background location | Pass: "Protection is off" within 75 s, no crash |
| Crash log over all runs | No LeaveCheck crashes |

Simulated location bypasses Google's fused location, so this doesn't show how soon a real phone notices leaving. Earlier attempts in this run were discarded: the first had a false match in my check, and later ones sent no locations because mock location wasn't allowed. A further Reminder came from a jump of hundreds of kilometres between simulated positions, so it isn't counted. Adding the test provider again caused a temporary "Protection is off", as in S15.

### Acceptance criteria added since the earlier run

| AC | Covered by | Status |
|---|---|---|
| 10.1, 10.2, 12.5 | `test/domain/detection_settings_test.dart`, `test/service/watcher_test.dart`, `test/ui/stay_setting_screen_test.dart` | Logic; phone open |
| 11.2, 11.3, 11.5, 11.8 | `test/domain/reminder_place_test.dart`, `test/fixtures/synthetic_place_*.jsonl` | Logic; FT-6 open |
| 11.1, 11.4, 11.6, 11.7 | `test/ui/reminder_places_screen_test.dart`, `test/ui/quiet_places_screen_test.dart`, `test/service/watcher_test.dart` | Logic; FT-6 open |
| 12.1 to 12.4, 12.6 | `test/ui/advanced_settings_screen_test.dart` | Logic |
| 13.1 to 13.4 | `test/ui/language_screen_test.dart`, `test/l10n/text_test.dart`, `test/domain/language_test.dart`, `test/service/protection_monitor_test.dart` | Logic; S16 emulator check |
| 13.5 | manual; sheet in `docs/store/native-speaker-check.md` | **Open** |
| 14.1 to 14.3 | `probes/steps/test/steps_log_test.dart`; main app has no step code | **14.1 open:** no real walks |
| 15.1 | manual: `fastlane/metadata/android/`, `assets/brand/`, owner's reported trademark search | Prepared; shape of the logo to confirm on a real phone |
| 15.2, 15.3 | manual: listing text read against the criteria | Pass for now; recheck after FT-2 |
| 15.4 | manual | **Open:** nothing submitted |

Coverage for 11 to 13 was mapped by test file and test name; each test's assertions weren't re-read in this run. The earlier AC table still applies to the older criteria, except that the 7.x setup text changed.

### What blocks release

1. **No real-phone results:** the S15 Walk test and FT-1 to FT-6. FT-2 decides whether Ride stays in v1. The earlier gaps 0 to 3 stay open for real phones; on the emulator, gap 0's silent failure is handled by the S15 fallback.
2. **Native-speaker check (AC-13.5)** not done.
3. **Play:** real upload key, published privacy policy, screenshots, the declaration with its video, and the Data safety form. Rejection of background location is the main product risk.

### Audit against the Engineering rules

| Rule | Result |
|---|---|
| Detection separate from Flutter and plugins | Pass: `test/architecture_test.dart`; no plugin imports in `lib/domain` or `lib/ports` |
| Plugins only through thin wrappers | Pass, with the same accepted exceptions: `lib/main.dart` and `lib/service/entry_point.dart` use `flutter_foreground_task` |
| Location stays on the phone | Pass: no `INTERNET` in the release APK and no network code in `lib` |

### Findings

| Finding | Recommendation |
|---|---|
| `README.md:3` said the app is Russian only and omitted newer features | Fixed |
| `docs/requirements.md:55` (AC-4.3) said the default is in Russian, which conflicted with AC-13.4 | Fixed |
| `ic_notification` not looked at in the status bar, and the service notification still uses the app icon | Check during FT-6; fix if it looks wrong |
| The warning box is repeated in six places, and `_quietly` in four files | Defer until after the field tests, as before |
| Release builds without `key.properties` use the debug key without warning | Ignore: Play rejects them |
| `docs/requirements.md` AC-5.3: showing a Ride's advice on screen has no test | Defer to FT-2 |

## Earlier run

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
- **Unbroken Walk checks (added 2026-11-02, no real data):** slow and walker walks, pause comparison, and false walks in daily life. Pass rule in `probes/steps/README.md`.
- **Real-walk results (2026-11-02, one tester on one phone, no elderly walks or daily life; logs in `probes/steps/data/`):** 10 walks, 4 sits, no vehicle rides. Steps: seen on 10 of 10 walks, median delay 0 s, false signals in 0 of 4 sits. Activity Recognition: 10 of 10, median 5 s, 0 of 4. Pedestrian: 3 of 10, median 81 s, 0 of 4. Motion: 10 of 10, median 1 s, 2 of 4. All 10 walks reached 40 unbroken steps at pauses up to 2, 3 and 5 s.
- **Verdict from the report:** Steps experiment: **drop**, because steps lead Activity Recognition by only 5 s, not the required 15 s. Unbroken Walk: **not enough data**. So AC-14.2 applies: no steps in the release.


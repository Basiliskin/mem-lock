# Geo Alert: QA Report

Run 2026-10-31 on commit 5aea7ff. Verdict: **not ready for release.** See "Blocking gaps".

## Results

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 203 passed, 0 failed |
| Clean clone: `flutter pub get`, `flutter test`, `flutter build apk --release` | All passed; APK built |
| Release APK permissions | No `INTERNET` permission (supports AC-5.6) |
| App smoke test, abuse cases | **Not run:** no phone or emulator was connected |
| FT-1 to FT-5 | **Not run:** no results are recorded anywhere |

## Acceptance criteria

"Logic" means automated tests cover the logic with fakes, not the real phone.

| AC | Covered by | Status |
|---|---|---|
| 1.1, 1.2, 1.4, 1.5 | `test/domain/detector_test.dart`, `test/domain/replay_test.dart` | Logic; FT-1, FT-3 open |
| 1.3 | `detector_test.dart`, `test/service/watcher_test.dart` | Logic |
| 2.1, 2.2, 2.3 | `test/domain/ride_test.dart`, `test/domain/ride_replay_test.dart` (synthetic rides) | Logic only; **not connected to the phone's activity signal**; real rides and FT-2 open |
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
| 7.5 | `test/widget_test.dart` (Helper entry group) | Logic |
| 8.1 | manual; `autoRunOnBoot` is set in `lib/adapters/foreground_host.dart:25` | **Open** |
| 8.2, 8.3 | `widget_test.dart`, `test/service/protection_monitor_test.dart` | Logic; phone open |
| 8.4 | `widget_test.dart` | Logic; persistent notification open |
| 9.1 | `test/domain/location_mode_test.dart` | Logic; FT-4 open |
| 9.2 | `test/service/battery_monitor_test.dart`, `widget_test.dart` | Logic; phone open |
| 10.1, 10.2 | `s12_test.dart`, `watcher_test.dart`, `test/ui/stay_setting_screen_test.dart` | Logic; phone open |

## Blocking gaps

1. **Ride detection doesn't run in the app.** The Detector has the Ride rules (S4, logic only, synthetic rides), but there is no `ActivitySource` adapter, so `ActivityChanged` is never sent. No slice lists this work. No S1 ride logs or FT-2 result exist, so the rule for dropping Ride from v1 has not been triggered.
2. **Setup blocks on a permission nothing uses yet.** The activity permission (`lib/ui/setup_screen.dart:65`) is kept for S4. The claim about noticing a train or bus exit has been removed from the setup text.
3. **No field or phone results.** FT-1 to FT-5 and the S1 and S2 gates have no recorded results.

## Audit against the Engineering rules

| Rule | Result |
|---|---|
| Detection separate from Flutter and plugins | Pass: `test/architecture_test.dart` enforces it for `lib/domain` |
| Plugins only through thin wrappers | Pass, with two exceptions: `lib/service/entry_point.dart:4` and `lib/main.dart:2` use `flutter_foreground_task` directly. Both are start-up wiring |
| Location stays on the phone | Pass: no `INTERNET` permission in the release APK; the only exit is the `geo:` link in `lib/adapters/url_map_launcher.dart` |

Smaller findings:

- **Duplication:** the warning colour and note box are repeated in five screens, for example `lib/ui/main_screen.dart:286` and `lib/ui/forgot_screen.dart:99`. `_quietly` is repeated in `lib/service/watcher.dart`, `lib/service/protection_monitor.dart`, `lib/service/reminder_session.dart` and `lib/ui/reminder_options_screen.dart`.
- **Stale test name:** fixed in `test/service/watcher_test.dart`.
- **Dead code:** no unused classes found. This was a name search only.

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

No runs recorded yet.

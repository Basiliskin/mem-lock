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

## 2026-10-31 · /qa

- **Release signing:** fix just before the first Play upload, using the owner's own key. Deferred.
- **Repeated warning box and `_quietly`:** defer until after the field tests.
- **Other small findings:** ignored: the two start-up plugin imports, unused iOS code in the vendored plugin, no direct test for `lib/adapters/phone_health.dart`, and the notification warning delay of up to 60 s. Files: `docs/qa-report.md`.

## 2026-11-01 · /developer gap 0

- **Location stream failure (D4 option a):** the Watcher retries every 60 s and saves the failure to prefs, so the notification and main screen warn. No fallback to `LocationManager` yet, so the failing settings check itself remains. Files: `lib/service/watcher.dart`, `lib/service/entry_point.dart`, `lib/adapters/phone_health.dart`, `lib/ports/ports.dart`, `lib/ui/main_screen.dart`, `lib/l10n/strings.dart`, `test/service/watcher_test.dart`.

## 2026-11-01 · /grill-with-docs

- **First release scope widened:** publishing waits until custom location alerts, speed and stop modes, more languages, name, logo and description are all done. This replaces the "Russian only" and "other languages: Won't" scope once `docs/requirements.md` is updated.
- **Custom location alerts:** leaving a chosen place always gives a Reminder, even after a short visit, with that place's own message.
- **Step tracking:** explore the phone's step and motion sensors as a sign that walking has started, as an experiment until tested on a real phone. No step history.
- **Reminder Place:** the name for a custom location. A place can't be both a Reminder Place and a Quiet Place; the app asks which to keep.
- **Advanced values:** the Helper can set actual speed and time values in an advanced mode. Limits and exact fields still to be decided.
- **Advanced settings:** Stay time 1-30 min, Stay area 30-300 m, vehicle speed 7-30 km/h, walking time after a Ride 10-120 s, as starting limits to retune after field tests. Ride time limit stays fixed. Reset to recommended, and a warning on risky values such as a Stay time over 15 min.
- **Languages:** Russian and English first; Hebrew still to be confirmed. Follows the phone's language, and the Helper can change it. A native speaker checks Reminder and warning wording.
- **Name:** LeaveCheck replaces Geo Alert, subject to a trademark search. A web search found no app with that exact name, but didn't cover trademark registries.
- **Hebrew:** left out of the first release, unless specific Hebrew-speaking families are already lined up.
- **Publishing:** free at launch; closed test starts once field tests pass. Countries and Play account still to be decided.
- **Store title and listing:** LeaveCheck plus a translated tagline, such as "LeaveCheck: ничего не забудь". Logo: a bag with a checkmark, high contrast. Description addresses the adult child, states the limits, and mentions train and bus Reminders only if FT-2 passes.
- **Countries and account:** all countries, on the owner's existing Play account.
- **Reminder Place setup:** the Helper presses a button while at the place and gives a name and message. No address search, so the app stays without internet.
- **Reminder Place trigger:** at least 1 minute inside the area (75 m by default), then a Reminder once the Wearer has clearly left. Fixed, tuned in field tests.

## 2026-11-01 · /product

- **Requirements updated:** added US-11 to US-15 and FT-6, and renamed the app LeaveCheck. Defaults set: other phone languages use English; picking More often, Normal or Less often replaces advanced Stay values; a Stay ending at a Reminder Place gives one Reminder with that place's message. Files: `docs/requirements.md`, `GLOSSARY.md`, `.claude/project-profile.md`.

## 2026-11-01 · /architect

- **Reminder Places in the Detector; Flutter translation files; app ID `com.leavecheck.app` after the trademark search.** Slices S15 to S22 added, with the real-phone Walk test as a gate first. Files: `docs/architecture.md`, `docs/adr/0001-reminder-places-in-detector.md`.

## 2026-11-01 · /designer

- **Variant A for the new screens:** separate screens with typed values and − and + buttons. Files: `docs/design.md`, `prototypes/release-variant-a.html`, `prototypes/release-variant-b.html`.

## 2026-11-01 · /developer S15

- **`LocationManager` fallback built before the real Walk test,** because the owner can't do a real walk soon. Each service start tries fused location first and moves to `LocationManager` only when it reports location as disabled. S15 stays open until a real walk gives a Reminder. Files: `lib/adapters/geolocator_location.dart`, `test/adapters/geolocator_location_test.dart`, `docs/qa-report.md`.

## 2026-11-01 · /developer S16

- **Translation files with the language read at each use.** `app_ru.arb` and `app_en.arb` replace `lib/l10n/strings.dart`. The service looks up the saved language each time it shows text. The first phone language alone decides when nothing is chosen. English text is a draft until the AC-13.5 check. Times stay 24-hour in both languages. Files: `lib/l10n/`, `lib/domain/language.dart`, `lib/adapters/prefs_language.dart`, `lib/ui/language_screen.dart`, `lib/ui/localized_app.dart`, the screens and adapters that show text, and their tests.

## 2026-11-01 · /developer S18, S19

- **Advanced settings and Reminder Places committed together,** at the owner's request, so S20 has its own commit. Files: `lib/ui/advanced_settings_screen.dart`, `lib/ui/reminder_places_screen.dart`, `lib/domain/detector.dart`, `lib/adapters/prefs_reminder_places.dart` and their tests.

## 2026-11-01 · /developer S20

- **Trademark search passed.** The owner searched WIPO, TMview, USPTO and FIPS and reported no matches in classes 9 and 42. This is the owner's reported result, not a legal clearance opinion.
- **Renamed to LeaveCheck; app ID and namespace are `com.leavecheck.app`; Dart package is `leavecheck`.** Installs under the old ID are a separate app, so test phones need setup again. `probes/` keep their IDs because they don't ship.
- **Logo:** a white tote bag with a checkmark on the `primary` blue, as an adaptive icon. Notifications use a separate one-colour icon. Files: `pubspec.yaml`, `android/app/`, `assets/brand/`, `lib/l10n/`, `lib/adapters/reminder_actions.dart`, imports across `lib/` and `test/`, `README.md`, `.claude/`, `docs/architecture.md`.

## 2026-11-01 · /developer S21

- **Step probe measures against Activity Recognition, with a fixed rule for "clear benefit".** A sensor is kept only if it is seen on at least 90% of walks, is at least 15 s sooner at the median, and gives no more false signals. These thresholds are the developer's default, set before any data, and the owner can change them. The probe logs that a step happened, never a count, and no places. Files: `probes/steps/`, `docs/qa-report.md`.

## 2026-11-01 · /developer S22

- **Listing leaves out trains and buses,** because FT-2 hasn't passed (AC-15.3). Tagline is "check your things" / "проверь вещи", not the earlier "ничего не забудь" example, which comes close to the claim AC-15.2 forbids.
- **Setup's location text is now a real disclosure,** naming location, its features and use when the app is closed.
- **Release signing reads `android/key.properties`;** without it, release builds use the debug key, which Play rejects. The owner creates and keeps the upload key.
- Files: `android/app/build.gradle.kts`, `fastlane/metadata/android/`, `docs/store/`, `lib/l10n/`, `test/l10n/text_test.dart`.

## 2026-11-01 · /qa

- **Fixed the README's language and feature text, and AC-4.3's conflict with AC-13.4.** The other findings keep the recommendations in the report. Files: `README.md`, `docs/requirements.md`, `docs/qa-report.md`.

## 2026-11-02 · Unbroken Walk idea, probe extended

- **Idea, not yet built:** an Unbroken Walk ends a Stay sooner. Direction is dropped, because phones can't measure walking direction reliably. The limit starts at 30 steps and drops 1 a minute to 12. With normal GPS it wakes location, and a good reading past half the Stay area confirms. With weak GPS, 40 steps start the Reminder alone. Today's rule stays as the backup. It covers Stays and Reminder Places, not Rides. All numbers are starting guesses.
- **Nothing goes into the main app until the probe passes.** Pass rule: 90% of normal and of at least 3 elderly walks reach 40 unbroken steps, and at most 1 false walk per 16 waking hours, over at least 8 hours of daily life. The 8 and 16 hours are the developer's default.
- **The probe now logs steps since the previous signal, replacing the earlier "never a count".** Sensors may deliver steps in batches, so walks can't be measured without it. It never logs the running total, and the main app's count stays in memory only (AC-14.3).
- Files: `probes/steps/`, `GLOSSARY.md`, `docs/qa-report.md`.
- **The probe now guides the tester:** checklist, next activity, timing and progress kept between sessions. Logging runs only during an activity, and an activity stopped before its minimum is discarded. Log lines are now written one at a time, because a write during an unfinished flush can throw an error.

## 2026-11-02 · Leaving home

- **Steps are dropped (AC-14.2), and leaving home becomes the indoor case.** Home can be a Reminder Place with a message such as "Gas off? Door locked?", or a Quiet Place, as the family chooses.
- **Goal:** a Reminder within about 30 m of the door. No leaving signal can come before the door closes.
- **Home Wi-Fi dropping is the proposed signal, tested first.** The probe logs only whether Wi-Fi is connected. Pass rule in `probes/steps/README.md`; the 50 steps, 30 s and 90% are the developer's default. Nothing goes into the main app until it passes.
- **Activity Recognition's walking signal now wakes precise location outside Rides (AC-1.6).** A good reading past half the area confirms leaving, so Reminders can come sooner, for Stays and Reminder Places. The 2-minute signal life and 25 m accuracy are starting values. The 2-reading rule at the full area stays as the backup. Files: `lib/domain/detector.dart`, `lib/domain/detector_json.dart`.

## 2026-11-03 · Home Wi-Fi only, behind a flag

- **Wi-Fi fingerprints of rooms are dropped.** The Wi-Fi probe (`probes/wifi/`) recognised 4 of 9 marked spots even with scan throttling off. Scans were partial, strong networks dropped out, and one room varied by 10–16 dB. With the screen off, Android scans about once per 30 minutes.
- **The Helper chose to build the home Wi-Fi Reminder now, before the Leaving home probe passes.** It replaces the earlier "nothing goes in until it passes".
- **Rule:** connected to the home Wi-Fi for at least 1 minute, then it is lost. Walking from 30 s before to 2 min after the loss gives the Reminder. Without walking, an accurate reading (25 m or better) more than 75 m from home gives it. Location is precise for 10 minutes after the loss, then low power. One Reminder per departure; reconnecting stops repeats and arms it again. A router restart with nobody walking gives none. All numbers are starting values.
- **A name that can't be read while still on Wi-Fi is ignored**, so it can't look like leaving.
- **`HOME_WIFI_ONLY` (in `.env`, default true) switches off Stays, Rides, Quiet Places and Reminder Places.** Their code and tests stay; only their service and settings links are off.
- Files: `lib/domain/home_wifi.dart`, `lib/service/home_watcher.dart`, `lib/adapters/phone_wifi.dart`, `lib/ui/home_wifi_screen.dart`, `lib/features.dart`, `.env`.

## 2026-11-03 · Home Wi-Fi screens

- **Chosen from `prototypes/home-wifi-prototype.html`:** design A for the main screen (one big status), R2 for the check (one item at a time, "Yes" or "No, go back"), and F1 for family settings (a short list, each row its own page).
- **New: the Helper chooses what to check.** Keys, wallet, phone, gas off and door locked are on by default; glasses is off; the Helper can add their own. Tapping the Reminder opens the check. "Yes" to the last item, or "Skip all", stops the Reminder; "No, go back" stops it and shows home on the map.
- **Family settings opens with one tap on "👪 Settings for family".** The 2-second hold was replaced in both modes, because the Helper could not find how to open it.
- In home Wi-Fi mode the family list replaces the old settings screen; with `HOME_WIFI_ONLY=false` the old screen is used. The main screen's new look applies in both modes.
- Files: `lib/domain/check_items.dart`, `lib/ui/check_screen.dart`, `lib/ui/check_items_screen.dart`, `lib/ui/family_settings_screen.dart`, `lib/ui/main_screen.dart`.

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

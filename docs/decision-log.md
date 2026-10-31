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

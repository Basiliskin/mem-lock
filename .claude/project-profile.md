# Project Profile

The single source of project facts for this repo's role skills. Edit here; skills read it at run time. Use `unknown` for gaps and never invent a value.

## Product
- Summary: A phone app that helps elderly people avoid losing their belongings by reminding them to check they have everything when they leave a place or get off a vehicle.
- Users: Wearers (elderly people who receive Reminders) and Helpers (family members who set up the app).
- Name: LeaveCheck (replaces Geo Alert; owner's trademark search on 2026-11-01 found no matches)
- Deliverable: A working Android v1, in Russian and English, free, in all countries, on the owner's existing Play account.
- Out of scope: "Won't (v1)" in docs/requirements.md, which replaces docs/idea.md section 2 where they differ.
- Time budget: None

## Sources
- Brief: docs/idea.md
- Glossary: GLOSSARY.md
- ADR folder: docs/adr
- Decision log: docs/decision-log.md

## Stack
- Languages and frameworks: Flutter, Dart ≥ 3.3
- Layout: Planned in docs/architecture.md (lib/domain, ports, adapters, service, ui, l10n; probes/)- Has UI: yes

## Commands
- Install: flutter pub get
- Run: flutter run
- Test: flutter test
- Lint: flutter analyze
- Typecheck: flutter analyze

## Engineering rules
<!-- Fixed architecture rules, as a checkable list. -->
- Stay and Ride detection stays separate from Flutter and plugins, and can be tested with recorded movement data.
- Plugins are reached only through thin wrappers.
- Location data never leaves the phone except when the Wearer opens directions.

## Settled decisions
<!-- Do not re-ask these. -->
- The app is always watching, with no manual mode or start button.
- A Reminder is triggered by the end of a Stay or Ride, except at a Quiet Place, or by leaving a Reminder Place after at least 1 minute.
- A place can't be both a Quiet Place and a Reminder Place. Reminder Places are marked by pressing a button on the spot, with no address search or internet.
- Advanced settings expose real values within limits; the Ride time limit stays fixed.
- Steps are an experiment only, with no step history.
- The Helper customizes Reminders and settings, which are protected from accidental changes.
- A Reminder repeats about 3 times until tapped; there is no "back in the zone" alert.
- "I forgot something" shows the Last Place; only the most recent one or two are kept.
- Phone in a forgotten bag is a stated v1 limit; a Bluetooth tag or smartwatch comes later.
- The Last Place opens in the phone's map app; there is no map inside the app.
- Recorded voice is in v1 unless it cannot play reliably on a locked phone; Ride detection leaves v1 if the train field test fails.
- Watching runs as Dart in an Android foreground service; native Kotlin is the fallback.
- On silent, the Helper chooses "play aloud" (default) or "vibrate only".
- Ride detection uses Activity Recognition first, with GPS speed as a check.
- Android first, Russian and English, following the phone's language, with a choice in settings.
- Location wakes on movement, with a low battery warning.

## Marketing
- Audience: Russian-speaking adult children of elderly parents.
- Goal: First 100 installs, kept beyond the first month.
- Production URL: unknown
- Open source: no
- Channels: Google Play, Telegram, family and senior-care communities.

## Interview
- Context: Not included
- Key files: Not included

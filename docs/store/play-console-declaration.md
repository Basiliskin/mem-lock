# Play Console submission notes

Prepared text for the owner to submit. Nothing here has been submitted. Check the live forms and `docs/play-policy-check.md` first, because forms and rules change.

## Background location declaration (AC-15.4)

**Feature:** Reminders to check belongings when leaving a place.

**Why background access is needed:** the person carrying the phone is elderly and doesn't open the app. The Reminder has to come at the moment they walk away from a place, with the phone locked in a pocket. That moment can only be noticed by reading location while the app is in the background.

**Benefit:** helps elderly people, including those with memory difficulties, avoid losing their belongings. Do not describe it as a safety app.

**Video to record (real phone):** setup, the location disclosure, the "Allow all the time" permission, a Stay, walking away with the phone locked, and the Reminder.

**Known risk:** Google may judge this as convenience. See the fallback in `docs/play-policy-check.md`; that decision is the owner's.

## Data safety form (draft)

| Data | Collected or shared | Note |
|---|---|---|
| Precise and approximate location | Not collected or shared | Stays on the phone |
| Voice recordings | Not collected or shared | Stays on the phone |
| Physical activity | Not collected or shared | Processed on the phone |

Confirm that no plugin sends data before submitting. Opening directions passes the destination to the map app at the person's request.

## Other Console items

- Price free, all countries, on the owner's existing account.
- Foreground service declaration: location.
- Target audience: adults. Content rating questionnaire.

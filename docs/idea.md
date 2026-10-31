# Geo Alert: Product Spec

Version 2.0 · Flutter · Android first

"Geo Alert" is a working name. Terms in bold capitals, such as Stay and Reminder, are defined in `GLOSSARY.md`.

## 1. Overview

Geo Alert helps elderly people avoid losing their belongings. It reminds the Wearer to check they have everything when they leave a place or get off a vehicle, such as a cafe, a park bench or a train. Once a Helper has set it up, the Wearer never needs to press anything to start it.

## 2. Goals and non-goals

### Goals

- Detect the end of a Stay or Ride without any action from the Wearer.
- Deliver a Reminder that is hard to miss and can be customized.
- Help the Wearer go back or report a loss through the Last Place.
- Warn clearly when the app cannot watch.
- Keep battery use low enough to last a normal day on an older phone.

### Non-goals (v1)

- Manual saving of a location, or a manual mode.
- Bluetooth tags or smartwatches.
- A server, accounts, or alerts sent to the Helper's phone.
- Location history beyond the Last Place.
- Choosing places on a map or by typing an address.
- "Back in the zone" alerts.
- iPhone support and languages other than Russian.

## 3. User scenarios

1. **Setup:** a Helper installs the app on the Wearer's phone, grants permissions, chooses the Reminder settings, and marks the Wearer's home as a Quiet Place while standing there.
2. **Cafe:** the Wearer sits in a cafe for 20 minutes, then walks out. A Reminder plays: "Do you have your bag?" They tap "I have everything".
3. **Train:** the Wearer rides for 40 minutes, gets off and starts walking. A Reminder plays.
4. **Something forgotten:** the Wearer taps "I forgot something". The app shows the Last Place on a map, with directions and the time they were there.
5. **Quiet Place:** the Wearer leaves home. No Reminder plays.
6. **App cannot watch:** someone turns off location. The phone shows "Geo Alert is not protecting you, tap to fix".

## 4. Functional requirements

### Detection

| ID | Requirement |
|---|---|
| FR-1 | Watching starts when setup is complete and has no start or stop button for the Wearer. |
| FR-2 | A Stay begins when the Wearer remains within the Stay area for the Stay time. |
| FR-3 | A Stay ends when the Wearer moves out of the Stay area, which triggers a Reminder unless the Stay is at a Quiet Place. |
| FR-4 | The Stay setting offers "More often", "Normal" and "Less often". Normal starts at 5 minutes and 75 m; all values are to be tuned by testing. |
| FR-5 | A Ride is recognized from the motion sensors. A Ride ends when the Wearer starts walking, which triggers a Reminder. |
| FR-6 | Ending a Stay or Ride replaces the Last Place with the new one. A new Stay begins only under FR-2. |

### Reminder

| ID | Requirement |
|---|---|
| FR-7 | The Helper can customize the sound, vibration, text, spoken or recorded voice message, and number of repeats. |
| FR-8 | A Reminder repeats about every 30 seconds, up to 3 tries by default. |
| FR-9 | A Reminder offers two actions: "I have everything" and "I forgot something". |
| FR-10 | Repeats stop when the Wearer taps an action, the tries run out, or the Wearer returns to the place the Stay ended. |

### Last Place

| ID | Requirement |
|---|---|
| FR-11 | "I forgot something" shows the time of the Last Place and a button that opens it in the phone's map app. |
| FR-12 | Only the most recent one or two Last Places are kept, on the phone only. |
| FR-13 | After a Ride, the Last Place is where the Wearer got off, and the time is shown clearly for use with lost property offices. |

### Helper settings and Quiet Places

| ID | Requirement |
|---|---|
| FR-14 | The Helper marks a Quiet Place by pressing a button while standing there. More than one is allowed. |
| FR-15 | Settings sit behind a long press or simple code, so the Wearer cannot change them by accident. |
| FR-16 | Setup tells the Helper that the phone must be kept on the Wearer's body, not in a bag, and suggests a neck or belt pouch. |

### Reliability warnings

| ID | Requirement |
|---|---|
| FR-17 | Watching resumes by itself after a phone restart. |
| FR-18 | When location is off, permission is missing, or watching has stopped, the phone shows a clear warning with a way to fix it, wherever the app is able to show one. |
| FR-19 | The app warns the Wearer when the battery is low. |

## 5. Main screen

The Wearer's screen is a single view with large text:

- Current status, such as "Protecting you" or "Not protecting you, tap to fix".
- The Last Place and its time, when there is one.
- A hidden way into the Helper settings.

The Helper's settings cover Reminder options, the Stay setting, Quiet Places, and the setup advice.

## 6. Permissions and platform setup

- Setup guides the Helper through location ("Allow all the time"), notifications, physical activity, and turning off battery optimisation, which matters most on aggressive brands such as Xiaomi, Samsung and Huawei.
- Permission refused: explain why it is needed. Refused permanently: open system settings.
- Android manifest: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `ACTIVITY_RECOGNITION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`.
- minSdk 21, compileSdk 35, core library desugaring enabled. Re-check these against current Google Play requirements before release.

## 7. Background behaviour

- Watching runs as a foreground service with a persistent notification.
- Location stays mostly off and is woken by the motion sensors when the Wearer starts moving.
- Watching restarts after a phone restart.

## 8. Technical design

| Area | Choice |
|---|---|
| Framework | Flutter, Dart ≥ 3.3 |
| Location | geolocator |
| Motion detection | Activity recognition plugin, to be chosen |
| Notifications | flutter_local_notifications, maximum importance |
| Storage | shared_preferences: settings, Quiet Places, Last Place |
| Text | Stored so it can be translated later |

Package versions are to be confirmed when the project is created. The app has no backend. The app has no map of its own; the Last Place opens in the phone's map app.

## 9. Non-functional requirements

- **Battery:** lasts a normal day on an older phone. To be measured.
- **Accuracy:** on walking away, the Reminder plays within about 100 m of the Stay area under open sky. To be confirmed by testing.
- **Privacy:** location stays on the phone and goes to no server of ours. Opening directions shares the destination with the map app.
- **Accessibility:** large text, high contrast, and simple wording.
- **Language:** Russian in v1.

## 10. Known limits and risks

- **Phone in the forgotten bag:** the app cannot detect this, because the phone does not move. Setup states this limit, and a Bluetooth tag or smartwatch is planned for later.
- **Trains:** motion detection may notice too late, after the train has left with the bag. Test on real journeys early. If it is too slow, drop train coverage from v1 and do not promise it.
- **Indoor location:** the signal can be off by 30 m or more, which may cause false Reminders.
- **Google Play:** always-on background location needs a declaration and review, so confirm the app's case early.
- **Unverified estimates:** battery savings, Reminder delay, and the choice of Android first all need checking against real phones and real users.

## 11. Acceptance criteria

- After a Stay, walking out of the area produces one Reminder, with repeats following the settings.
- Leaving a Quiet Place produces no Reminder.
- Getting off a train and walking produces a Reminder, and the delay is recorded across real journeys.
- A very short stop, below the Stay time, produces no Reminder.
- Tapping either action stops the repeats.
- "I forgot something" shows the correct Last Place and time.
- Watching resumes after a phone restart with no action needed.
- Turning off location or removing permission produces the warning, and never a crash.
- A day of normal use on an older phone does not run the battery flat.

## 12. Future ideas

- Bluetooth tag or smartwatch, to cover the phone-in-bag case.
- iPhone support. A swiped-away iPhone app cannot warn about itself, so setup must explain this to the Helper.
- Alerts to the Helper's phone.
- A home-leaving check, such as "Got your keys?".
- English and other languages.

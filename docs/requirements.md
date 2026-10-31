# Geo Alert: Requirements

The single source of truth for what gets built in v1. It is based on `docs/idea.md` and uses the terms in `GLOSSARY.md`.

Field test numbers are targets set before any testing, not measured results.

## Scope

| Priority | Items |
|---|---|
| **Must** | Stay and Ride detection; Reminders with repeats and two actions; customizable sound, vibration, text and recorded voice; Last Place; Quiet Places; guided setup with protected settings and phone-on-body advice; restart after reboot; "not protecting you" warnings; wake-on-movement location; Russian text |
| **Should** | Low battery warning; More often / Normal / Less often setting; keeping two Last Places instead of one |
| **Could** | Adjustable number of repeats; spoken message read out from the Reminder text |
| **Won't (v1)** | iPhone; Bluetooth tags and smartwatches; alerts to the Helper's phone; a server or accounts; a manual mode; a map inside the app; location history beyond the Last Place; "back in the zone" alerts; other languages |

Two Must items depend on field results:

- **Train coverage:** if FT-2 fails, Ride detection is dropped from v1 and the app makes no claim about trains.
- **Recorded voice:** if it cannot play reliably on a locked phone, it moves to the first update.

Until "Should" and "Could" settings are built, the app uses the defaults: Normal Stay setting, 3 tries, and one Last Place.

## User stories and acceptance criteria

### US-1: Reminder after a Stay (Must)
As a Wearer, I want a Reminder when I leave a place where I stayed, so that I don't leave my belongings behind.

- **AC-1.1** Given the Wearer has remained in the Stay area for the Stay time, when they move out of it, then one Reminder starts.
- **AC-1.2** Given the Wearer stopped for less than the Stay time, when they move on, then no Reminder starts.
- **AC-1.3** Given a Stay is at a Quiet Place, when the Wearer leaves, then no Reminder starts.
- **AC-1.4** Given the Wearer stays in place while the location signal drifts within the Stay area, then no Reminder starts.
- **AC-1.5** Given a Reminder has started for a Stay, when the location signal crosses the edge of the Stay area again, then no second Reminder starts for that same Stay.

### US-2: Reminder after a Ride (Must, depends on FT-2)
As a Wearer, I want a Reminder when I get off a train or bus, so that I don't leave my bag on the seat.

- **AC-2.1** Given the Wearer is on a Ride, when they get off and start walking, then one Reminder starts.
- **AC-2.2** Given the vehicle stops at a station and the Wearer stays seated, then no Reminder starts.
- **AC-2.3** Given the Wearer walks along the vehicle during a Ride, then no Reminder starts.

### US-3: A Reminder that is hard to miss (Must)
As a Wearer, I want the Reminder to repeat until I respond, so that I notice it on a noisy street.

- **AC-3.1** Given a Reminder has started and gets no response, then it repeats about every 30 seconds, up to 3 tries.
- **AC-3.2** Given a Reminder is playing, when the Wearer taps "I have everything" or "I forgot something", then the repeats stop.
- **AC-3.3** Given repeats remain after a Stay, when the Wearer returns to the place the Stay ended, then the repeats stop.
- **AC-3.4** Given the phone is locked, when a Reminder starts, then its sound, vibration and actions all work.
- **AC-3.5** Given the phone is on silent, then setup tells the Helper what the Reminder will do on silent, and the Reminder behaves that way. The exact behaviour is decided in `/architect`, based on what Android allows.

### US-4: Customized Reminders (Must)
As a Helper, I want to choose the sound, vibration, text and a recorded voice, so that the Wearer notices and recognizes the Reminder.

- **AC-4.1** Given the Helper changes a Reminder option, when the next Reminder starts, then it uses the new option.
- **AC-4.2** Given the Helper records a voice message, when a Reminder starts on a locked phone, then the message plays.
- **AC-4.3** Given no custom options are set, then a Reminder uses a working default in Russian.
- **AC-4.4** Given a chosen sound or recording cannot be played, then the Reminder still plays using the default.
- **AC-4.5** Given the Helper is choosing options, when they tap test, then they hear and feel the Reminder as it will play.

### US-5: Going back for a forgotten item (Must)
As a Wearer, I want to see where I was and when, so that I can go back or report the loss.

- **AC-5.1** Given a Reminder is playing, when the Wearer taps "I forgot something", then the app shows the time of the Last Place and a button to open it in the phone's map app.
- **AC-5.2** Given the Wearer taps that button, then the map app opens at the Last Place.
- **AC-5.3** Given a Ride ended, then the Last Place is where the Wearer got off, and the time is shown clearly.
- **AC-5.4** Given no map app is available, then the app shows a clear message and still shows the time and coordinates.
- **AC-5.5** Given a new Stay or Ride has ended, then the oldest Last Place beyond the kept limit is deleted.
- **AC-5.6** Given normal use, then no location data leaves the phone until the Wearer opens the map app.

### US-6: Quiet Places (Must)
As a Helper, I want to mark places such as home, so that the Wearer isn't reminded when leaving them.

- **AC-6.1** Given the Helper is at a place, when they press the button to mark it, then it becomes a Quiet Place.
- **AC-6.2** Given several Quiet Places exist, when the Wearer leaves any of them, then no Reminder starts.
- **AC-6.3** Given the Helper removes a Quiet Place, when the Wearer next stays there and leaves, then a Reminder starts.
- **AC-6.4** Given no location fix is available, when the Helper presses the button, then no place is saved and a clear message says why.

### US-7: Setup and protected settings (Must)
As a Helper, I want a guided setup and protected settings, so that the app works and can't be changed by accident.

- **AC-7.1** Given a fresh install, when the Helper finishes setup, then watching has started with no further action.
- **AC-7.2** Given setup, then it guides the Helper through location ("Allow all the time"), notifications, physical activity and battery optimisation.
- **AC-7.3** Given a permission is refused, then the app explains why it is needed, and a permanent refusal leads to system settings. The app never crashes.
- **AC-7.4** Given setup, then it states that the phone must be kept on the body and that the app cannot detect a phone left in the bag.
- **AC-7.5** Given the Wearer uses the main screen normally, then no setting can be changed without the long press or code.

### US-8: Always watching, or saying so (Must)
As a Helper, I want the app to restart itself and warn when it can't watch, so that nobody relies on it while it's off.

- **AC-8.1** Given the phone restarts, when it has started up, then watching resumes with no action.
- **AC-8.2** Given location is turned off or a permission is removed, then the phone shows "Not protecting you, tap to fix".
- **AC-8.3** Given the warning is showing, when the problem is fixed, then the warning clears and the status shows "Protecting you".
- **AC-8.4** Given watching is working, then the main screen shows "Protecting you" and the phone shows the persistent notification.

### US-9: Battery (Must; low battery warning is Should)
As a Wearer, I want the app to use little battery, so that my phone lasts the day.

- **AC-9.1** Given the Wearer is in a Stay, then only low-power location runs until a reading suggests the Wearer has moved.
- **AC-9.2** (Should) Given the battery runs low, then the app warns the Wearer once per low-battery period.

### US-10: Stay setting (Should)
As a Helper, I want to choose how often Reminders happen, so that they suit the Wearer's day.

- **AC-10.1** Given the Helper picks More often, Normal or Less often, then later Stays use those values.
- **AC-10.2** Given no choice was made, then Normal applies: 5 minutes and 75 m, subject to tuning from the field tests.

## Field tests

Run on a real Android phone kept on the body, with the app minimised and the screen locked. Record every run, including failures, in `docs/qa-report.md`.

| ID | Test | Passes when | Covers |
|---|---|---|---|
| FT-1 | Walks: 10 Stays in cafes, parks and similar places, then walking away | At least 9 of 10 give a Reminder within 100 m of the Stay area | US-1, US-3 |
| FT-2 | Train journeys: 10 rides, then getting off and walking, with train type recorded | At least 8 of 10 give a Reminder within 60 seconds of starting to walk | US-2 |
| FT-3 | Short stops: 5 stops shorter than the Stay time | No Reminder | AC-1.2 |
| FT-4 | Full days: 3 days of normal use on an older phone | No more than 2 needless Reminders a day on average, and the phone lasts 16 hours | US-1, US-9 |
| FT-5 | Locked phone: 5 Reminders with a recorded voice on a locked phone | All 5 play the recording | AC-4.2 |

Results by train type must be reported separately. A pass on FT-2 does not mean a bag can be saved on a metro, where doors may close within seconds, and the app must not claim that it can.

"Older phone" is still to be chosen, and the same model must be used for all FT-4 days.

## Out of scope

See "Won't (v1)" above. The app cannot detect a phone left inside the forgotten bag. This is a stated limit of v1.

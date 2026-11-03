# LeaveCheck

A phone app that helps elderly people avoid losing their belongings by reminding them to check they have everything when they leave a place or get off a vehicle.

## Language

**Wearer**:
The elderly person whose phone runs the app and who receives Reminders.
_Avoid_: User, patient, owner

**Helper**:
The family member who sets up and adjusts the app for the Wearer.
_Avoid_: Admin, caregiver, guardian

**Stay**:
A period in which the person remained in one area long enough for belongings to have been put down.
_Avoid_: Anchor, zone, geofence

**Ride**:
A period in which the person travelled in a vehicle such as a train or bus.
_Avoid_: Trip, journey

**Unbroken Walk**:
Walking without a long pause, which suggests the Wearer may be leaving a Stay. Short bursts of walking don't add up to one.
_Avoid_: Steps in one direction, walk-off

**Home Wi-Fi**:
The Wi-Fi network the Helper marks at the Wearer's home. Losing it while walking out gives a Reminder.
_Avoid_: SSID, router, access point

**Quiet Place**:
A place chosen by the Helper, such as the Wearer's home, that never produces a Reminder when the Wearer leaves it.
_Avoid_: Home, safe zone, excluded zone

**Reminder Place**:
A place chosen by the Helper such as the Wearer's home, that always produces a Reminder when the Wearer leaves it, even after a short visit, with that place's own message. A place cannot be both a Reminder Place and a Quiet Place.
_Avoid_: Alert, custom location, geofence

**Last Place**:
Where and when a recent Stay or Ride ended, kept so the Wearer can go back or report a loss. The two most recent are kept.
_Avoid_: History, track, log

**Reminder**:
The prompt telling the person to check their belongings after a Stay or Ride ends, or after they leave a Reminder Place.
_Avoid_: Alert, notification, alarm

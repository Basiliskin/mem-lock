import 'detection_settings.dart';
import 'geo.dart';

export 'detection_settings.dart';

/// Readings less accurate than this are too unreliable to act on.
const maxAccuracyMeters = 50.0;

/// Readings in a row outside the area needed to end a Stay, so that one bad
/// jump in the signal can't trigger a Reminder.
const outsideReadingsToLeave = 2;

/// How close a Stay must be to a Quiet Place to count as being at it.
const quietPlaceMeters = 100.0;

// Ride thresholds are placeholders, set without real rides. Retune them from
// the S1 logs before trusting them.

/// A vehicle signal must be this sure to start a Ride, because starting one
/// can end a Stay.
const rideStartConfidence = 75;

/// Other activity signals below this are ignored. Same as the S1 probe.
const activityMinConfidence = 50;

/// With no sign of a vehicle for this long, the end of the Ride was missed.
/// Without it, Stay detection would never resume.
const rideTimeLimit = Duration(minutes: 15);

class QuietPlace {
  const QuietPlace(this.id, this.point);

  final String id;
  final GeoPoint point;
}

class LastPlace {
  const LastPlace(this.point, this.time);

  final GeoPoint point;
  final DateTime time;
}

// Events --------------------------------------------------------------------

sealed class DetectorEvent {
  const DetectorEvent(this.time);

  final DateTime time;
}

class LocationFix extends DetectorEvent {
  const LocationFix(super.time, this.point, this.accuracyMeters);

  final GeoPoint point;
  final double accuracyMeters;
}

/// Time passing with no other signal.
class Tick extends DetectorEvent {
  const Tick(super.time);
}

enum ActivityKind { still, walking, inVehicle, unknown }

class ActivityChanged extends DetectorEvent {
  const ActivityChanged(super.time, this.kind, this.confidence);

  final ActivityKind kind;
  final int confidence;
}

class QuietPlacesChanged extends DetectorEvent {
  const QuietPlacesChanged(super.time, this.places);

  final List<QuietPlace> places;
}

class SettingsChanged extends DetectorEvent {
  const SettingsChanged(super.time, this.settings);

  final DetectionSettings settings;
}

// Decisions -----------------------------------------------------------------

enum ReminderSource { stay, ride }

enum LocationMode { precise, lowPower }

sealed class Decision {
  const Decision();
}

class StartReminder extends Decision {
  const StartReminder(this.source, this.lastPlace);

  final ReminderSource source;
  final LastPlace lastPlace;
}

/// The Wearer came back to where the Stay ended.
class StopRepeats extends Decision {
  const StopRepeats();
}

/// Rest location during a Stay, or wake it when a reading looks outside.
class SetLocationMode extends Decision {
  const SetLocationMode(this.mode);

  final LocationMode mode;
}

// State ---------------------------------------------------------------------

sealed class Phase {
  const Phase();
}

/// Moving or not yet settled. [anchor] is where the Stay clock started.
class Roaming extends Phase {
  const Roaming({this.anchor, this.since});

  final GeoPoint? anchor;
  final DateTime? since;
}

class InStay extends Phase {
  const InStay(this.center, this.meters, {this.outsideReadings = 0});

  final GeoPoint center;

  /// The distance chosen when this Stay began. A changed setting applies only
  /// to later Stays, so changing it can't end this one.
  final double meters;
  final int outsideReadings;
}

class OnRide extends Phase {
  const OnRide({
    required this.movingAt,
    this.lastPoint,
    this.lastFixAt,
    this.walkingSince,
    this.gotOffPoint,
  });

  /// The last sign of being in a vehicle.
  final DateTime movingAt;

  /// The last trusted reading. It may be old, such as in a metro tunnel.
  final GeoPoint? lastPoint;
  final DateTime? lastFixAt;

  /// When unconfirmed walking began, and the best reading of where.
  final DateTime? walkingSince;
  final GeoPoint? gotOffPoint;

  OnRide stoppedWalking({DateTime? movingAt}) => OnRide(
    movingAt: movingAt ?? this.movingAt,
    lastPoint: lastPoint,
    lastFixAt: lastFixAt,
  );
}

class DetectorState {
  const DetectorState({
    required this.phase,
    required this.settings,
    required this.quietPlaces,
    this.returnTo,
    this.locationMode = LocationMode.precise,
  });

  factory DetectorState.initial() => const DetectorState(
    phase: Roaming(),
    settings: DetectionSettings.normal,
    quietPlaces: [],
  );

  final Phase phase;
  final DetectionSettings settings;
  final List<QuietPlace> quietPlaces;

  /// Where the last Reminder's Stay was, until the Wearer returns or a new
  /// Stay begins.
  final GeoPoint? returnTo;

  final LocationMode locationMode;

  DetectorState _with({Phase? phase}) => DetectorState(
    phase: phase ?? this.phase,
    settings: settings,
    quietPlaces: quietPlaces,
    returnTo: returnTo,
    locationMode: locationMode,
  );

  DetectorState _withReturnTo(GeoPoint? point) => DetectorState(
    phase: phase,
    settings: settings,
    quietPlaces: quietPlaces,
    returnTo: point,
    locationMode: locationMode,
  );
}

// Step ----------------------------------------------------------------------

/// The whole Detector: no clock, plugin or storage, so recorded movement can
/// be replayed in a test.
(DetectorState, List<Decision>) step(DetectorState state, DetectorEvent event) {
  final (next, decisions) = _core(state, event);
  final mode = _modeAfter(state, next, event);
  if (mode == state.locationMode) return (next, decisions);
  return (
    DetectorState(
      phase: next.phase,
      settings: next.settings,
      quietPlaces: next.quietPlaces,
      returnTo: next.returnTo,
      locationMode: mode,
    ),
    [...decisions, SetLocationMode(mode)],
  );
}

/// Precise unless settled in a Stay. Any reading outside wakes precise, even
/// an inaccurate one, and any reading inside rests it again.
LocationMode _modeAfter(
  DetectorState before,
  DetectorState after,
  DetectorEvent event,
) {
  final phase = after.phase;
  if (phase is! InStay) return LocationMode.precise;
  if (event is LocationFix) {
    return event.point.distanceTo(phase.center) > phase.meters
        ? LocationMode.precise
        : LocationMode.lowPower;
  }
  return before.phase is InStay ? before.locationMode : LocationMode.lowPower;
}

(DetectorState, List<Decision>) _core(
  DetectorState state,
  DetectorEvent event,
) {
  return switch (event) {
    LocationFix() => _onFix(state, event),
    Tick() => _onTick(state, event.time),
    ActivityChanged() => _onActivity(state, event),
    QuietPlacesChanged() => (
      DetectorState(
        phase: state.phase,
        settings: state.settings,
        quietPlaces: event.places,
        returnTo: state.returnTo,
        locationMode: state.locationMode,
      ),
      const [],
    ),
    SettingsChanged() => (
      DetectorState(
        phase: state.phase,
        settings: event.settings,
        quietPlaces: state.quietPlaces,
        returnTo: state.returnTo,
        locationMode: state.locationMode,
      ),
      const [],
    ),
  };
}

bool _stayTimeReached(DetectorState s, DateTime since, DateTime now) =>
    now.difference(since) >= s.settings.stayTime;

DetectorState _beginStay(DetectorState s, GeoPoint center, int outside) => s
    ._withReturnTo(null)
    ._with(
      phase: InStay(center, s.settings.stayMeters, outsideReadings: outside),
    );

(DetectorState, List<Decision>) _onTick(DetectorState s, DateTime now) {
  final phase = s.phase;
  if (phase is OnRide) return _checkRideEnd(s, phase, now);
  if (phase is Roaming &&
      phase.anchor != null &&
      _stayTimeReached(s, phase.since!, now)) {
    return (_beginStay(s, phase.anchor!, 0), const []);
  }
  return (s, const []);
}

(DetectorState, List<Decision>) _onFix(DetectorState s, LocationFix fix) {
  if (fix.accuracyMeters > maxAccuracyMeters) return (s, const []);

  final decisions = <Decision>[];
  var state = s;
  final returnTo = state.returnTo;
  if (returnTo != null &&
      fix.point.distanceTo(returnTo) <= state.settings.returnMeters) {
    decisions.add(const StopRepeats());
    state = state._withReturnTo(null);
  }

  final (next, more) = switch (state.phase) {
    Roaming() => _fixWhileRoaming(state, fix),
    InStay() => _fixInStay(state, fix),
    OnRide() => _fixOnRide(state, fix),
  };
  return (next, [...decisions, ...more]);
}

(DetectorState, List<Decision>) _fixWhileRoaming(
  DetectorState s,
  LocationFix fix,
) {
  final phase = s.phase as Roaming;
  final anchor = phase.anchor;
  if (anchor == null) {
    return (
      s._with(
        phase: Roaming(anchor: fix.point, since: fix.time),
      ),
      const [],
    );
  }

  final reached = _stayTimeReached(s, phase.since!, fix.time);
  final inside = fix.point.distanceTo(anchor) <= s.settings.stayMeters;
  if (reached) {
    // Readings may have paused during the wait. A reading already outside
    // counts towards leaving, because a missed bag is the worse mistake.
    return (_beginStay(s, anchor, inside ? 0 : 1), const []);
  }
  if (inside) return (s, const []);
  return (
    s._with(
      phase: Roaming(anchor: fix.point, since: fix.time),
    ),
    const [],
  );
}

(DetectorState, List<Decision>) _fixInStay(DetectorState s, LocationFix fix) {
  final phase = s.phase as InStay;
  if (fix.point.distanceTo(phase.center) <= phase.meters) {
    return (s._with(phase: InStay(phase.center, phase.meters)), const []);
  }

  final outside = phase.outsideReadings + 1;
  if (outside < outsideReadingsToLeave) {
    return (
      s._with(
        phase: InStay(phase.center, phase.meters, outsideReadings: outside),
      ),
      const [],
    );
  }

  return _endStay(
    s._with(
      phase: Roaming(anchor: fix.point, since: fix.time),
    ),
    phase.center,
    fix.time,
  );
}

bool _isQuiet(DetectorState s, GeoPoint point) =>
    s.quietPlaces.any((q) => q.point.distanceTo(point) <= quietPlaceMeters);

/// [after] already has the phase that follows the Stay.
(DetectorState, List<Decision>) _endStay(
  DetectorState after,
  GeoPoint center,
  DateTime time,
) {
  if (_isQuiet(after, center)) return (after, const []);
  return (
    after._withReturnTo(center),
    [StartReminder(ReminderSource.stay, LastPlace(center, time))],
  );
}

(DetectorState, List<Decision>) _onActivity(
  DetectorState s,
  ActivityChanged e,
) {
  final phase = s.phase;
  if (phase is OnRide) return _activityOnRide(s, phase, e);
  if (e.kind != ActivityKind.inVehicle || e.confidence < rideStartConfidence) {
    return (s, const []);
  }
  return switch (phase) {
    InStay() => _endStay(
      s._with(
        phase: OnRide(movingAt: e.time, lastPoint: phase.center),
      ),
      phase.center,
      e.time,
    ),
    Roaming() => (
      s._with(
        phase: OnRide(movingAt: e.time, lastPoint: phase.anchor),
      ),
      const [],
    ),
    OnRide() => (s, const []),
  };
}

(DetectorState, List<Decision>) _activityOnRide(
  DetectorState s,
  OnRide phase,
  ActivityChanged e,
) {
  if (e.confidence < activityMinConfidence) {
    return _checkRideEnd(s, phase, e.time);
  }
  final OnRide next = switch (e.kind) {
    ActivityKind.inVehicle => phase.stoppedWalking(movingAt: e.time),
    ActivityKind.still => phase.stoppedWalking(),
    ActivityKind.walking when phase.walkingSince == null => OnRide(
      movingAt: phase.movingAt,
      lastPoint: phase.lastPoint,
      lastFixAt: phase.lastFixAt,
      walkingSince: e.time,
      gotOffPoint: phase.lastPoint,
    ),
    ActivityKind.walking || ActivityKind.unknown => phase,
  };
  return _checkRideEnd(s._with(phase: next), next, e.time);
}

(DetectorState, List<Decision>) _fixOnRide(DetectorState s, LocationFix fix) {
  final phase = s.phase as OnRide;
  final lastPoint = phase.lastPoint;
  final lastFixAt = phase.lastFixAt;
  var moving = false;
  if (lastPoint != null && lastFixAt != null) {
    final seconds = fix.time.difference(lastFixAt).inMilliseconds / 1000;
    moving =
        seconds > 0 &&
        fix.point.distanceTo(lastPoint) / seconds >
            s.settings.vehicleMetersPerSecond;
  }
  final next = OnRide(
    movingAt: moving ? fix.time : phase.movingAt,
    lastPoint: fix.point,
    lastFixAt: fix.time,
    walkingSince: moving ? null : phase.walkingSince,
    gotOffPoint: moving ? null : phase.gotOffPoint ?? _ifWalking(phase, fix),
  );
  return _checkRideEnd(s._with(phase: next), next, fix.time);
}

GeoPoint? _ifWalking(OnRide phase, LocationFix fix) =>
    phase.walkingSince == null ? null : fix.point;

/// A missed bag is the worse mistake, so a Ride that timed out still reminds.
/// With no reading at all there is no Last Place yet, so it waits for one.
(DetectorState, List<Decision>) _checkRideEnd(
  DetectorState s,
  OnRide phase,
  DateTime now,
) {
  final since = phase.walkingSince;
  final confirmed =
      since != null && now.difference(since) >= s.settings.walkingAfterRide;
  final timedOut = now.difference(phase.movingAt) >= rideTimeLimit;
  if (!confirmed && !timedOut) return (s, const []);

  final point = confirmed ? phase.gotOffPoint : phase.lastPoint;
  if (point == null) return (s, const []);

  final roaming = s._with(phase: const Roaming());
  if (_isQuiet(s, point)) return (roaming, const []);
  return (
    roaming,
    [
      StartReminder(
        ReminderSource.ride,
        LastPlace(point, confirmed ? since : phase.movingAt),
      ),
    ],
  );
}

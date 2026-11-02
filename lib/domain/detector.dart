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

/// How close the Wearer must be to count as inside a Reminder Place.
const reminderPlaceMeters = 75.0;

/// Time inside a Reminder Place needed before leaving gives a Reminder.
const reminderPlaceMinVisit = Duration(minutes: 1);

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

// Walking thresholds are starting values, to be retuned from real use.

/// A walking signal counts for this long, so a missed "still" can't keep
/// precise location on for the rest of a Stay.
const walkingSignalLasts = Duration(minutes: 2);

/// While walking, a reading this accurate past half the area ends the Stay or
/// visit. Less accurate readings could be drift.
const walkingFixAccuracyMeters = 25.0;

class QuietPlace {
  const QuietPlace(this.id, this.point);

  final String id;
  final GeoPoint point;
}

class ReminderPlace {
  const ReminderPlace(this.id, this.point, this.message);

  final String id;
  final GeoPoint point;
  final String message;
}

/// Time inside one Reminder Place, tracked alongside Stays and Rides so that
/// it can't disturb them.
class PlaceVisit {
  const PlaceVisit({
    required this.placeId,
    required this.since,
    this.outsideReadings = 0,
    this.firstOutsideAt,
  });

  final String placeId;
  final DateTime since;
  final int outsideReadings;

  /// The best known end of the time inside, while readings look outside.
  final DateTime? firstOutsideAt;
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

class ReminderPlacesChanged extends DetectorEvent {
  const ReminderPlacesChanged(super.time, this.places);

  final List<ReminderPlace> places;
}

class SettingsChanged extends DetectorEvent {
  const SettingsChanged(super.time, this.settings);

  final DetectionSettings settings;
}

// Decisions -----------------------------------------------------------------

enum ReminderSource { stay, ride, reminderPlace }

enum LocationMode { precise, lowPower }

sealed class Decision {
  const Decision();
}

class StartReminder extends Decision {
  const StartReminder(this.source, this.lastPlace, {this.placeMessage});

  final ReminderSource source;
  final LastPlace lastPlace;

  /// The Reminder Place's own message, when one was left.
  final String? placeMessage;
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
    this.reminderPlaces = const [],
    this.visit,
    this.returnTo,
    this.returnMeters,
    this.walkingSince,
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
  final List<ReminderPlace> reminderPlaces;
  final PlaceVisit? visit;

  /// Where the last Reminder's Stay was, until the Wearer returns or a new
  /// Stay begins.
  final GeoPoint? returnTo;

  /// How close counts as back, when not the usual distance. A Reminder confirmed
  /// close to the place needs a closer return, or the next reading would stop it.
  final double? returnMeters;

  /// The latest walking signal outside a Ride.
  final DateTime? walkingSince;

  final LocationMode locationMode;

  DetectorState _copy({
    Phase? phase,
    DetectionSettings? settings,
    List<QuietPlace>? quietPlaces,
    List<ReminderPlace>? reminderPlaces,
    LocationMode? locationMode,
  }) => DetectorState(
    phase: phase ?? this.phase,
    settings: settings ?? this.settings,
    quietPlaces: quietPlaces ?? this.quietPlaces,
    reminderPlaces: reminderPlaces ?? this.reminderPlaces,
    visit: visit,
    returnTo: returnTo,
    returnMeters: returnMeters,
    walkingSince: walkingSince,
    locationMode: locationMode ?? this.locationMode,
  );

  DetectorState _with({Phase? phase}) => _copy(phase: phase);

  DetectorState _withWalking(DateTime? since) => DetectorState(
    phase: phase,
    settings: settings,
    quietPlaces: quietPlaces,
    reminderPlaces: reminderPlaces,
    visit: visit,
    returnTo: returnTo,
    returnMeters: returnMeters,
    walkingSince: since,
    locationMode: locationMode,
  );

  DetectorState _withReturnTo(GeoPoint? point, {double? meters}) =>
      DetectorState(
        phase: phase,
        settings: settings,
        quietPlaces: quietPlaces,
        reminderPlaces: reminderPlaces,
        visit: visit,
        returnTo: point,
        returnMeters: meters,
        walkingSince: walkingSince,
        locationMode: locationMode,
      );

  DetectorState _withVisit(PlaceVisit? value) => DetectorState(
    phase: phase,
    settings: settings,
    quietPlaces: quietPlaces,
    reminderPlaces: reminderPlaces,
    visit: value,
    returnTo: returnTo,
    returnMeters: returnMeters,
    walkingSince: walkingSince,
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
    next._copy(locationMode: mode),
    [...decisions, SetLocationMode(mode)],
  );
}

bool _walkingNow(DetectorState s, DateTime now) {
  final since = s.walkingSince;
  return since != null && now.difference(since) <= walkingSignalLasts;
}

/// A trusted reading while walking, past half of [meters] from [center].
bool _walkedOut(
  DetectorState s,
  LocationFix fix,
  GeoPoint center,
  double meters,
) =>
    _walkingNow(s, fix.time) &&
    fix.accuracyMeters <= walkingFixAccuracyMeters &&
    fix.point.distanceTo(center) > meters / 2;

/// Precise unless settled in a Stay, or walking. Any reading outside wakes precise, even
/// an inaccurate one, and any reading inside rests it again.
LocationMode _modeAfter(
  DetectorState before,
  DetectorState after,
  DetectorEvent event,
) {
  final phase = after.phase;
  if (phase is! InStay || _walkingNow(after, event.time)) {
    return LocationMode.precise;
  }
  if (event is LocationFix) {
    return event.point.distanceTo(phase.center) > phase.meters
        ? LocationMode.precise
        : LocationMode.lowPower;
  }
  if (before.phase is! InStay) return LocationMode.lowPower;
  // Walking was the only thing keeping it precise, unless a reading looked out.
  return before.walkingSince != null && phase.outsideReadings == 0
      ? LocationMode.lowPower
      : before.locationMode;
}

(DetectorState, List<Decision>) _core(
  DetectorState state,
  DetectorEvent event,
) {
  return switch (event) {
    LocationFix() => _onFix(state, event),
    Tick() => _onTick(state, event.time),
    ActivityChanged() => _onActivity(state, event),
    QuietPlacesChanged() => (state._copy(quietPlaces: event.places), const []),
    ReminderPlacesChanged() => (
      state._copy(reminderPlaces: event.places),
      const [],
    ),
    SettingsChanged() => (state._copy(settings: event.settings), const []),
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
      fix.point.distanceTo(returnTo) <=
          (state.returnMeters ?? state.settings.returnMeters)) {
    decisions.add(const StopRepeats());
    state = state._withReturnTo(null);
  }

  final (next, more) = switch (state.phase) {
    Roaming() => _fixWhileRoaming(state, fix),
    InStay() => _fixInStay(state, fix),
    OnRide() => _fixOnRide(state, fix),
  };
  return _trackVisit(next, fix, [...decisions, ...more]);
}

/// Places that count. If stored data ever disagrees, Quiet Place wins.
Iterable<ReminderPlace> _activePlaces(DetectorState s) =>
    s.reminderPlaces.where((p) => !_isQuiet(s, p.point));

ReminderPlace? _activePlaceById(DetectorState s, String id) {
  for (final p in _activePlaces(s)) {
    if (p.id == id) return p;
  }
  return null;
}

/// The nearest place whose area holds [point].
ReminderPlace? _placeAt(DetectorState s, GeoPoint point) {
  ReminderPlace? nearest;
  var best = reminderPlaceMeters;
  for (final p in _activePlaces(s)) {
    final distance = p.point.distanceTo(point);
    if (distance <= best) {
      nearest = p;
      best = distance;
    }
  }
  return nearest;
}

bool _visitLongEnough(PlaceVisit v, DateTime end) =>
    end.difference(v.since) >= reminderPlaceMinVisit;

/// Runs after the phase has handled [fix]. One fix gives at most one Reminder,
/// and a Stay at the place leaves the Reminder to the end of that Stay.
(DetectorState, List<Decision>) _trackVisit(
  DetectorState s,
  LocationFix fix,
  List<Decision> decisions,
) {
  if (s.phase is OnRide) return (s._withVisit(null), decisions);

  DetectorState entering(DetectorState from) {
    final place = _placeAt(from, fix.point);
    return from._withVisit(
      place == null ? null : PlaceVisit(placeId: place.id, since: fix.time),
    );
  }

  if (decisions.any((d) => d is StartReminder)) {
    return (entering(s), decisions);
  }
  final visit = s.visit;
  final place = visit == null ? null : _activePlaceById(s, visit.placeId);
  if (visit == null || place == null) return (entering(s), decisions);

  final phaseNow = s.phase;
  final settledHere =
      phaseNow is InStay && _placeAt(s, phaseNow.center)?.id == place.id;
  if (!settledHere &&
      _visitLongEnough(visit, fix.time) &&
      _walkedOut(s, fix, place.point, reminderPlaceMeters)) {
    return (
      entering(s)._withReturnTo(place.point, meters: reminderPlaceMeters / 4),
      [...decisions, _placeReminder(place, fix.time)],
    );
  }

  if (place.point.distanceTo(fix.point) <= reminderPlaceMeters) {
    return (
      s._withVisit(PlaceVisit(placeId: visit.placeId, since: visit.since)),
      decisions,
    );
  }

  final outside = visit.outsideReadings + 1;
  final firstOutsideAt = visit.firstOutsideAt ?? fix.time;
  if (outside < outsideReadingsToLeave) {
    return (
      s._withVisit(
        PlaceVisit(
          placeId: visit.placeId,
          since: visit.since,
          outsideReadings: outside,
          firstOutsideAt: firstOutsideAt,
        ),
      ),
      decisions,
    );
  }

  final next = entering(s);
  final phase = s.phase;
  final stayHere = phase is InStay && _placeAt(s, phase.center)?.id == place.id;
  final ended = PlaceVisit(placeId: visit.placeId, since: visit.since);
  if (stayHere || !_visitLongEnough(ended, firstOutsideAt)) {
    return (next, decisions);
  }
  return (
    next._withReturnTo(place.point),
    [...decisions, _placeReminder(place, fix.time)],
  );
}

StartReminder _placeReminder(ReminderPlace place, DateTime time) =>
    StartReminder(
      ReminderSource.reminderPlace,
      LastPlace(place.point, time),
      placeMessage: place.message,
    );

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
  if (_walkedOut(s, fix, phase.center, phase.meters)) {
    return _endStay(
      s._with(
        phase: Roaming(anchor: fix.point, since: fix.time),
      ),
      phase.center,
      fix.time,
      returnMeters: phase.meters / 4,
    );
  }
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
  DateTime time, {
  double? returnMeters,
}) {
  if (_isQuiet(after, center)) return (after, const []);
  return (
    after._withReturnTo(center, meters: returnMeters),
    [
      StartReminder(
        ReminderSource.stay,
        LastPlace(center, time),
        placeMessage: _placeAt(after, center)?.message,
      ),
    ],
  );
}

(DetectorState, List<Decision>) _onActivity(
  DetectorState state,
  ActivityChanged e,
) {
  var s = state;
  final phase = s.phase;
  if (phase is OnRide) return _activityOnRide(s, phase, e);
  if (e.confidence >= activityMinConfidence) {
    if (e.kind == ActivityKind.walking) {
      return (s._withWalking(e.time), const []);
    }
    if (e.kind == ActivityKind.still) {
      s = s._withWalking(null);
    }
  }
  if (e.kind != ActivityKind.inVehicle || e.confidence < rideStartConfidence) {
    return (s, const []);
  }
  return switch (phase) {
    InStay() => _endStay(
      s
          ._with(
            phase: OnRide(movingAt: e.time, lastPoint: phase.center),
          )
          ._withVisit(null),
      phase.center,
      e.time,
    ),
    Roaming() => _leaveVisitForRide(
      s._with(
        phase: OnRide(movingAt: e.time, lastPoint: phase.anchor),
      ),
      e.time,
    ),
    OnRide() => (s, const []),
  };
}

/// Getting in a vehicle is a departure too. A Ride that merely passes a place
/// has no visit, because visits aren't tracked during a Ride.
(DetectorState, List<Decision>) _leaveVisitForRide(
  DetectorState s,
  DateTime time,
) {
  final visit = s.visit;
  final place = visit == null ? null : _activePlaceById(s, visit.placeId);
  final cleared = s._withVisit(null);
  if (visit == null ||
      place == null ||
      !_visitLongEnough(visit, visit.firstOutsideAt ?? time)) {
    return (cleared, const []);
  }
  return (cleared._withReturnTo(place.point), [_placeReminder(place, time)]);
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

  final roaming = s._with(phase: const Roaming())._withWalking(null);
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

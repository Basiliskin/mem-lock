import 'geo.dart';

/// Readings less accurate than this are too unreliable to act on.
const maxAccuracyMeters = 50.0;

/// Readings in a row outside the area needed to end a Stay, so that one bad
/// jump in the signal can't trigger a Reminder.
const outsideReadingsToLeave = 2;

/// How close a Stay must be to a Quiet Place to count as being at it.
const quietPlaceMeters = 100.0;

class StaySettings {
  const StaySettings({required this.stayTime, required this.stayMeters});

  static const normal = StaySettings(
    stayTime: Duration(minutes: 5),
    stayMeters: 75,
  );

  final Duration stayTime;
  final double stayMeters;

  /// Coming back needs a reading well inside the area, so that jitter near the
  /// edge while walking away doesn't count as a return.
  double get returnMeters => stayMeters / 2;
}

/// The Helper's choice of how often Reminders happen. Values are to be tuned
/// from the field tests.
enum StayChoice {
  moreOften(StaySettings(stayTime: Duration(minutes: 3), stayMeters: 75)),
  normal(StaySettings.normal),
  lessOften(StaySettings(stayTime: Duration(minutes: 10), stayMeters: 100));

  const StayChoice(this.settings);

  final StaySettings settings;
}

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

class QuietPlacesChanged extends DetectorEvent {
  const QuietPlacesChanged(super.time, this.places);

  final List<QuietPlace> places;
}

class SettingsChanged extends DetectorEvent {
  const SettingsChanged(super.time, this.settings);

  final StaySettings settings;
}

// Decisions -----------------------------------------------------------------

enum ReminderSource { stay }

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
    settings: StaySettings.normal,
    quietPlaces: [],
  );

  final Phase phase;
  final StaySettings settings;
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
    Tick() => (_onTick(state, event.time), const []),
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

DetectorState _onTick(DetectorState s, DateTime now) {
  final phase = s.phase;
  if (phase is Roaming &&
      phase.anchor != null &&
      _stayTimeReached(s, phase.since!, now)) {
    return _beginStay(s, phase.anchor!, 0);
  }
  return s;
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

  final roaming = s._with(
    phase: Roaming(anchor: fix.point, since: fix.time),
  );
  final isQuiet = s.quietPlaces.any(
    (q) => q.point.distanceTo(phase.center) <= quietPlaceMeters,
  );
  if (isQuiet) return (roaming, const []);
  return (
    roaming._withReturnTo(phase.center),
    [StartReminder(ReminderSource.stay, LastPlace(phase.center, fix.time))],
  );
}

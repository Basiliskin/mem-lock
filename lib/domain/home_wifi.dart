import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

/// Connected this long before a drop counts as leaving, so a phone that only
/// touched the home network at the door doesn't remind.
const homeArmAfter = Duration(minutes: 1);

/// Walking this soon before the drop counts as walking out.
const walkBeforeDrop = Duration(seconds: 30);

/// Walking this soon after the drop counts as walking out. Later walking with
/// the router still off is someone moving about the flat.
const walkAfterDrop = Duration(minutes: 2);

/// A reading this far from home confirms leaving when no walking was seen.
const homeLeftMeters = 75.0;

/// Location stays precise this long after a drop, waiting for that reading.
const homeGpsWatch = Duration(minutes: 10);

/// The Wearer's home network, and where home is for the Last Place.
class HomeWifi {
  const HomeWifi(this.network, this.point);

  final String network;
  final GeoPoint point;

  @override
  bool operator ==(Object other) =>
      other is HomeWifi && other.network == network && other.point == point;

  @override
  int get hashCode => Object.hash(network, point);
}

sealed class HomeEvent {
  const HomeEvent(this.time);

  final DateTime time;
}

/// [network] is the network the phone is connected to now, or null.
class WifiChanged extends HomeEvent {
  const WifiChanged(super.time, this.network);

  final String? network;
}

class HomeChanged extends HomeEvent {
  const HomeChanged(super.time, this.home);

  final HomeWifi? home;
}

/// A location reading, activity change or tick.
class Sensed extends HomeEvent {
  Sensed(this.event) : super(event.time);

  final DetectorEvent event;
}

class HomeState {
  const HomeState({
    this.home,
    this.homeSince,
    this.droppedAt,
    this.walkingAt,
    this.reminded = false,
    this.mode = LocationMode.lowPower,
  });

  final HomeWifi? home;

  /// Connected to the home network since then; null when not connected.
  final DateTime? homeSince;

  /// The home network was lost then, and the Wearer hasn't come back.
  final DateTime? droppedAt;
  final DateTime? walkingAt;

  /// A Reminder was given for this departure.
  final bool reminded;
  final LocationMode mode;

  HomeState _copy({
    Object? home = _keep,
    Object? homeSince = _keep,
    Object? droppedAt = _keep,
    Object? walkingAt = _keep,
    bool? reminded,
    LocationMode? mode,
  }) => HomeState(
    home: home == _keep ? this.home : home as HomeWifi?,
    homeSince: homeSince == _keep ? this.homeSince : homeSince as DateTime?,
    droppedAt: droppedAt == _keep ? this.droppedAt : droppedAt as DateTime?,
    walkingAt: walkingAt == _keep ? this.walkingAt : walkingAt as DateTime?,
    reminded: reminded ?? this.reminded,
    mode: mode ?? this.mode,
  );
}

const _keep = Object();

(HomeState, List<Decision>) homeStep(HomeState s, HomeEvent e) {
  final (next, decisions) = switch (e) {
    HomeChanged(:final home) => _onHome(s, home),
    WifiChanged(:final network) => _onWifi(s, e.time, network),
    Sensed(:final event) => _onSensed(s, event),
  };
  return _withMode(next, decisions, e.time);
}

(HomeState, List<Decision>) _onHome(HomeState s, HomeWifi? home) =>
    // The service passes the same home again on every start.
    home == s.home ? (s, const []) : (HomeState(home: home), const []);

(HomeState, List<Decision>) _onWifi(
  HomeState s,
  DateTime now,
  String? network,
) {
  final home = s.home;
  if (home == null) return (s, const []);
  if (network == home.network) {
    if (s.homeSince != null) return (s, const []);
    return (
      s._copy(homeSince: now, droppedAt: null, reminded: false),
      [if (s.reminded) const StopRepeats()],
    );
  }
  final since = s.homeSince;
  if (since == null) return (s, const []);
  final left = s._copy(homeSince: null);
  if (now.difference(since) < homeArmAfter) return (left, const []);
  final dropped = left._copy(droppedAt: now, reminded: false);
  final walkedOut =
      s.walkingAt != null && now.difference(s.walkingAt!) <= walkBeforeDrop;
  return walkedOut ? _remind(dropped) : (dropped, const []);
}

(HomeState, List<Decision>) _onSensed(HomeState s, DetectorEvent e) {
  switch (e) {
    case ActivityChanged(:final kind, :final confidence, :final time)
        when kind == ActivityKind.walking &&
            confidence >= activityMinConfidence:
      final walking = s._copy(walkingAt: time);
      return _waiting(s) && time.difference(s.droppedAt!) <= walkAfterDrop
          ? _remind(walking)
          : (walking, const []);
    case LocationFix(:final point, :final accuracyMeters):
      final home = s.home;
      if (home != null &&
          _waiting(s) &&
          accuracyMeters <= walkingFixAccuracyMeters &&
          point.distanceTo(home.point) > homeLeftMeters) {
        return _remind(s);
      }
      return (s, const []);
    default:
      return (s, const []);
  }
}

bool _waiting(HomeState s) => s.droppedAt != null && !s.reminded;

(HomeState, List<Decision>) _remind(HomeState s) => (
  s._copy(reminded: true),
  [StartReminder(ReminderSource.home, LastPlace(s.home!.point, s.droppedAt!))],
);

/// Precise only while waiting, for a while, for a reading to confirm leaving.
(HomeState, List<Decision>) _withMode(
  HomeState s,
  List<Decision> decisions,
  DateTime now,
) {
  final mode = _waiting(s) && now.difference(s.droppedAt!) <= homeGpsWatch
      ? LocationMode.precise
      : LocationMode.lowPower;
  if (mode == s.mode) return (s, decisions);
  return (s._copy(mode: mode), [...decisions, SetLocationMode(mode)]);
}

String encodeHomeState(HomeState s) => jsonEncode({
  'home': s.home == null ? null : encodeHome(s.home!),
  'homeSince': s.homeSince?.toUtc().toIso8601String(),
  'droppedAt': s.droppedAt?.toUtc().toIso8601String(),
  'walkingAt': s.walkingAt?.toUtc().toIso8601String(),
  'reminded': s.reminded,
  'mode': s.mode.name,
});

/// Unreadable text gives a fresh state, so watching carries on.
HomeState decodeHomeState(String? text) {
  if (text == null) return const HomeState();
  try {
    final m = jsonDecode(text) as Map<String, dynamic>;
    DateTime? time(String key) =>
        m[key] == null ? null : DateTime.parse(m[key] as String);
    return HomeState(
      home: parseHome(m['home'] as String?),
      homeSince: time('homeSince'),
      droppedAt: time('droppedAt'),
      walkingAt: time('walkingAt'),
      reminded: m['reminded'] as bool,
      mode: LocationMode.values.byName(m['mode'] as String),
    );
  } on FormatException {
    return const HomeState();
  } on TypeError {
    return const HomeState();
  } on ArgumentError {
    return const HomeState();
  }
}

String encodeHome(HomeWifi h) =>
    jsonEncode({'network': h.network, 'lat': h.point.lat, 'lng': h.point.lng});

/// Returns null when there is none or it can't be read.
HomeWifi? parseHome(String? text) {
  if (text == null) return null;
  try {
    final m = jsonDecode(text) as Map<String, dynamic>;
    return HomeWifi(
      m['network'] as String,
      GeoPoint((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
    );
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

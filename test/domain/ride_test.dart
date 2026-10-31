import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';

const start = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(start.lat + m / 111195, start.lng);
final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));
LocationFix fix(int s, GeoPoint p, [double acc = 10]) =>
    LocationFix(at(s), p, acc);
ActivityChanged act(int s, ActivityKind k, [int c = 90]) =>
    ActivityChanged(at(s), k, c);

const vehicle = ActivityKind.inVehicle;
const walking = ActivityKind.walking;
const still = ActivityKind.still;

(DetectorState, List<Decision>) run(
  List<DetectorEvent> events, [
  DetectorState? from,
]) {
  var s = from ?? DetectorState.initial();
  final all = <Decision>[];
  for (final e in events) {
    final (n, d) = step(s, e);
    s = n;
    all.addAll(d);
  }
  return (s, all);
}

Iterable<StartReminder> reminders(List<Decision> d) =>
    d.whereType<StartReminder>();

/// On a Ride, moving at 15 m/s until second 100.
final riding = <DetectorEvent>[
  fix(0, start),
  act(1, vehicle),
  fix(50, north(750)),
  fix(100, north(1500)),
];

void main() {
  group('starting', () {
    test('a confident vehicle signal starts a Ride', () {
      final (s, d) = run([fix(0, start), act(1, vehicle)]);
      expect(s.phase, isA<OnRide>());
      expect(d, isNot(contains(isA<StartReminder>())));
    });
    test('a weak vehicle signal does not', () {
      final (s, _) = run([fix(0, start), act(1, vehicle, 60)]);
      expect(s.phase, isA<Roaming>());
    });
    test('walking outside a Ride does nothing', () {
      final (s, d) = run([fix(0, start), act(1, walking)]);
      expect(s.phase, isA<Roaming>());
      expect(reminders(d), isEmpty);
    });
    test('invariant 5: a Ride from a Stay first ends it, with a Reminder', () {
      final (s, d) = run([fix(0, start), Tick(at(300)), act(400, vehicle)]);
      expect(s.phase, isA<OnRide>());
      final r = reminders(d).single;
      expect(r.source, ReminderSource.stay);
      expect(r.lastPlace.point, start);
    });
    test('a Ride from a Stay at a Quiet Place gives no Reminder', () {
      final (s, d) = run([
        QuietPlacesChanged(at(0), const [QuietPlace('home', start)]),
        fix(0, start),
        Tick(at(300)),
        act(400, vehicle),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
  });

  group('ending', () {
    test('AC-2.1: confirmed walking gives one Reminder', () {
      final (s, d) = run([
        ...riding,
        act(110, walking),
        fix(125, north(1520)),
        fix(141, north(1540)),
      ]);
      expect(s.phase, isA<Roaming>());
      expect(reminders(d).single.source, ReminderSource.ride);
    });
    test('walking on afterwards gives no second Reminder', () {
      final (_, d) = run([
        ...riding,
        act(110, walking),
        Tick(at(141)),
        act(150, walking),
        Tick(at(300)),
      ]);
      expect(reminders(d), hasLength(1));
    });
    test('AC-5.3: the Last Place is where walking began, and when', () {
      final (_, d) = run([
        ...riding,
        act(110, walking),
        fix(125, north(1520)),
        fix(141, north(1540)),
      ]);
      final place = reminders(d).single.lastPlace;
      expect(place.point, north(1500));
      expect(place.time, at(110));
    });
    test('a Ride ending at a Quiet Place gives no Reminder', () {
      final (s, d) = run([
        QuietPlacesChanged(at(0), [QuietPlace('home', north(1500))]),
        ...riding,
        act(110, walking),
        Tick(at(141)),
      ]);
      expect(s.phase, isA<Roaming>());
      expect(reminders(d), isEmpty);
    });
    test('with no reading yet, the Reminder waits for the first one', () {
      final (s1, d1) = run([act(0, vehicle), act(100, walking), Tick(at(140))]);
      expect(reminders(d1), isEmpty);
      final (s2, d2) = run([fix(150, north(10))], s1);
      expect(s2.phase, isA<Roaming>());
      expect(reminders(d2).single.lastPlace.point, north(10));
    });
    test('a Ride with no end signal ends after the time limit', () {
      final (s, d) = run([...riding, Tick(at(100 + 15 * 60))]);
      expect(s.phase, isA<Roaming>());
      expect(reminders(d).single.lastPlace.point, north(1500));
    });
    test('a vehicle signal holds off the time limit', () {
      final (s, d) = run([
        ...riding,
        act(800, vehicle),
        Tick(at(100 + 15 * 60)),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
  });

  group('not ending', () {
    test('AC-2.2: a station stop while seated gives no Reminder', () {
      final (s, d) = run([
        ...riding,
        act(110, still),
        fix(200, north(1500)),
        fix(290, north(1500)),
        act(300, vehicle),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
    test('AC-2.3: a short walk along the vehicle gives no Reminder', () {
      final (s, d) = run([
        ...riding,
        act(110, walking),
        Tick(at(125)),
        act(130, vehicle),
        Tick(at(200)),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
    test('AC-2.3: walking signals while moving fast give no Reminder', () {
      final (s, d) = run([
        ...riding,
        act(105, walking),
        fix(120, north(1800)),
        fix(140, north(2100)),
        fix(160, north(2400)),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
    test('stopping to stand restarts the walking time', () {
      final (s, d) = run([
        ...riding,
        act(110, walking),
        act(125, still),
        act(130, walking),
        Tick(at(145)),
      ]);
      expect(s.phase, isA<OnRide>());
      expect(reminders(d), isEmpty);
    });
    test('a weak walking signal does not count', () {
      final (s, _) = run([...riding, act(110, walking, 30), Tick(at(200))]);
      expect(s.phase, isA<OnRide>());
    });
    test('an inaccurate reading is not used as the Last Place', () {
      final (_, d) = run([
        ...riding,
        fix(105, north(9000), 500),
        act(110, walking),
        Tick(at(141)),
      ]);
      expect(reminders(d).single.lastPlace.point, north(1500));
    });
  });

  test('invariant 6: a Ride in progress survives a restart', () {
    final (s, _) = run([...riding, act(110, walking)]);
    final back = decodeState(encodeState(s));
    expect(encodeState(back), encodeState(s));
    final (_, d) = run([Tick(at(141))], back);
    expect(reminders(d).single.lastPlace.time, at(110));
  });

  test('location stays precise during a Ride', () {
    final (s, _) = run(riding);
    expect(s.locationMode, LocationMode.precise);
  });
}

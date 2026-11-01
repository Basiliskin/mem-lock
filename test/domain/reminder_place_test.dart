import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';

const pool = GeoPoint(55.75, 37.61);
const poolPlace = ReminderPlace('p1', pool, 'Take your towel');
GeoPoint north(double m) => GeoPoint(pool.lat + m / 111195, pool.lng);
final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));
LocationFix fix(int s, GeoPoint p, [double acc = 15]) =>
    LocationFix(at(s), p, acc);
ActivityChanged vehicle(int s) =>
    ActivityChanged(at(s), ActivityKind.inVehicle, 90);

(DetectorState, List<StartReminder>, List<Decision>) run(
  List<DetectorEvent> events, {
  List<ReminderPlace> places = const [poolPlace],
  List<QuietPlace> quiet = const [],
}) {
  var (s, _) = step(DetectorState.initial(), ReminderPlacesChanged(t0, places));
  (s, _) = step(s, QuietPlacesChanged(t0, quiet));
  final all = <Decision>[];
  for (final e in events) {
    final (n, d) = step(s, e);
    s = n;
    all.addAll(d);
  }
  return (s, all.whereType<StartReminder>().toList(), all);
}

List<DetectorEvent> replayFile(String name) => [
  for (final line in File('test/fixtures/$name.jsonl').readAsLinesSync())
    if (line.trim().isNotEmpty)
      _event(jsonDecode(line) as Map<String, dynamic>),
];

DetectorEvent _event(Map<String, dynamic> m) {
  final time = at(m['t'] as int);
  if (m.containsKey('activity')) {
    return ActivityChanged(time, ActivityKind.inVehicle, 90);
  }
  return LocationFix(
    time,
    GeoPoint(m['lat'] as double, m['lng'] as double),
    (m['acc'] as num).toDouble(),
  );
}

void main() {
  group('replays', () {
    test('AC-11.2: a 3-minute visit gives one Reminder with the message', () {
      final (_, r, _) = run(replayFile('synthetic_place_visit'));
      expect(r, hasLength(1));
      expect(r.single.source, ReminderSource.reminderPlace);
      expect(r.single.placeMessage, 'Take your towel');
    });

    test('AC-11.3: walking past along the edge gives none', () {
      final (_, r, _) = run(replayFile('synthetic_place_walk_past'));
      expect(r, isEmpty);
    });

    test('AC-11.5: a Stay at the place gives one, with the message', () {
      final (_, r, _) = run(replayFile('synthetic_place_stay'));
      expect(r, hasLength(1));
      expect(r.single.source, ReminderSource.stay);
      expect(r.single.placeMessage, 'Take your towel');
    });

    test('passing in a vehicle, even stopped nearby, gives none', () {
      final (_, r, _) = run(replayFile('synthetic_place_in_vehicle'));
      expect(r, isEmpty);
    });
  });

  group('AC-11.2 and AC-11.3: a visit', () {
    List<DetectorEvent> visit(int seconds) => [
      fix(0, pool),
      fix(seconds, north(100)),
      fix(seconds + 10, north(120)),
    ];

    test('exactly 1 minute counts', () {
      expect(run(visit(60)).$2, hasLength(1));
    });

    test('just under 1 minute does not', () {
      expect(run(visit(59)).$2, isEmpty);
    });

    test('time spent walking away does not count', () {
      expect(
        run([fix(0, pool), fix(40, north(100)), fix(90, north(200))]).$2,
        isEmpty,
      );
    });

    test('one bad reading neither ends a visit nor restarts it', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(30, north(200)),
        fix(40, pool),
        fix(70, north(200)),
        fix(80, north(220)),
      ]);
      expect(r, hasLength(1));
    });

    test('one outside reading alone gives nothing', () {
      expect(run([fix(0, pool), fix(90, north(200))]).$2, isEmpty);
    });

    test('inaccurate readings are ignored', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(90, north(200), 80),
        fix(100, north(200), 80),
      ]);
      expect(r, isEmpty);
    });

    test('a later visit gives its own Reminder', () {
      final (_, r, _) = run([
        ...visit(70),
        fix(200, pool),
        fix(280, north(100)),
        fix(290, north(120)),
      ]);
      expect(r, hasLength(2));
    });

    test('AC-11.8: carries the place as its Last Place', () {
      final r = run(visit(70)).$2.single;
      expect(r.lastPlace.point, pool);
      expect(r.lastPlace.time, at(80));
    });

    test('coming back stops the repeats', () {
      final (s, _, all) = run([...visit(70), fix(100, pool)]);
      expect(all.whereType<StopRepeats>(), hasLength(1));
      expect(s.returnTo, isNull);
    });

    test('does not disturb Stay detection', () {
      final (a, _, _) = run([fix(0, pool), fix(10, north(10))]);
      final (b, _, _) = run([fix(0, pool), fix(10, north(10))], places: []);
      expect((a.phase as Roaming).since, (b.phase as Roaming).since);
      expect((a.phase as Roaming).anchor, (b.phase as Roaming).anchor);
    });
  });

  group('AC-11.5: a Stay at a place', () {
    test('a Stay centred inside the area but off-centre gives one', () {
      // Leaves the place's area before the Stay's own area.
      final (_, r, _) = run([
        fix(0, north(50)),
        Tick(at(300)),
        fix(310, north(80)),
        fix(320, north(85)),
        fix(330, north(130)),
        fix(340, north(140)),
      ]);
      expect(r, hasLength(1));
      expect(r.single.placeMessage, 'Take your towel');
    });

    test('a Stay ended by getting in a vehicle uses the message', () {
      final (_, r, _) = run([fix(0, pool), Tick(at(300)), vehicle(310)]);
      expect(r, hasLength(1));
      expect(r.single.source, ReminderSource.stay);
      expect(r.single.placeMessage, 'Take your towel');
    });

    test('a Stay elsewhere has no message', () {
      final (_, r, _) = run([
        fix(0, north(500)),
        Tick(at(300)),
        fix(310, north(700)),
        fix(320, north(800)),
      ]);
      expect(r, hasLength(1));
      expect(r.single.placeMessage, isNull);
    });
  });

  group('Rides', () {
    test('getting in a vehicle after a visit gives one Reminder', () {
      final (s, r, _) = run([fix(0, pool), fix(70, pool), vehicle(80)]);
      expect(r, hasLength(1));
      expect(r.single.source, ReminderSource.reminderPlace);
      expect(r.single.placeMessage, 'Take your towel');
      expect(s.phase, isA<OnRide>());
    });

    test('getting in a vehicle after under 1 minute gives none', () {
      expect(run([fix(0, pool), fix(30, pool), vehicle(40)]).$2, isEmpty);
    });

    test('a weak vehicle signal does not end a visit', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(70, pool),
        ActivityChanged(at(80), ActivityKind.inVehicle, 60),
      ]);
      expect(r, isEmpty);
    });

    test('a Ride ending near the place still gives only the Ride one', () {
      final (_, r, _) = run([
        vehicle(1),
        fix(10, north(-500)),
        fix(50, pool),
        ActivityChanged(at(60), ActivityKind.walking, 90),
        Tick(at(95)),
      ]);
      expect(r, hasLength(1));
      expect(r.single.source, ReminderSource.ride);
      expect(r.single.placeMessage, isNull);
    });
  });

  group('changing the list', () {
    test('AC-11.7: a removed place gives no Reminder, even mid-visit', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(70, pool),
        ReminderPlacesChanged(at(75), const []),
        fix(80, north(100)),
        fix(90, north(120)),
      ]);
      expect(r, isEmpty);
    });

    test('AC-11.7: a Stay at a removed place has no message', () {
      final (_, r, _) = run([
        fix(0, pool),
        Tick(at(300)),
        ReminderPlacesChanged(at(305), const []),
        fix(310, north(100)),
        fix(320, north(120)),
      ]);
      expect(r.single.placeMessage, isNull);
    });

    test('an edited place keeps its visit and uses the new message', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(70, pool),
        ReminderPlacesChanged(at(75), const [
          ReminderPlace('p1', pool, 'New message'),
        ]),
        fix(80, north(100)),
        fix(90, north(120)),
      ]);
      expect(r.single.placeMessage, 'New message');
    });
  });

  group('Quiet Place wins over stored data that disagrees', () {
    const quiet = [QuietPlace('q1', pool)];

    test('leaving gives no Reminder', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(70, north(150)),
        fix(80, north(170)),
      ], quiet: quiet);
      expect(r, isEmpty);
    });

    test('a Stay there gives no Reminder', () {
      final (_, r, _) = run([
        fix(0, pool),
        Tick(at(300)),
        fix(310, north(300)),
        fix(320, north(320)),
      ], quiet: quiet);
      expect(r, isEmpty);
    });

    test('becoming quiet mid-visit stops it', () {
      final (_, r, _) = run([
        fix(0, pool),
        fix(70, pool),
        QuietPlacesChanged(at(75), quiet),
        fix(80, north(150)),
        fix(90, north(170)),
      ]);
      expect(r, isEmpty);
    });
  });

  group('saving', () {
    test('places and a visit survive a restart', () {
      final (s, _, _) = run([fix(0, pool), fix(30, north(100))]);
      final back = decodeState(encodeState(s));
      expect(back.reminderPlaces.single.message, 'Take your towel');
      final (_, d) = step(back, fix(70, north(120)));
      expect(d.whereType<StartReminder>(), isEmpty);
      expect(back.visit!.since, at(0));
      expect(back.visit!.outsideReadings, 1);
      expect(back.visit!.firstOutsideAt, at(30));
    });

    test('a visit in progress still reminds after a restart', () {
      final (s, _, _) = run([fix(0, pool), fix(70, north(100))]);
      final (_, d) = step(decodeState(encodeState(s)), fix(80, north(120)));
      expect(d.whereType<StartReminder>(), hasLength(1));
    });

    test('a state saved before Reminder Places still loads', () {
      final s = decodeState(
        '{"phase":{"type":"inStay","center":{"lat":1.0,"lng":2.0},"meters":75,'
        '"outside":0},"staySeconds":300,"stayMeters":75,"quiet":[],'
        '"returnTo":null,"mode":"lowPower"}',
      );
      expect(s.phase, isA<InStay>());
      expect(s.reminderPlaces, isEmpty);
      expect(s.visit, isNull);
    });
  });

  test(
    'known limit: walking through the middle at 1.4 m/s counts as a visit',
    () {
      // 150 m takes about 107 s. AC-11.2 only asks for 1 minute inside; to be
      // judged from FT-6.
      final (_, r, _) = run([
        for (var i = 0; i < 20; i++) fix(i * 10, north(-130.0 + i * 14)),
      ]);
      expect(r, hasLength(1));
    },
  );
}

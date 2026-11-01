import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int minutes, [int seconds = 0]) =>
    t0.add(Duration(minutes: minutes, seconds: seconds));

const cafe = GeoPoint(55.75, 37.61);

/// A point this many metres north of the cafe. 1 degree is about 111,195 m.
GeoPoint north(double metres) => GeoPoint(cafe.lat + metres / 111195, cafe.lng);

LocationFix fix(DateTime time, GeoPoint p, {double accuracy = 10}) =>
    LocationFix(time, p, accuracy);

/// Runs events in order and returns the final state and every decision.
(DetectorState, List<Decision>) run(
  List<DetectorEvent> events, [
  DetectorState? from,
]) {
  var state = from ?? DetectorState.initial();
  final out = <Decision>[];
  for (final e in events) {
    final (next, decisions) = step(state, e);
    state = next;
    out.addAll(decisions.where((d) => d is! SetLocationMode));
  }
  return (state, out);
}

/// A completed Stay at the cafe, ready to be left.
List<DetectorEvent> stayed() => [fix(at(0), cafe), Tick(at(5))];

List<DetectorEvent> leave({int minute = 6}) => [
  fix(at(minute), north(200)),
  fix(at(minute, 10), north(220)),
];

void main() {
  test('distance is close to the known value', () {
    expect(north(1000).distanceTo(cafe), closeTo(1000, 1));
  });

  group('Stay begins', () {
    test('after the Stay time in the area', () {
      final (s, _) = run(stayed());
      expect(s.phase, isA<InStay>());
    });

    test('not one second before the Stay time', () {
      final (s, _) = run([fix(at(0), cafe), Tick(at(4, 59))]);
      expect(s.phase, isA<Roaming>());
    });

    test('a fix after the Stay time also begins it, with no Tick', () {
      final (s, _) = run([fix(at(0), cafe), fix(at(5), north(5))]);
      expect(s.phase, isA<InStay>());
    });

    test('moving out of the area restarts the clock', () {
      final (s, _) = run([
        fix(at(0), cafe),
        fix(at(3), north(200)),
        Tick(at(5)),
      ]);
      expect(s.phase, isA<Roaming>());
    });
  });

  group('AC-1.1: leaving a Stay', () {
    test('gives one Reminder with the Stay middle and end time', () {
      final (s, d) = run([...stayed(), ...leave()]);
      final r = d.single as StartReminder;
      expect(r.source, ReminderSource.stay);
      expect(r.lastPlace.point, cafe);
      expect(r.lastPlace.time, at(6, 10));
      expect(s.phase, isA<Roaming>());
    });

    test('a long gap followed by leaving still counts as a Stay', () {
      final (_, d) = run([
        fix(at(0), cafe),
        fix(at(30), north(200)),
        fix(at(30, 10), north(220)),
      ]);
      expect(d.single, isA<StartReminder>());
    });
  });

  group('AC-1.2: short stops', () {
    test('give no Reminder', () {
      final (_, d) = run([
        fix(at(0), cafe),
        fix(at(4), cafe),
        fix(at(4, 30), north(200)),
        fix(at(4, 40), north(220)),
      ]);
      expect(d, isEmpty);
    });
  });

  group('AC-1.4: signal drift', () {
    test('within the area gives no Reminder', () {
      final (_, d) = run([
        ...stayed(),
        for (var i = 0; i < 20; i++)
          fix(at(6 + i), north(i.isEven ? 40 : -40), accuracy: 30),
      ]);
      expect(d, isEmpty);
    });

    test('one jump out of the area gives no Reminder', () {
      final (s, d) = run([
        ...stayed(),
        fix(at(6), north(300)),
        fix(at(7), cafe),
        fix(at(8), north(300)),
        fix(at(9), cafe),
      ]);
      expect(d, isEmpty);
      expect(s.phase, isA<InStay>());
    });

    test('readings too inaccurate to trust never end a Stay', () {
      final (s, d) = run([
        ...stayed(),
        fix(at(6), north(500), accuracy: 51),
        fix(at(7), north(500), accuracy: 200),
        fix(at(8), north(500), accuracy: 200),
      ]);
      expect(d, isEmpty);
      expect(s.phase, isA<InStay>());
    });

    test('an inaccurate reading between two outside does not end it', () {
      final (_, d) = run([
        ...stayed(),
        fix(at(6), north(200)),
        fix(at(6, 10), north(900), accuracy: 200),
      ]);
      expect(d, isEmpty);
    });

    test('an inaccurate reading cannot start the Stay clock', () {
      final (s, _) = run([fix(at(0), cafe, accuracy: 200), Tick(at(10))]);
      expect(s.phase, isA<Roaming>());
    });
  });

  group('AC-1.5: one Reminder per Stay', () {
    test('crossing back and out again gives no second Reminder', () {
      final (_, d) = run([
        ...stayed(),
        ...leave(),
        fix(at(6, 20), cafe),
        fix(at(6, 30), north(200)),
        fix(at(6, 40), north(220)),
      ]);
      expect(d.whereType<StartReminder>(), hasLength(1));
    });

    test('a new full Stay somewhere else gives its own Reminder', () {
      final (_, d) = run([
        ...stayed(),
        ...leave(),
        Tick(at(12)),
        fix(at(13), north(600)),
        fix(at(13, 10), north(620)),
      ]);
      expect(d.whereType<StartReminder>(), hasLength(2));
    });
  });

  group('Quiet Places', () {
    final home = QuietPlace('home', cafe);
    final quiet = QuietPlacesChanged(at(0), [home]);

    test('AC-1.3: leaving one gives no Reminder', () {
      final (s, d) = run([quiet, ...stayed(), ...leave()]);
      expect(d, isEmpty);
      expect(s.phase, isA<Roaming>());
    });

    test('AC-6.2: any of several counts', () {
      final (_, d) = run([
        QuietPlacesChanged(at(0), [QuietPlace('other', north(5000)), home]),
        ...stayed(),
        ...leave(),
      ]);
      expect(d, isEmpty);
    });

    test('a Stay just outside the Quiet Place size gives a Reminder', () {
      final (_, d) = run([
        QuietPlacesChanged(at(0), [QuietPlace('near', north(101))]),
        ...stayed(),
        ...leave(),
      ]);
      expect(d.single, isA<StartReminder>());
    });

    test('a Stay just inside the Quiet Place size is silent', () {
      final (_, d) = run([
        QuietPlacesChanged(at(0), [QuietPlace('near', north(99))]),
        ...stayed(),
        ...leave(),
      ]);
      expect(d, isEmpty);
    });

    test('AC-6.3: after removal, leaving gives a Reminder', () {
      final (_, d) = run([
        quiet,
        ...stayed(),
        QuietPlacesChanged(at(5), const []),
        ...leave(),
      ]);
      expect(d.single, isA<StartReminder>());
    });
  });

  group('AC-3.3: coming back', () {
    test('stops the repeats, once', () {
      final (_, d) = run([
        ...stayed(),
        ...leave(),
        fix(at(7), north(20)),
        fix(at(8), north(10)),
      ]);
      expect(d.whereType<StopRepeats>(), hasLength(1));
    });

    test('jitter near the edge while walking away does not stop them', () {
      final (_, d) = run([...stayed(), ...leave(), fix(at(7), north(60))]);
      expect(d.whereType<StopRepeats>(), isEmpty);
    });

    test('an inaccurate reading does not stop them', () {
      final (_, d) = run([
        ...stayed(),
        ...leave(),
        fix(at(7), cafe, accuracy: 200),
      ]);
      expect(d.whereType<StopRepeats>(), isEmpty);
    });

    test('a silent Quiet Place exit has nothing to stop', () {
      final (_, d) = run([
        QuietPlacesChanged(at(0), [QuietPlace('home', cafe)]),
        ...stayed(),
        ...leave(),
        fix(at(7), cafe),
      ]);
      expect(d, isEmpty);
    });
  });

  group('settings', () {
    test('default to Normal: 5 minutes and 75 metres', () {
      final s = DetectorState.initial().settings;
      expect(s.stayTime, const Duration(minutes: 5));
      expect(s.stayMeters, 75);
    });

    test('a changed Stay time applies', () {
      final (s, _) = run([
        SettingsChanged(
          at(0),
          const DetectionSettings(
            stayTime: Duration(minutes: 15),
            stayMeters: 75,
          ),
        ),
        fix(at(0), cafe),
        Tick(at(10)),
      ]);
      expect(s.phase, isA<Roaming>());
    });

    test('a changed Stay distance applies', () {
      final (_, d) = run([
        SettingsChanged(
          at(0),
          const DetectionSettings(
            stayTime: Duration(minutes: 5),
            stayMeters: 300,
          ),
        ),
        ...stayed(),
        ...leave(),
      ]);
      expect(d, isEmpty);
    });
  });
}

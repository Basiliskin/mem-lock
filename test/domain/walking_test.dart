import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/detector_json.dart';
import 'package:leavecheck/domain/geo.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int seconds) => t0.add(Duration(seconds: seconds));
const cafe = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(cafe.lat + m / 111195, cafe.lng);

class Run {
  Run([DetectorState? start]) : state = start ?? DetectorState.initial();
  DetectorState state;

  List<Decision> send(DetectorEvent e) {
    final (next, d) = step(state, e);
    state = next;
    return d;
  }

  /// A Stay at the cafe on Normal: 75 m, so half is 37.5 m. Ends at 300 s.
  void toStay() {
    send(LocationFix(at(0), cafe, 10));
    send(Tick(at(300)));
  }

  List<Decision> walk(int s, {int confidence = 80}) =>
      send(ActivityChanged(at(s), ActivityKind.walking, confidence));

  List<Decision> fix(int s, double meters, {double accuracy = 10}) =>
      send(LocationFix(at(s), north(meters), accuracy));
}

Iterable<StartReminder> reminders(List<Decision> d) =>
    d.whereType<StartReminder>();
Iterable<LocationMode> modes(List<Decision> d) =>
    d.whereType<SetLocationMode>().map((m) => m.mode);

void main() {
  group('Stay', () {
    test('walking wakes precise location', () {
      final r = Run()..toStay();
      expect(modes(r.walk(400)), [LocationMode.precise]);
    });

    test('a weak walking signal does nothing', () {
      final r = Run()..toStay();
      expect(r.walk(400, confidence: 30), isEmpty);
      expect(r.state.walkingSince, isNull);
    });

    test(
      'walking and a good reading past half the area gives one Reminder',
      () {
        final r = Run()..toStay();
        r.walk(400);
        expect(reminders(r.fix(410, 30)), isEmpty);
        expect(reminders(r.fix(420, 40)), hasLength(1));
        expect(reminders(r.fix(430, 50)), isEmpty);
      },
    );

    test('an inaccurate reading does not confirm leaving', () {
      final r = Run()..toStay();
      r.walk(400);
      expect(reminders(r.fix(410, 40, accuracy: 30)), isEmpty);
    });

    test('without walking, past half the area is still inside', () {
      final r = Run()..toStay();
      expect(reminders(r.fix(400, 40)), isEmpty);
    });

    test('a walking signal too old no longer counts', () {
      final r = Run()..toStay();
      r.walk(400);
      expect(reminders(r.fix(521, 40)), isEmpty);
    });

    test('becoming still ends walking and rests location', () {
      final r = Run()..toStay();
      r.walk(400);
      final d = r.send(ActivityChanged(at(410), ActivityKind.still, 80));
      expect(modes(d), [LocationMode.lowPower]);
      expect(reminders(r.fix(420, 40)), isEmpty);
    });

    test('an expired walking signal rests location on the next tick', () {
      final r = Run()..toStay();
      r.walk(400);
      expect(modes(r.send(Tick(at(521)))), [LocationMode.lowPower]);
    });

    test('a Quiet Place stays silent', () {
      final r = Run();
      r.send(QuietPlacesChanged(at(0), const [QuietPlace('home', cafe)]));
      r.toStay();
      r.walk(400);
      expect(reminders(r.fix(410, 40)), isEmpty);
    });

    test('the next reading nearby does not stop the repeats', () {
      final r = Run()..toStay();
      r.walk(400);
      r.fix(410, 40);
      expect(r.fix(420, 36).whereType<StopRepeats>(), isEmpty);
      expect(r.fix(430, 18).whereType<StopRepeats>(), hasLength(1));
    });

    test('the two-reading rule still works without walking', () {
      final r = Run()..toStay();
      expect(reminders(r.fix(400, 100)), isEmpty);
      expect(reminders(r.fix(410, 110)), hasLength(1));
    });
  });

  group('Reminder Place', () {
    Run visiting() {
      final r = Run();
      r.send(
        ReminderPlacesChanged(at(0), const [ReminderPlace('p', cafe, 'Bag?')]),
      );
      r.fix(0, 0);
      r.fix(90, 0);
      return r;
    }

    test('walking out past half gives its Reminder with its message', () {
      final r = visiting();
      r.walk(95);
      final found = reminders(r.fix(100, 40));
      expect(found.single.placeMessage, 'Bag?');
      expect(r.state.returnMeters, reminderPlaceMeters / 4);
    });

    test('a visit too short gives none', () {
      final r = Run();
      r.send(
        ReminderPlacesChanged(at(0), const [ReminderPlace('p', cafe, 'Bag?')]),
      );
      r.fix(0, 0);
      r.walk(10);
      expect(reminders(r.fix(20, 40)), isEmpty);
    });
  });

  test('walking and the return distance survive saving', () {
    final r = Run()..toStay();
    r.walk(400);
    r.fix(410, 40);
    final back = decodeState(encodeState(r.state));
    expect(back.walkingSince, r.state.walkingSince);
    expect(back.returnMeters, 75 / 4);
  });

  test('a state saved before this change still loads', () {
    final text = encodeState(DetectorState.initial())
        .replaceAll('"returnMeters":null,', '')
        .replaceAll('"walkingSince":null,', '');
    expect(decodeState(text).walkingSince, isNull);
  });
}

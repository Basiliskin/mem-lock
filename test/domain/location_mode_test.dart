import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int minutes) => t0.add(Duration(minutes: minutes));
const cafe = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(cafe.lat + m / 111195, cafe.lng);

class Run {
  DetectorState state = DetectorState.initial();
  List<LocationMode> modes(DetectorEvent e) {
    final (next, d) = step(state, e);
    state = next;
    return d.whereType<SetLocationMode>().map((m) => m.mode).toList();
  }

  void toStay() {
    modes(LocationFix(at(0), cafe, 10));
    modes(Tick(at(5)));
  }
}

void main() {
  test('starts precise, so a first Stay can be recognised', () {
    expect(DetectorState.initial().locationMode, LocationMode.precise);
  });

  test('AC-9.1: beginning a Stay rests location', () {
    final r = Run();
    r.modes(LocationFix(at(0), cafe, 10));
    expect(r.modes(Tick(at(5))), [LocationMode.lowPower]);
  });

  test('a Stay begun by a reading inside the area also rests it', () {
    final r = Run();
    r.modes(LocationFix(at(0), cafe, 10));
    expect(r.modes(LocationFix(at(5), cafe, 10)), [LocationMode.lowPower]);
  });

  test('no repeat decision while the mode is unchanged', () {
    final r = Run()..toStay();
    expect(r.modes(LocationFix(at(6), cafe, 90)), isEmpty);
    expect(r.modes(Tick(at(7))), isEmpty);
  });

  test('a low-power reading outside the area wakes precise', () {
    final r = Run()..toStay();
    expect(r.modes(LocationFix(at(6), north(200), 20)), [LocationMode.precise]);
  });

  test('an inaccurate reading outside also wakes it, without ending', () {
    final r = Run()..toStay();
    expect(r.modes(LocationFix(at(6), north(200), 150)), [
      LocationMode.precise,
    ]);
    expect(r.state.phase, isA<InStay>());
  });

  test('a false alarm goes back to low power', () {
    final r = Run()..toStay();
    r.modes(LocationFix(at(6), north(200), 150));
    expect(r.modes(LocationFix(at(7), cafe, 10)), [LocationMode.lowPower]);
  });

  test('stays precise after really leaving', () {
    final r = Run()..toStay();
    r.modes(LocationFix(at(6), north(200), 20));
    final (next, d) = step(r.state, LocationFix(at(6), north(220), 10));
    expect(d.whereType<SetLocationMode>(), isEmpty);
    expect(d.whereType<StartReminder>(), hasLength(1));
    expect(next.locationMode, LocationMode.precise);
  });
}

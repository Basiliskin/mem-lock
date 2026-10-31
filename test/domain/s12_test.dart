import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/battery.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';

const cafe = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(cafe.lat + m / 111195, cafe.lng);
final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int m) => t0.add(Duration(minutes: m));
LastPlaceRecord rec(int m) => LastPlaceRecord(cafe, at(m), ReminderSource.stay);

(DetectorState, List<Decision>) run(List<DetectorEvent> events) {
  var s = DetectorState.initial();
  final all = <Decision>[];
  for (final e in events) {
    final (n, d) = step(s, e);
    s = n;
    all.addAll(d);
  }
  return (s, all);
}

void main() {
  group('Stay choice', () {
    test('AC-10.2: Normal is 5 minutes and 75 m', () {
      expect(StayChoice.normal.settings.stayTime, const Duration(minutes: 5));
      expect(StayChoice.normal.settings.stayMeters, 75);
    });
    test('More often and Less often use the chosen values', () {
      expect(StayChoice.moreOften.settings.stayTime.inMinutes, 3);
      expect(StayChoice.moreOften.settings.stayMeters, 75);
      expect(StayChoice.lessOften.settings.stayTime.inMinutes, 10);
      expect(StayChoice.lessOften.settings.stayMeters, 100);
    });
    test('AC-10.1: a later Stay uses the new values', () {
      final (s, _) = run([
        SettingsChanged(at(0), StayChoice.moreOften.settings),
        LocationFix(at(0), cafe, 10),
        Tick(at(3)),
      ]);
      expect(s.phase, isA<InStay>());
    });
    test('AC-10.1: a Stay in progress keeps the distance it began with', () {
      final (_, d) = run([
        SettingsChanged(at(0), StayChoice.lessOften.settings),
        LocationFix(at(0), cafe, 10),
        Tick(at(10)),
        SettingsChanged(at(11), StayChoice.moreOften.settings),
        LocationFix(at(12), north(90), 10),
        LocationFix(at(13), north(90), 10),
      ]);
      expect(d.whereType<StartReminder>(), isEmpty);
    });
    test('the location mode also uses the Stay distance', () {
      final (s, _) = run([
        SettingsChanged(at(0), StayChoice.lessOften.settings),
        LocationFix(at(0), cafe, 10),
        Tick(at(10)),
        SettingsChanged(at(11), StayChoice.moreOften.settings),
        LocationFix(at(12), north(90), 10),
      ]);
      expect(s.locationMode, LocationMode.lowPower);
    });
    test('the Stay distance survives a restart', () {
      final (s, _) = run([
        SettingsChanged(at(0), StayChoice.lessOften.settings),
        LocationFix(at(0), cafe, 10),
        Tick(at(10)),
      ]);
      final back = decodeState(encodeState(s));
      expect((back.phase as InStay).meters, 100);
    });
    test('a state saved before S12 uses the current distance', () {
      final (s, _) = run([LocationFix(at(0), cafe, 10), Tick(at(5))]);
      final old = encodeState(s).replaceFirst('"meters":75.0,', '');
      expect(old, isNot(contains('"meters"')));
      expect((decodeState(old).phase as InStay).meters, 75);
    });
  });

  group('Last Places', () {
    test('AC-5.5: only the two newest are kept, newest first', () {
      final kept = withNewest(withNewest([rec(1)], rec(2)), rec(3));
      expect(kept.map((r) => r.time), [at(3), at(2)]);
    });
    test('a list survives a round trip', () {
      final back = parseLastPlaces(encodeLastPlaces([rec(2), rec(1)]));
      expect(back.map((r) => r.time.toUtc()), [at(2), at(1)]);
    });
    test('text saved as one place before S12 still reads', () {
      expect(parseLastPlaces(rec(1).encode()).single.time.toUtc(), at(1));
    });
    test('unreadable text gives an empty list', () {
      expect(parseLastPlaces('garbage'), isEmpty);
      expect(parseLastPlaces('{}'), isEmpty);
      expect(parseLastPlaces('[{}]'), isEmpty);
    });
  });

  group('BatteryReading', () {
    test('low at 20% or under, unless charging', () {
      expect(const BatteryReading(20, charging: false).isLow, isTrue);
      expect(const BatteryReading(21, charging: false).isLow, isFalse);
      expect(const BatteryReading(5, charging: true).isLow, isFalse);
    });
    test('the period ends on charging or above 25%', () {
      expect(const BatteryReading(5, charging: true).periodOver, isTrue);
      expect(const BatteryReading(26, charging: false).periodOver, isTrue);
      expect(const BatteryReading(25, charging: false).periodOver, isFalse);
    });
  });
}

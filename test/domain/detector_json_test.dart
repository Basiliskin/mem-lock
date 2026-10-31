import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
const cafe = GeoPoint(55.75, 37.61);

DetectorState back(DetectorState s) => decodeState(encodeState(s));

void main() {
  test('Roaming with an anchor survives', () {
    final s = back(
      DetectorState(
        phase: Roaming(anchor: cafe, since: t0),
        settings: StaySettings.normal,
        quietPlaces: const [QuietPlace('home', cafe)],
        returnTo: cafe,
      ),
    );
    final p = s.phase as Roaming;
    expect(p.anchor, cafe);
    expect(p.since, t0);
    expect(s.quietPlaces.single.id, 'home');
    expect(s.quietPlaces.single.point, cafe);
    expect(s.returnTo, cafe);
  });

  test('empty Roaming survives', () {
    final p = back(DetectorState.initial()).phase as Roaming;
    expect(p.anchor, isNull);
    expect(p.since, isNull);
  });

  test('InStay, its outside count, settings and mode survive', () {
    final s = back(
      const DetectorState(
        phase: InStay(cafe, outsideReadings: 1),
        settings: StaySettings(
          stayTime: Duration(minutes: 15),
          stayMeters: 120,
        ),
        quietPlaces: [],
        locationMode: LocationMode.lowPower,
      ),
    );
    final p = s.phase as InStay;
    expect(p.center, cafe);
    expect(p.outsideReadings, 1);
    expect(s.settings.stayTime, const Duration(minutes: 15));
    expect(s.settings.stayMeters, 120);
    expect(s.returnTo, isNull);
    expect(s.locationMode, LocationMode.lowPower);
  });

  test('unreadable text throws FormatException', () {
    for (final bad in [
      'not json',
      '{}',
      '[]',
      '{"phase":{"type":"other"}}',
      '{"phase":{"type":"inStay","lat":"x"}}',
    ]) {
      expect(() => decodeState(bad), throwsFormatException, reason: bad);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';

const start = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(start.lat + m / 111195, start.lng);
final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));

DetectionSettings custom({
  Duration stayTime = const Duration(minutes: 5),
  double stayMeters = 75,
  double vehicleKmh = 14.4,
  Duration walkingAfterRide = const Duration(seconds: 30),
}) => DetectionSettings(
  stayTime: stayTime,
  stayMeters: stayMeters,
  vehicleKmh: vehicleKmh,
  walkingAfterRide: walkingAfterRide,
);

List<Decision> decisions(DetectionSettings settings, List<DetectorEvent> list) {
  var (s, _) = step(DetectorState.initial(), SettingsChanged(at(0), settings));
  final all = <Decision>[];
  for (final e in list) {
    final (n, d) = step(s, e);
    s = n;
    all.addAll(d);
  }
  return all.whereType<StartReminder>().toList();
}

void main() {
  group('recommended values', () {
    test('AC-10.2: match the values the Detector was tuned with', () {
      const s = DetectionSettings.normal;
      expect(s.stayTime, const Duration(minutes: 5));
      expect(s.stayMeters, 75);
      expect(s.vehicleMetersPerSecond, 4.0);
      expect(s.walkingAfterRide, const Duration(seconds: 30));
      expect(s.withinLimits, isTrue);
    });

    test('every preset is within limits', () {
      for (final c in StayChoice.values) {
        expect(c.settings.withinLimits, isTrue, reason: c.name);
      }
    });
  });

  group('limits', () {
    test('AC-12.1: each end of each range is allowed', () {
      for (final s in [
        custom(stayTime: const Duration(minutes: 1)),
        custom(stayTime: const Duration(minutes: 30)),
        custom(stayMeters: 30),
        custom(stayMeters: 300),
        custom(vehicleKmh: 7),
        custom(vehicleKmh: 30),
        custom(walkingAfterRide: const Duration(seconds: 10)),
        custom(walkingAfterRide: const Duration(seconds: 120)),
      ]) {
        expect(s.withinLimits, isTrue);
      }
    });

    test('AC-12.2: just past each end is refused', () {
      for (final s in [
        custom(stayTime: const Duration(seconds: 59)),
        custom(stayTime: const Duration(minutes: 31)),
        custom(stayMeters: 29),
        custom(stayMeters: 301),
        custom(vehicleKmh: 6.9),
        custom(vehicleKmh: 30.1),
        custom(walkingAfterRide: const Duration(seconds: 9)),
        custom(walkingAfterRide: const Duration(seconds: 121)),
      ]) {
        expect(s.withinLimits, isFalse);
      }
    });
  });

  group('choice', () {
    test('Stay values matching a preset are that choice', () {
      for (final c in StayChoice.values) {
        expect(c.settings.choice, c);
      }
    });

    test('changed Ride values do not change the choice', () {
      expect(custom(vehicleKmh: 20).choice, StayChoice.normal);
    });

    test('AC-12.5: other Stay values are no choice', () {
      expect(custom(stayMeters: 120).choice, isNull);
      expect(custom(stayTime: const Duration(minutes: 7)).choice, isNull);
    });

    test('AC-12.5: picking a choice replaces only the Stay values', () {
      final s = custom(
        stayMeters: 200,
        vehicleKmh: 20,
        walkingAfterRide: const Duration(seconds: 60),
      ).withChoice(StayChoice.lessOften);
      expect(s.stayTime, const Duration(minutes: 10));
      expect(s.stayMeters, 100);
      expect(s.vehicleKmh, 20);
      expect(s.walkingAfterRide, const Duration(seconds: 60));
    });
  });

  group('exact choice', () {
    test('needs recommended Ride values too', () {
      expect(StayChoice.lessOften.settings.exactChoice, StayChoice.lessOften);
      expect(custom(vehicleKmh: 20).exactChoice, isNull);
      expect(
        custom(walkingAfterRide: const Duration(seconds: 60)).exactChoice,
        isNull,
      );
      expect(custom(stayMeters: 120).exactChoice, isNull);
    });
  });

  group('AC-12.3: risks', () {
    test('recommended values and presets have none', () {
      for (final c in StayChoice.values) {
        expect(c.settings.risks, isEmpty, reason: c.name);
      }
    });

    test('values at the thresholds have none', () {
      expect(
        custom(
          stayTime: const Duration(minutes: 15),
          stayMeters: 150,
          vehicleKmh: 20,
          walkingAfterRide: const Duration(seconds: 60),
        ).risks,
        isEmpty,
      );
    });

    test('each value over its threshold is named', () {
      expect(custom(stayTime: const Duration(minutes: 16)).risks, [
        DetectionValue.stayTime,
      ]);
      expect(custom(stayMeters: 151).risks, [DetectionValue.stayArea]);
      expect(custom(vehicleKmh: 20.5).risks, [DetectionValue.vehicleSpeed]);
      expect(custom(walkingAfterRide: const Duration(seconds: 61)).risks, [
        DetectionValue.walkingTime,
      ]);
    });
  });

  group('saved text', () {
    test('survives saving', () {
      final s = parseDetectionSettings(
        encodeDetectionSettings(
          custom(
            stayTime: const Duration(minutes: 20),
            stayMeters: 250,
            vehicleKmh: 12.5,
            walkingAfterRide: const Duration(seconds: 90),
          ),
        ),
      );
      expect(s.stayTime, const Duration(minutes: 20));
      expect(s.stayMeters, 250);
      expect(s.vehicleKmh, 12.5);
      expect(s.walkingAfterRide, const Duration(seconds: 90));
    });

    test('unreadable or out of limits falls back to Normal', () {
      for (final text in [
        'not json',
        '[]',
        '{}',
        '{"staySeconds":"a","stayMeters":75}',
        '{"staySeconds":300,"stayMeters":5000}',
        '{"staySeconds":300,"stayMeters":75,"vehicleKmh":500}',
      ]) {
        final s = parseDetectionSettings(text);
        expect(s.stayTime, DetectionSettings.normal.stayTime, reason: text);
        expect(s.stayMeters, 75, reason: text);
        expect(s.vehicleKmh, DetectionSettings.normal.vehicleKmh, reason: text);
      }
    });
  });

  group('custom values change outcomes', () {
    test('AC-12.5: a longer walking time delays the end of a Ride', () {
      List<DetectorEvent> ride(int checkAt) => [
        LocationFix(at(1), start, 10),
        ActivityChanged(at(2), ActivityKind.inVehicle, 90),
        ActivityChanged(at(10), ActivityKind.walking, 90),
        Tick(at(checkAt)),
      ];
      final slow = custom(walkingAfterRide: const Duration(seconds: 60));
      expect(decisions(DetectionSettings.normal, ride(40)), hasLength(1));
      expect(decisions(slow, ride(40)), isEmpty);
      expect(decisions(slow, ride(70)), hasLength(1));
    });

    test('AC-12.5: a shorter walking time ends a Ride sooner', () {
      final events = [
        LocationFix(at(1), start, 10),
        ActivityChanged(at(2), ActivityKind.inVehicle, 90),
        ActivityChanged(at(10), ActivityKind.walking, 90),
        Tick(at(20)),
      ];
      expect(decisions(DetectionSettings.normal, events), isEmpty);
      expect(
        decisions(
          custom(walkingAfterRide: const Duration(seconds: 10)),
          events,
        ),
        hasLength(1),
      );
    });

    test('AC-12.5: vehicle speed decides if a reading means still riding', () {
      // 100 m in 20 s is 18 km/h.
      final events = [
        ActivityChanged(at(1), ActivityKind.inVehicle, 90),
        LocationFix(at(10), start, 10),
        ActivityChanged(at(20), ActivityKind.walking, 90),
        LocationFix(at(30), north(100), 10),
        Tick(at(60)),
      ];
      expect(decisions(DetectionSettings.normal, events), isEmpty);
      expect(decisions(custom(vehicleKmh: 25), events), hasLength(1));
    });

    test('AC-12.5: custom Stay values apply to later Stays', () {
      final events = [
        LocationFix(at(1), start, 10),
        Tick(at(70)),
        LocationFix(at(80), north(40), 10),
        LocationFix(at(90), north(40), 10),
      ];
      expect(decisions(DetectionSettings.normal, events), isEmpty);
      expect(
        decisions(
          custom(stayTime: const Duration(minutes: 1), stayMeters: 30),
          events,
        ),
        hasLength(1),
      );
    });

    test('the Ride time limit is not a setting', () {
      final events = [
        LocationFix(at(1), start, 10),
        ActivityChanged(at(2), ActivityKind.inVehicle, 90),
        Tick(at(2).add(rideTimeLimit)),
      ];
      expect(
        decisions(
          custom(walkingAfterRide: const Duration(seconds: 120)),
          events,
        ),
        hasLength(1),
      );
    });
  });
}

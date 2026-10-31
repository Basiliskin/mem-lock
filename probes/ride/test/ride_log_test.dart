import 'package:flutter_test/flutter_test.dart';
import 'package:ride_probe/ride_log.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));

LogEntry start(int s, [String type = 'train']) =>
    LogEntry(at(s), 'ride_start', {'train': type});
LogEntry off(int s) => LogEntry(at(s), 'got_off', {});
LogEntry act(int s, String kind, [int conf = 90]) =>
    LogEntry(at(s), 'activity', {'kind': kind, 'confidence': conf});
LogEntry beat(int s) => LogEntry(at(s), 'heartbeat', {});

void main() {
  test('entries survive a round trip through a log line', () {
    final e = LogEntry(at(1), 'location', {'lat': 1.5, 'speed': 2.0});
    final back = LogEntry.parse(e.toLine());
    expect(back.time, e.time);
    expect(back.kind, 'location');
    expect(back.data, e.data);
  });

  test('parseLog skips a damaged line, such as a cut-off last line', () {
    final log = '${off(0).toLine()}\n{"time":"20';
    expect(parseLog(log), hasLength(1));
  });

  group('analyze', () {
    test('measures delay from got off to first confident walking', () {
      final r = analyze([
        start(0),
        act(10, 'IN_VEHICLE'),
        off(100),
        act(130, 'WALKING'),
      ]).rides.single;
      expect(r.delay, const Duration(seconds: 30));
      expect(r.sawVehicle, isTrue);
      expect(r.train, 'train');
    });

    test('ignores walking below the confidence bar', () {
      final r = analyze([
        start(0),
        off(100),
        act(110, 'WALKING', 40),
        act(150, 'ON_FOOT', 80),
      ]).rides.single;
      expect(r.delay, const Duration(seconds: 50));
    });

    test('a ride with no walking afterwards is not detected', () {
      final r = analyze([start(0), off(100), act(110, 'STILL')]).rides.single;
      expect(r.delay, isNull);
    });

    test('walking is not credited to a ride after the next one starts', () {
      final rides = analyze([
        start(0),
        off(100),
        start(200),
        act(210, 'WALKING'),
        off(300),
      ]).rides;
      expect(rides.first.delay, isNull);
      expect(rides.last.delay, isNull);
      expect(rides.last.walkingDuringRide, 1);
    });

    test('counts walking during a ride as a possible false Reminder', () {
      final r = analyze([
        start(0),
        act(10, 'WALKING'),
        act(20, 'IN_VEHICLE'),
        act(30, 'WALKING'),
        off(100),
      ]).rides.single;
      expect(r.walkingDuringRide, 2);
    });

    test('a ride with no got off tap is left out', () {
      expect(analyze([start(0), act(10, 'WALKING')]).rides, isEmpty);
    });

    test('reports the longest gap, which shows the app was paused', () {
      final a = analyze([beat(0), beat(30), beat(630), beat(660)]);
      expect(a.longestGap, const Duration(seconds: 600));
    });
  });

  group('FT-2 verdict', () {
    Analysis withRides(int fast, int slow) {
      final e = <LogEntry>[];
      var s = 0;
      for (var i = 0; i < fast + slow; i++) {
        e
          ..add(start(s))
          ..add(off(s + 100))
          ..add(act(s + 100 + (i < fast ? 60 : 61), 'WALKING'));
        s += 1000;
      }
      return analyze(e);
    }

    test('passes at 8 of 10 within exactly 60 seconds', () {
      expect(withRides(8, 2).verdict, Verdict.pass);
    });

    test('fails at 7 of 10', () {
      expect(withRides(7, 3).verdict, Verdict.fail);
    });

    test('is not enough data below 10 rides, however good', () {
      expect(withRides(9, 0).verdict, Verdict.notEnoughRides);
    });
  });

  test('report groups results by train type', () {
    final text = analyze([
      start(0, 'metro'),
      off(100),
      act(120, 'WALKING'),
      start(1000, 'bus'),
      off(1100),
    ]).report();
    expect(text, contains('metro: 1 of 1'));
    expect(text, contains('bus: 0 of 1'));
    expect(text, contains('not enough rides'));
  });
}

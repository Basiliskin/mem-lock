import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';
import 'package:leavecheck/domain/home_wifi.dart';

final t0 = DateTime.utc(2026, 11, 3, 9);
DateTime at(int s) => t0.add(Duration(seconds: s));
const homePoint = GeoPoint(32.08, 34.78);
const home = HomeWifi('Home', homePoint);

/// A metre of latitude is about 1/111000 of a degree.
GeoPoint north(double meters) =>
    GeoPoint(homePoint.lat + meters / 111000, homePoint.lng);

HomeEvent wifi(int s, String? n) => WifiChanged(at(s), n);
HomeEvent walk(int s, [int conf = 80]) =>
    Sensed(ActivityChanged(at(s), ActivityKind.walking, conf));
HomeEvent fix(int s, double meters, [double accuracy = 10]) =>
    Sensed(LocationFix(at(s), north(meters), accuracy));

/// Runs [events] from a state with [home] set, connected since 0 s.
(HomeState, List<Decision>) run(List<HomeEvent> events) {
  var s = homeStep(const HomeState(), HomeChanged(at(0), home)).$1;
  s = homeStep(s, wifi(0, 'Home')).$1;
  final all = <Decision>[];
  for (final e in events) {
    final (next, d) = homeStep(s, e);
    s = next;
    all.addAll(d);
  }
  return (s, all);
}

int reminders(List<Decision> d) => d.whereType<StartReminder>().length;

void main() {
  test('walking out as the home Wi-Fi drops gives one Reminder', () {
    final (s, d) = run([walk(600), wifi(610, null), walk(620)]);
    expect(reminders(d), 1);
    final r = d.whereType<StartReminder>().single;
    expect(r.source, ReminderSource.home);
    expect(r.lastPlace.point, homePoint);
    expect(r.lastPlace.time, at(610));
    expect(s.reminded, isTrue);
  });

  test('walking soon after the drop also reminds', () {
    expect(reminders(run([wifi(600, null), walk(700)]).$2), 1);
  });

  test('a router restart with nobody walking gives none', () {
    final (s, d) = run([wifi(600, null), wifi(700, 'Home')]);
    expect(reminders(d), 0);
    expect(s.droppedAt, isNull);
  });

  test('walking long after the drop is moving about the flat', () {
    expect(reminders(run([wifi(600, null), walk(600 + 121)]).$2), 0);
  });

  test('old walking before the drop does not count', () {
    expect(reminders(run([walk(500), wifi(600, null)]).$2), 0);
  });

  test('weak walking signals do not count', () {
    expect(reminders(run([wifi(600, null), walk(610, 40)]).$2), 0);
  });

  test('a short connection at the door does not arm it', () {
    var s = homeStep(const HomeState(), HomeChanged(at(0), home)).$1;
    s = homeStep(s, wifi(0, 'Home')).$1;
    final (_, d) = homeStep(s, wifi(30, null));
    expect(d, isEmpty);
  });

  test('another network counts as the home Wi-Fi lost', () {
    expect(reminders(run([walk(600), wifi(605, 'Cafe')]).$2), 1);
  });

  test('a far, accurate reading confirms leaving with no walking seen', () {
    final (_, d) = run([wifi(600, null), fix(900, 200)]);
    expect(reminders(d), 1);
  });

  test('a near or rough reading does not', () {
    expect(reminders(run([wifi(600, null), fix(900, 50)]).$2), 0);
    expect(reminders(run([wifi(600, null), fix(900, 200, 60)]).$2), 0);
  });

  test('only one Reminder per departure', () {
    final (_, d) = run([walk(600), wifi(605, null), walk(610), fix(900, 300)]);
    expect(reminders(d), 1);
  });

  test('coming back home stops repeats and arms again', () {
    final (s, d) = run([
      walk(600),
      wifi(605, null),
      wifi(3600, 'Home'),
      walk(7200),
      wifi(7205, null),
    ]);
    expect(d.whereType<StopRepeats>(), hasLength(1));
    expect(reminders(d), 2);
    expect(s.reminded, isTrue);
  });

  test('location is precise only while waiting, for a while', () {
    final (waiting, d) = run([wifi(600, null)]);
    expect(waiting.mode, LocationMode.precise);
    expect(d.whereType<SetLocationMode>().single.mode, LocationMode.precise);
    final (later, _) = homeStep(waiting, Sensed(Tick(at(600 + 601))));
    expect(later.mode, LocationMode.lowPower);
    final (reminded, _) = run([walk(600), wifi(605, null)]);
    expect(reminded.mode, LocationMode.lowPower);
  });

  test('nothing happens without a home Wi-Fi', () {
    var s = const HomeState();
    for (final e in [wifi(0, 'Home'), walk(600), wifi(605, null)]) {
      final (next, d) = homeStep(s, e);
      expect(d, isEmpty);
      s = next;
    }
  });

  test('the same home again keeps the departure; a new one starts over', () {
    final (s, _) = run([wifi(600, null)]);
    expect(homeStep(s, HomeChanged(at(610), home)).$1.droppedAt, at(600));
    final other = HomeWifi('Other', homePoint);
    expect(homeStep(s, HomeChanged(at(610), other)).$1.droppedAt, isNull);
  });

  test('state and home survive saving, and bad text starts fresh', () {
    final (s, _) = run([walk(600), wifi(605, null)]);
    final back = decodeHomeState(encodeHomeState(s));
    expect(encodeHomeState(back), encodeHomeState(s));
    expect(back.home, home);
    expect(decodeHomeState('{"bad'), isA<HomeState>());
    expect(decodeHomeState(null).home, isNull);
    expect(parseHome(encodeHome(home)), home);
    expect(parseHome('[]'), isNull);
  });
}

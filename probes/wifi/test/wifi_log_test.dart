import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_probe/wifi_log.dart';

final t0 = DateTime.utc(2026, 11, 3, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));

List<ApReading> scan(Map<String, int> m) => [
  for (final e in m.entries) ApReading(e.key, e.value),
];

LogEntry scanAt(int s, Map<String, int> m) => LogEntry(at(s), 'scan', {
  'aps': [for (final r in scan(m)) r.toJson()],
});

LogEntry added(int s, String id, Map<String, int> m) =>
    LogEntry(at(s), 'point_added', {
      'id': id,
      'name': id,
      'aps': [for (final r in scan(m)) r.toJson()],
    });

LogEntry here(int s, String id) => LogEntry(at(s), 'at_point', {'id': id});

const kitchen = {'a': -40, 'b': -60, 'c': -80};
const door = {'a': -75, 'b': -50, 'd': -55};

void main() {
  test('hidden ids are stable, salted and not the address', () {
    final id = hideAp('salt', 'AA:BB:CC:DD:EE:FF');
    expect(id, hideAp('salt', 'aa:bb:cc:dd:ee:ff'));
    expect(id, isNot(hideAp('other', 'aa:bb:cc:dd:ee:ff')));
    expect(id, isNot(contains(':')));
    expect(id, hasLength(12));
  });

  group('fingerprint', () {
    test('keeps the strongest 5, averaged, strongest first', () {
      final fp = fingerprintOf([
        scan({'a': -40, 'b': -50, 'c': -60, 'd': -70, 'e': -80, 'f': -90}),
        scan({'a': -42, 'b': -50, 'c': -60, 'd': -70, 'e': -80, 'f': -90}),
      ]);
      expect(fp.map((r) => r.ap), ['a', 'b', 'c', 'd', 'e']);
      expect(fp.first.rssi, -41);
    });

    test('drops access points heard in fewer than half the scans', () {
      final fp = fingerprintOf([
        scan({'a': -40, 'flash': -30}),
        scan({'a': -40}),
        scan({'a': -40}),
      ]);
      expect(fp.map((r) => r.ap), ['a']);
    });
  });

  group('distance', () {
    const p = WifiPoint('k', 'k', [ApReading('a', -40), ApReading('b', -60)]);

    test('is 0 for the same signals', () {
      expect(distanceTo(p, scan({'a': -40, 'b': -60})), 0);
    });

    test('a missing access point counts as not heard', () {
      expect(distanceTo(p, scan({'a': -40})), closeTo(28.28, 0.01));
    });

    test('nearest picks the most alike point', () {
      const q = WifiPoint('d', 'd', [ApReading('a', -75), ApReading('b', -50)]);
      expect(nearest([p, q], scan({'a': -45, 'b': -58}))!.$1.id, 'k');
      expect(nearest(const [], scan({'a': -45})), isNull);
    });
  });

  test('points replay additions and removals', () {
    final points = pointsIn([
      added(0, 'kitchen', kitchen),
      added(1, 'door', door),
      LogEntry(at(2), 'point_removed', {'id': 'kitchen'}),
    ]);
    expect(points.map((p) => p.id), ['door']);
  });

  group('analysis', () {
    test('a tap uses the first scan after it, not an older one', () {
      final a = analyzeWifi([
        added(0, 'kitchen', kitchen),
        added(1, 'door', door),
        scanAt(95, kitchen),
        here(100, 'door'),
        scanAt(125, door),
      ]);
      expect(a.correct, 1);
    });

    test('a scan finishing just before the tap still counts', () {
      final a = analyzeWifi([
        added(0, 'kitchen', kitchen),
        added(1, 'door', door),
        scanAt(103, kitchen),
        here(105, 'kitchen'),
        scanAt(200, kitchen),
        here(210, 'door'),
        scanAt(212, door),
      ]);
      expect(a.marks, hasLength(2));
      expect(a.correct, 2);
      expect(a.marks.first.ownDistance, 0);
      expect(a.marks.first.otherDistance, greaterThan(0));
      expect(a.report(), contains('2 of 2 matched'));
    });

    test('a wrong match is reported', () {
      final a = analyzeWifi([
        added(0, 'kitchen', kitchen),
        added(1, 'door', door),
        here(100, 'door'),
        scanAt(101, kitchen),
      ]);
      expect(a.correct, 0);
      expect(a.report(), contains('looked like kitchen'));
    });

    test('a tap with no scan nearby is reported, not guessed', () {
      final a = analyzeWifi([
        added(0, 'kitchen', kitchen),
        scanAt(100, kitchen),
        here(200, 'kitchen'),
      ]);
      expect(a.marks.single.found, isNull);
      expect(a.report(), contains('no scan within'));
    });

    test('counts refused scans and the time between scans', () {
      final a = analyzeWifi([
        scanAt(0, kitchen),
        LogEntry(at(5), 'scan_refused', {}),
        scanAt(30, kitchen),
        scanAt(90, kitchen),
      ]);
      expect(a.throttled, 1);
      expect(a.medianGap, const Duration(seconds: 60));
    });
  });

  test('the report holds no hidden ids', () {
    final a = analyzeWifi([
      added(0, 'kitchen', {'abc123def456': -40}),
    ]);
    expect(a.report(), isNot(contains('abc123def456')));
  });
}

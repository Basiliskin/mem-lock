import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';

/// Replays a recorded movement file through the Detector.
/// Each line: {"t":seconds,"lat":..,"lng":..,"acc":..} or {"t":seconds}, a Tick.
List<Decision> replay(String name) {
  final start = DateTime.utc(2026, 11, 1, 10);
  var state = DetectorState.initial();
  final out = <Decision>[];
  for (final line in File('test/fixtures/$name').readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final m = jsonDecode(line) as Map<String, dynamic>;
    final time = start.add(Duration(seconds: m['t'] as int));
    final DetectorEvent event = m.containsKey('lat')
        ? LocationFix(
            time,
            GeoPoint(m['lat'] as double, m['lng'] as double),
            (m['acc'] as num).toDouble(),
          )
        : Tick(time);
    final (next, decisions) = step(state, event);
    state = next;
    out.addAll(decisions.where((d) => d is! SetLocationMode));
  }
  return out;
}

void main() {
  test('cafe visit, then walking away: one Reminder', () {
    final d = replay('synthetic_cafe_then_walk.jsonl');
    expect(d.whereType<StartReminder>(), hasLength(1));
  });

  test('sitting indoors with a drifting signal: no Reminder', () {
    expect(replay('synthetic_indoor_drift.jsonl'), isEmpty);
  });

  test('short wait at a bus stop, then walking on: no Reminder', () {
    expect(replay('synthetic_short_stop.jsonl'), isEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';

ActivityKind kindOf(String s) => switch (s) {
  'IN_VEHICLE' => ActivityKind.inVehicle,
  'WALKING' || 'ON_FOOT' || 'RUNNING' => ActivityKind.walking,
  'STILL' => ActivityKind.still,
  _ => ActivityKind.unknown,
};

/// Replays a file in the S1 probe's log format through the Detector.
/// These rides are made up. They check the rules, not real-world detection.
({List<StartReminder> reminders, DateTime? gotOff, DateTime? reminderAt})
replay(String name) {
  var state = DetectorState.initial();
  final reminders = <StartReminder>[];
  DateTime? gotOff;
  DateTime? reminderAt;
  for (final line in File('test/fixtures/$name').readAsLinesSync()) {
    final m = jsonDecode(line) as Map<String, dynamic>;
    final time = DateTime.parse(m['time'] as String);
    final data = m['data'] as Map<String, dynamic>;
    final DetectorEvent? event = switch (m['kind']) {
      'location' => LocationFix(
        time,
        GeoPoint(data['lat'] as double, data['lng'] as double),
        (data['accuracy'] as num).toDouble(),
      ),
      'activity' => ActivityChanged(
        time,
        kindOf(data['kind'] as String),
        data['confidence'] as int,
      ),
      'heartbeat' => Tick(time),
      _ => null,
    };
    if (m['kind'] == 'got_off') gotOff = time;
    if (event == null) continue;
    final (next, decisions) = step(state, event);
    state = next;
    final started = decisions.whereType<StartReminder>();
    if (started.isNotEmpty) reminderAt ??= time;
    reminders.addAll(started);
  }
  return (reminders: reminders, gotOff: gotOff, reminderAt: reminderAt);
}

void main() {
  test('AC-2.1: getting off gives one Reminder within 60 seconds', () {
    final r = replay('synthetic_ride_get_off.jsonl');
    expect(r.reminders.single.source, ReminderSource.ride);
    expect(
      r.reminderAt!.difference(r.gotOff!),
      lessThanOrEqualTo(const Duration(seconds: 60)),
    );
  });

  test('AC-2.2: staying seated at a station gives no Reminder', () {
    expect(replay('synthetic_ride_station_stop.jsonl').reminders, isEmpty);
  });

  test('AC-2.3: walking along the vehicle gives no Reminder', () {
    expect(replay('synthetic_ride_walk_along.jsonl').reminders, isEmpty);
  });
}

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/adapters/plugin_activity.dart';
import 'package:leavecheck/domain/detector.dart';

void main() {
  test('every plugin type maps to the expected kind', () {
    const expected = {
      ActivityType.IN_VEHICLE: ActivityKind.inVehicle,
      ActivityType.WALKING: ActivityKind.walking,
      ActivityType.ON_FOOT: ActivityKind.walking,
      ActivityType.RUNNING: ActivityKind.walking,
      ActivityType.STILL: ActivityKind.still,
      ActivityType.ON_BICYCLE: ActivityKind.unknown,
      ActivityType.TILTING: ActivityKind.unknown,
      ActivityType.UNKNOWN: ActivityKind.unknown,
    };
    expect(expected.keys, containsAll(ActivityType.values));
    final time = DateTime.utc(2026, 11, 1);
    expected.forEach((type, kind) {
      final change = toActivityChanged(ActivityEvent(type, 80, time));
      expect(change.kind, kind);
      expect(change.confidence, 80);
      expect(change.time, time);
    });
  });
}

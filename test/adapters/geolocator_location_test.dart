import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/adapters/geolocator_location.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:geolocator/geolocator.dart';

Position position(double latitude) => Position(
  longitude: 30,
  latitude: latitude,
  timestamp: DateTime.utc(2026, 11, 1),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class OpenedStream {
  OpenedStream(this.settings) {
    controller = StreamController<Position>(onCancel: () => cancelled = true);
  }

  final AndroidSettings settings;
  late final StreamController<Position> controller;
  bool cancelled = false;
}

void main() {
  late List<OpenedStream> opened;
  late GeolocatorLocation location;
  late List<LocationFix> fixes;
  late List<Object> errors;
  late StreamSubscription<LocationFix> subscription;

  setUp(() {
    opened = [];
    fixes = [];
    errors = [];
    location = GeolocatorLocation(
      openStream: (settings) {
        final stream = OpenedStream(settings);
        opened.add(stream);
        return stream.controller.stream;
      },
    );
    subscription = location.fixes.listen(fixes.add, onError: errors.add);
  });

  tearDown(() => subscription.cancel());

  test('starts on fused location and passes on its fixes', () async {
    await location.setMode(LocationMode.precise);

    opened.single.controller.add(position(60));
    await pumpEventQueue();

    expect(opened.single.settings.forceLocationManager, isFalse);
    expect(fixes.single.point.lat, 60);
    expect(errors, isEmpty);
  });

  test(
    'moves to LocationManager without reporting a failed fused start',
    () async {
      await location.setMode(LocationMode.precise);

      opened.first.controller.addError(
        const LocationServiceDisabledException(),
      );
      await pumpEventQueue();

      expect(opened, hasLength(2));
      expect(opened.first.cancelled, isTrue);
      expect(opened.last.settings.forceLocationManager, isTrue);
      expect(opened.last.settings.accuracy, LocationAccuracy.high);
      expect(errors, isEmpty);

      opened.last.controller.add(position(61));
      await pumpEventQueue();
      expect(fixes.single.point.lat, 61);
    },
  );

  test('reports the error when LocationManager fails too', () async {
    await location.setMode(LocationMode.precise);
    opened.first.controller.addError(const LocationServiceDisabledException());
    await pumpEventQueue();

    opened.last.controller.addError(const LocationServiceDisabledException());
    await pumpEventQueue();

    expect(opened, hasLength(2));
    expect(errors.single, isA<LocationServiceDisabledException>());
  });

  test('keeps LocationManager for later mode changes and retries', () async {
    await location.setMode(LocationMode.precise);
    opened.first.controller.addError(const LocationServiceDisabledException());
    await pumpEventQueue();

    await location.setMode(LocationMode.lowPower);
    await location.setMode(LocationMode.lowPower);

    expect(opened, hasLength(4));
    expect(opened[2].settings.forceLocationManager, isTrue);
    expect(opened[2].settings.accuracy, LocationAccuracy.medium);
    expect(opened[2].cancelled, isTrue);
    expect(opened[3].settings.forceLocationManager, isTrue);
  });

  test('a fallback keeps the mode set most recently', () async {
    await location.setMode(LocationMode.lowPower);

    opened.first.controller.addError(const LocationServiceDisabledException());
    await pumpEventQueue();

    expect(opened.last.settings.forceLocationManager, isTrue);
    expect(opened.last.settings.accuracy, LocationAccuracy.medium);
  });

  test(
    'other errors are reported and do not change the location client',
    () async {
      await location.setMode(LocationMode.precise);

      opened.first.controller.addError(
        const PermissionDeniedException('denied'),
      );
      await pumpEventQueue();

      expect(opened, hasLength(1));
      expect(errors.single, isA<PermissionDeniedException>());
    },
  );

  test('mode changes at the same moment leave only one stream open', () async {
    await Future.wait([
      location.setMode(LocationMode.precise),
      location.setMode(LocationMode.lowPower),
    ]);

    expect(opened, hasLength(2));
    expect(opened.first.cancelled, isTrue);
    expect(opened.last.cancelled, isFalse);
    expect(opened.last.settings.accuracy, LocationAccuracy.medium);
  });
}

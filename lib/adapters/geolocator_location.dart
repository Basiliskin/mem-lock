import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/detector.dart';
import '../domain/geo.dart';
import '../ports/ports.dart';

class GeolocatorLocation implements LocationSource {
  final _controller = StreamController<LocationFix>.broadcast();
  StreamSubscription<Position>? _subscription;

  @override
  Stream<LocationFix> get fixes => _controller.stream;

  @override
  Future<void> setMode(LocationMode mode) async {
    await _subscription?.cancel();
    _subscription =
        Geolocator.getPositionStream(locationSettings: _settings(mode)).listen(
          (p) => _controller.add(
            LocationFix(
              p.timestamp,
              GeoPoint(p.latitude, p.longitude),
              p.accuracy,
            ),
          ),
          onError: _controller.addError,
        );
  }

  AndroidSettings _settings(LocationMode mode) => switch (mode) {
    LocationMode.precise => AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 5),
    ),
    LocationMode.lowPower => AndroidSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 30),
    ),
  };
}

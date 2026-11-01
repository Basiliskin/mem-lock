import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/detector.dart';
import '../domain/geo.dart';
import '../ports/ports.dart';

class GeolocatorLocation implements LocationSource, CurrentFixSource {
  GeolocatorLocation({
    Stream<Position> Function(AndroidSettings settings)? openStream,
  }) : _openStream =
           openStream ??
           ((settings) =>
               Geolocator.getPositionStream(locationSettings: settings));

  static const _fixTimeLimit = Duration(seconds: 20);

  final Stream<Position> Function(AndroidSettings settings) _openStream;
  final _controller = StreamController<LocationFix>.broadcast();
  StreamSubscription<Position>? _subscription;
  Future<void> _restarts = Future.value();
  LocationMode _mode = LocationMode.precise;
  bool _useLocationManager = false;

  @override
  Stream<LocationFix> get fixes => _controller.stream;

  /// Always a new reading, never the last known one: a Quiet Place must be
  /// where the Helper is standing now.
  @override
  Future<LocationFix?> currentFix() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeLimit,
        ),
      );
      return LocationFix(
        p.timestamp,
        GeoPoint(p.latitude, p.longitude),
        p.accuracy,
      );
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> setMode(LocationMode mode) {
    _mode = mode;
    return _restart();
  }

  /// One at a time, so that overlapping restarts can't leave two streams open.
  Future<void> _restart() => _restarts = _restarts.then((_) async {
    try {
      await _subscription?.cancel();
      _subscription = _openStream(_settings()).listen(
        (p) => _controller.add(
          LocationFix(
            p.timestamp,
            GeoPoint(p.latitude, p.longitude),
            p.accuracy,
          ),
        ),
        onError: _onStreamError,
      );
    } on Object catch (e) {
      _controller.addError(e);
    }
  });

  /// In the service there is no activity to answer fused location's settings
  /// check, so it can report location as off when it is on. LocationManager
  /// has no such check, and reports this error only when location really is
  /// off. It is kept until the service restarts.
  void _onStreamError(Object error) {
    if (error is LocationServiceDisabledException && !_useLocationManager) {
      _useLocationManager = true;
      unawaited(_restart());
      return;
    }
    _controller.addError(error);
  }

  AndroidSettings _settings() => switch (_mode) {
    LocationMode.precise => AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 5),
      forceLocationManager: _useLocationManager,
    ),
    LocationMode.lowPower => AndroidSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 30),
      forceLocationManager: _useLocationManager,
    ),
  };
}

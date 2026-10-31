import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

Map<String, dynamic> _point(GeoPoint p) => {'lat': p.lat, 'lng': p.lng};

GeoPoint _readPoint(Object? value) {
  final m = value as Map<String, dynamic>;
  return GeoPoint((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
}

String encodeState(DetectorState s) => jsonEncode({
  'phase': switch (s.phase) {
    Roaming(:final anchor, :final since) => {
      'type': 'roaming',
      'anchor': anchor == null ? null : _point(anchor),
      'since': since?.toUtc().toIso8601String(),
    },
    InStay(:final center, :final meters, :final outsideReadings) => {
      'type': 'inStay',
      'center': _point(center),
      'meters': meters,
      'outside': outsideReadings,
    },
  },
  'staySeconds': s.settings.stayTime.inSeconds,
  'stayMeters': s.settings.stayMeters,
  'quiet': [
    for (final q in s.quietPlaces) {'id': q.id, 'point': _point(q.point)},
  ],
  'returnTo': s.returnTo == null ? null : _point(s.returnTo!),
  'mode': s.locationMode.name,
});

/// Throws [FormatException] when the text can't be read as a saved state.
DetectorState decodeState(String text) {
  try {
    final m = jsonDecode(text) as Map<String, dynamic>;
    final phase = m['phase'] as Map<String, dynamic>;
    return DetectorState(
      phase: switch (phase['type']) {
        'roaming' => Roaming(
          anchor: phase['anchor'] == null ? null : _readPoint(phase['anchor']),
          since: phase['since'] == null
              ? null
              : DateTime.parse(phase['since'] as String),
        ),
        'inStay' => InStay(
          _readPoint(phase['center']),
          // States saved by older versions don't have it.
          ((phase['meters'] ?? m['stayMeters']) as num).toDouble(),
          outsideReadings: phase['outside'] as int,
        ),
        _ => throw const FormatException('Unknown phase'),
      },
      settings: StaySettings(
        stayTime: Duration(seconds: m['staySeconds'] as int),
        stayMeters: (m['stayMeters'] as num).toDouble(),
      ),
      quietPlaces: [
        for (final q in m['quiet'] as List<dynamic>)
          QuietPlace(
            (q as Map<String, dynamic>)['id'] as String,
            _readPoint(q['point']),
          ),
      ],
      returnTo: m['returnTo'] == null ? null : _readPoint(m['returnTo']),
      locationMode: LocationMode.values.byName(m['mode'] as String),
    );
  } on FormatException {
    rethrow;
  } on TypeError catch (e) {
    throw FormatException('Bad saved state: $e');
  } on ArgumentError catch (e) {
    throw FormatException('Bad saved state: $e');
  }
}

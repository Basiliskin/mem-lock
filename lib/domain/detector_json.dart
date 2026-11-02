import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

Map<String, dynamic> _point(GeoPoint p) => {'lat': p.lat, 'lng': p.lng};

GeoPoint _readPoint(Object? value) {
  final m = value as Map<String, dynamic>;
  return GeoPoint((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
}

PlaceVisit? _readVisit(Object? value) {
  if (value == null) return null;
  final m = value as Map<String, dynamic>;
  final firstOutsideAt = m['firstOutsideAt'] as String?;
  return PlaceVisit(
    placeId: m['placeId'] as String,
    since: DateTime.parse(m['since'] as String),
    outsideReadings: m['outside'] as int,
    firstOutsideAt: firstOutsideAt == null
        ? null
        : DateTime.parse(firstOutsideAt),
  );
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
    OnRide() && final r => {
      'type': 'onRide',
      'movingAt': r.movingAt.toUtc().toIso8601String(),
      'lastPoint': r.lastPoint == null ? null : _point(r.lastPoint!),
      'lastFixAt': r.lastFixAt?.toUtc().toIso8601String(),
      'walkingSince': r.walkingSince?.toUtc().toIso8601String(),
      'gotOffPoint': r.gotOffPoint == null ? null : _point(r.gotOffPoint!),
    },
  },
  ...s.settings.toMap(),
  'quiet': [
    for (final q in s.quietPlaces) {'id': q.id, 'point': _point(q.point)},
  ],
  'reminderPlaces': [
    for (final p in s.reminderPlaces)
      {'id': p.id, 'point': _point(p.point), 'message': p.message},
  ],
  'visit': switch (s.visit) {
    null => null,
    final v => {
      'placeId': v.placeId,
      'since': v.since.toUtc().toIso8601String(),
      'outside': v.outsideReadings,
      'firstOutsideAt': v.firstOutsideAt?.toUtc().toIso8601String(),
    },
  },
  'returnTo': s.returnTo == null ? null : _point(s.returnTo!),
  'returnMeters': s.returnMeters,
  'walkingSince': s.walkingSince?.toUtc().toIso8601String(),
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
        'onRide' => OnRide(
          movingAt: DateTime.parse(phase['movingAt'] as String),
          lastPoint: phase['lastPoint'] == null
              ? null
              : _readPoint(phase['lastPoint']),
          lastFixAt: phase['lastFixAt'] == null
              ? null
              : DateTime.parse(phase['lastFixAt'] as String),
          walkingSince: phase['walkingSince'] == null
              ? null
              : DateTime.parse(phase['walkingSince'] as String),
          gotOffPoint: phase['gotOffPoint'] == null
              ? null
              : _readPoint(phase['gotOffPoint']),
        ),
        _ => throw const FormatException('Unknown phase'),
      },
      settings: DetectionSettings.fromMap(m),
      quietPlaces: [
        for (final q in m['quiet'] as List<dynamic>)
          QuietPlace(
            (q as Map<String, dynamic>)['id'] as String,
            _readPoint(q['point']),
          ),
      ],
      // States saved by older versions don't have these.
      reminderPlaces: [
        for (final p in (m['reminderPlaces'] ?? const []) as List<dynamic>)
          ReminderPlace(
            (p as Map<String, dynamic>)['id'] as String,
            _readPoint(p['point']),
            p['message'] as String,
          ),
      ],
      visit: _readVisit(m['visit']),
      returnTo: m['returnTo'] == null ? null : _readPoint(m['returnTo']),
      // States saved by older versions don't have these.
      returnMeters: (m['returnMeters'] as num?)?.toDouble(),
      walkingSince: m['walkingSince'] == null
          ? null
          : DateTime.parse(m['walkingSince'] as String),
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

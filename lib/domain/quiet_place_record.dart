import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

/// A saved Quiet Place, with when it was marked so the Helper can tell places
/// apart. The Detector only needs [place].
class QuietPlaceRecord {
  const QuietPlaceRecord(this.place, this.markedAt);

  final QuietPlace place;
  final DateTime markedAt;
}

String encodeQuietPlaces(List<QuietPlaceRecord> places) => jsonEncode([
  for (final r in places)
    {
      'id': r.place.id,
      'lat': r.place.point.lat,
      'lng': r.place.point.lng,
      'markedAt': r.markedAt.millisecondsSinceEpoch,
    },
]);

/// Unreadable text gives an empty list: an unwanted Reminder is the safer
/// mistake, because a missed bag is the worse one.
List<QuietPlaceRecord> parseQuietPlaces(String? text) {
  if (text == null) return const [];
  try {
    return [
      for (final m in jsonDecode(text) as List<dynamic>)
        QuietPlaceRecord(
          QuietPlace(
            (m as Map<String, dynamic>)['id'] as String,
            GeoPoint(
              (m['lat'] as num).toDouble(),
              (m['lng'] as num).toDouble(),
            ),
          ),
          DateTime.fromMillisecondsSinceEpoch(m['markedAt'] as int),
        ),
    ];
  } on FormatException {
    return const [];
  } on TypeError {
    return const [];
  }
}

/// Whether a point already counts as being at one of these places.
bool coversPoint(List<QuietPlaceRecord> places, GeoPoint point) =>
    places.any((r) => r.place.point.distanceTo(point) <= quietPlaceMeters);

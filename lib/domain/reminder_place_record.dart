import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

/// A saved Reminder Place, with the name the Helper knows it by. The Detector
/// only needs [place].
class ReminderPlaceRecord {
  const ReminderPlaceRecord(this.place, this.name);

  final ReminderPlace place;
  final String name;
}

String encodeReminderPlaces(List<ReminderPlaceRecord> places) => jsonEncode([
  for (final r in places)
    {
      'id': r.place.id,
      'lat': r.place.point.lat,
      'lng': r.place.point.lng,
      'name': r.name,
      'message': r.place.message,
    },
]);

/// Unreadable text gives an empty list, so watching carries on.
List<ReminderPlaceRecord> parseReminderPlaces(String? text) {
  if (text == null) return const [];
  try {
    return [
      for (final m in jsonDecode(text) as List<dynamic>)
        ReminderPlaceRecord(
          ReminderPlace(
            (m as Map<String, dynamic>)['id'] as String,
            GeoPoint(
              (m['lat'] as num).toDouble(),
              (m['lng'] as num).toDouble(),
            ),
            m['message'] as String,
          ),
          m['name'] as String,
        ),
    ];
  } on FormatException {
    return const [];
  } on TypeError {
    return const [];
  }
}

/// Whether a point already counts as this Reminder Place.
bool coversReminderPoint(List<ReminderPlaceRecord> places, GeoPoint point) =>
    places.any((r) => r.place.point.distanceTo(point) <= reminderPlaceMeters);

/// Those close enough to [point] that a Quiet Place there would silence them.
/// The same distance the Detector uses, so the screens and it can't disagree.
List<ReminderPlaceRecord> reminderPlacesClashing(
  List<ReminderPlaceRecord> places,
  GeoPoint point,
) => [
  for (final r in places)
    if (r.place.point.distanceTo(point) <= quietPlaceMeters) r,
];

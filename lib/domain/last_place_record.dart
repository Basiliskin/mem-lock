import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

/// How many Last Places are kept.
const lastPlacesKept = 2;

/// [places] newest first, with [newest] added and any beyond the limit deleted.
List<LastPlaceRecord> withNewest(
  List<LastPlaceRecord> places,
  LastPlaceRecord newest,
) => [newest, ...places].take(lastPlacesKept).toList();

String encodeLastPlaces(List<LastPlaceRecord> places) =>
    '[${places.map((p) => p.encode()).join(',')}]';

/// Also reads a single place, the form saved by older versions. Gives an empty
/// list when the text can't be read.
List<LastPlaceRecord> parseLastPlaces(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  return [
    for (final item in decoded is List ? decoded : [decoded])
      ?LastPlaceRecord.parse(jsonEncode(item)),
  ];
}

/// A saved Last Place, with what ended there.
class LastPlaceRecord {
  const LastPlaceRecord(this.point, this.time, this.source);

  /// Returns null when the text can't be read.
  static LastPlaceRecord? parse(String text) {
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return LastPlaceRecord(
        GeoPoint((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
        DateTime.fromMillisecondsSinceEpoch(m['time'] as int),
        ReminderSource.values.byName(m['source'] as String),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  final GeoPoint point;
  final DateTime time;
  final ReminderSource source;

  String encode() => jsonEncode({
    'lat': point.lat,
    'lng': point.lng,
    'time': time.millisecondsSinceEpoch,
    'source': source.name,
  });
}

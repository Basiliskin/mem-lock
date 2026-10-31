import 'dart:convert';

import 'detector.dart';
import 'geo.dart';

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

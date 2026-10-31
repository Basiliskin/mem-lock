import 'dart:math';

const _earthRadiusMeters = 6371000.0;

double _radians(double degrees) => degrees * pi / 180;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Great-circle distance in metres.
  double distanceTo(GeoPoint other) {
    final dLat = _radians(other.lat - lat);
    final dLng = _radians(other.lng - lng);
    final a =
        pow(sin(dLat / 2), 2) +
        cos(_radians(lat)) * cos(_radians(other.lat)) * pow(sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * asin(sqrt(a));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

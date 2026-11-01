import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';
import 'package:leavecheck/domain/quiet_place_record.dart';

void main() {
  const home = GeoPoint(55.75, 37.61);
  final record = QuietPlaceRecord(
    const QuietPlace('a', home),
    DateTime.utc(2026, 11, 1, 10),
  );

  test('a list survives encoding', () {
    final back = parseQuietPlaces(encodeQuietPlaces([record])).single;
    expect(back.place.id, 'a');
    expect(back.place.point.lat, home.lat);
    expect(back.place.point.lng, home.lng);
    expect(back.markedAt.isAtSameMomentAs(record.markedAt), isTrue);
  });

  test('nothing saved or unreadable text gives an empty list', () {
    expect(parseQuietPlaces(null), isEmpty);
    expect(parseQuietPlaces('garbage'), isEmpty);
    expect(parseQuietPlaces('[{"id":1}]'), isEmpty);
    expect(parseQuietPlaces('{}'), isEmpty);
  });

  test('coversPoint uses the same distance as the Detector', () {
    GeoPoint north(double m) => GeoPoint(home.lat + m / 111195, home.lng);
    expect(coversPoint([record], north(quietPlaceMeters - 5)), isTrue);
    expect(coversPoint([record], north(quietPlaceMeters + 5)), isFalse);
    expect(coversPoint([], home), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/reminder_place_record.dart';

const pool = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(pool.lat + m / 111195, pool.lng);
const record = ReminderPlaceRecord(
  ReminderPlace('p', pool, 'Возьмите полотенце'),
  'Бассейн',
);

void main() {
  test('survives saving', () {
    final back = parseReminderPlaces(encodeReminderPlaces([record])).single;
    expect(back.name, 'Бассейн');
    expect(back.place.id, 'p');
    expect(back.place.message, 'Возьмите полотенце');
    expect(back.place.point, pool);
  });

  test('unreadable or missing text gives none', () {
    for (final text in [null, 'not json', '{}', '[{"id":"p"}]']) {
      expect(parseReminderPlaces(text), isEmpty, reason: text);
    }
  });

  test('covering uses the 75 m area', () {
    expect(coversReminderPoint([record], north(70)), isTrue);
    expect(coversReminderPoint([record], north(80)), isFalse);
  });

  test('clashing uses the Quiet Place distance', () {
    expect(reminderPlacesClashing([record], north(95)), hasLength(1));
    expect(reminderPlacesClashing([record], north(105)), isEmpty);
  });
}

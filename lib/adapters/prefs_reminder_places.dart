import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_place_record.dart';
import '../ports/ports.dart';

/// The Helper's list. Only the screens write it; the service only reads it.
class PrefsReminderPlaces implements ReminderPlaceStore {
  static const _key = 'reminder_places';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<List<ReminderPlaceRecord>> read() async =>
      parseReminderPlaces(await _prefs.getString(_key));

  @override
  Future<void> write(List<ReminderPlaceRecord> places) =>
      _prefs.setString(_key, encodeReminderPlaces(places));
}

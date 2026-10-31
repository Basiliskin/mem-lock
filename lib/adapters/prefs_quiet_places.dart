import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quiet_place_record.dart';
import '../ports/ports.dart';

/// The Helper's list. Only the screens write it; the service only reads it.
class PrefsQuietPlaces implements QuietPlaceStore {
  static const _key = 'quiet_places';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<List<QuietPlaceRecord>> read() async =>
      parseQuietPlaces(await _prefs.getString(_key));

  @override
  Future<void> write(List<QuietPlaceRecord> places) =>
      _prefs.setString(_key, encodeQuietPlaces(places));
}

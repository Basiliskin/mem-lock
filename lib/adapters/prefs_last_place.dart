import 'package:shared_preferences/shared_preferences.dart';

import '../domain/last_place_record.dart';
import '../ports/ports.dart';

/// Keeps the most recent Last Places, on the phone only.
class PrefsLastPlace implements LastPlaceStore {
  static const _key = 'last_place';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<List<LastPlaceRecord>> read() async {
    final text = await _prefs.getString(_key);
    return text == null ? const [] : parseLastPlaces(text);
  }

  @override
  Future<void> save(LastPlaceRecord value) async {
    final List<LastPlaceRecord> kept;
    try {
      kept = await read();
    } on Object {
      // The new place matters more than the older one.
      return _prefs.setString(_key, encodeLastPlaces([value]));
    }
    await _prefs.setString(_key, encodeLastPlaces(withNewest(kept, value)));
  }
}

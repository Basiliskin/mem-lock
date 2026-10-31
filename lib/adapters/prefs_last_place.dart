import 'package:shared_preferences/shared_preferences.dart';

import '../domain/last_place_record.dart';
import '../ports/ports.dart';

/// Keeps only the most recent Last Place, on the phone only.
class PrefsLastPlace implements LastPlaceStore {
  static const _key = 'last_place';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<LastPlaceRecord?> read() async {
    final text = await _prefs.getString(_key);
    return text == null ? null : LastPlaceRecord.parse(text);
  }

  @override
  Future<void> save(LastPlaceRecord value) =>
      _prefs.setString(_key, value.encode());
}

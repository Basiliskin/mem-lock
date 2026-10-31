import 'package:shared_preferences/shared_preferences.dart';

import '../ports/ports.dart';

/// Uses the uncached API, because the service and screens run in separate
/// isolates and a cache could go stale.
class PrefsStateStore implements StateStore {
  static const _key = 'detector_state';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(_key);

  @override
  Future<void> write(String value) => _prefs.setString(_key, value);
}

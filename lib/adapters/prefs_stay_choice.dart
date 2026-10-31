import 'package:shared_preferences/shared_preferences.dart';

import '../domain/detector.dart';
import '../ports/ports.dart';

class PrefsStayChoice implements StayChoiceStore {
  static const _key = 'stay_choice';
  final _prefs = SharedPreferencesAsync();

  /// Normal when nothing was picked or the saved text is unknown.
  @override
  Future<StayChoice> read() async {
    final name = await _prefs.getString(_key);
    return StayChoice.values.asNameMap()[name] ?? StayChoice.normal;
  }

  @override
  Future<void> write(StayChoice value) => _prefs.setString(_key, value.name);
}

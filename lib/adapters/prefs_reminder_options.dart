import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_options.dart';
import '../ports/ports.dart';

class PrefsReminderOptions implements ReminderOptionsStore {
  static const _key = 'reminder_options';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<ReminderOptions> read() async {
    final text = await _prefs.getString(_key);
    return text == null ? const ReminderOptions() : ReminderOptions.parse(text);
  }
}

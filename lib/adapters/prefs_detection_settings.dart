import 'package:shared_preferences/shared_preferences.dart';

import '../domain/detection_settings.dart';
import '../ports/ports.dart';

class PrefsDetectionSettings implements DetectionSettingsStore {
  static const _key = 'detection_settings';

  /// Written by versions before advanced settings. Only used until the first
  /// save under [_key]. Not migrated on read, because the screens and the
  /// service read from separate isolates.
  static const _oldChoiceKey = 'stay_choice';

  final _prefs = SharedPreferencesAsync();

  @override
  Future<DetectionSettings> read() async {
    final text = await _prefs.getString(_key);
    if (text != null) return parseDetectionSettings(text);
    final old = await _prefs.getString(_oldChoiceKey);
    return (StayChoice.values.asNameMap()[old] ?? StayChoice.normal).settings;
  }

  @override
  Future<void> write(DetectionSettings value) =>
      _prefs.setString(_key, encodeDetectionSettings(value));
}

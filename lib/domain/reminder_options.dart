import 'dart:convert';

/// What a Reminder does when the phone is on silent.
enum SilentChoice { aloud, vibrate }

class ReminderOptions {
  const ReminderOptions({
    this.silent = SilentChoice.aloud,
    this.customSoundPath,
  });

  /// Unreadable text gives the defaults, so a Reminder always works.
  factory ReminderOptions.parse(String text) {
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return ReminderOptions(
        silent: SilentChoice.values.byName(m['silent'] as String),
        customSoundPath: m['sound'] as String?,
      );
    } on FormatException {
      return const ReminderOptions();
    } on TypeError {
      return const ReminderOptions();
    } on ArgumentError {
      return const ReminderOptions();
    }
  }

  final SilentChoice silent;
  final String? customSoundPath;

  String encode() =>
      jsonEncode({'silent': silent.name, 'sound': customSoundPath});
}

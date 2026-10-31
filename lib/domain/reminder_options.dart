import 'dart:convert';

/// What a Reminder does when the phone is on silent.
enum SilentChoice { aloud, vibrate }

/// The sounds built into the app. [rising] is the default.
enum ReminderTone { rising, bell, pulse }

enum VibrationChoice { off, normal, strong }

class ReminderOptions {
  const ReminderOptions({
    this.silent = SilentChoice.aloud,
    this.voicePath,
    this.tone = ReminderTone.rising,
    this.vibration = VibrationChoice.normal,
    this.title,
    this.body,
  });

  /// Unreadable text gives the defaults, so a Reminder always works.
  factory ReminderOptions.parse(String text) {
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return ReminderOptions(
        silent: SilentChoice.values.byName(m['silent'] as String),
        voicePath: m['sound'] as String?,
        tone: ReminderTone.values.byName(
          m['tone'] as String? ?? ReminderTone.rising.name,
        ),
        vibration: VibrationChoice.values.byName(
          m['vibration'] as String? ?? VibrationChoice.normal.name,
        ),
        title: m['title'] as String?,
        body: m['body'] as String?,
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

  /// A recording by the Helper. When set, it plays instead of [tone].
  final String? voicePath;
  final ReminderTone tone;
  final VibrationChoice vibration;

  /// Null means the default Russian wording.
  final String? title;
  final String? body;

  /// Nullable fields take a function, so that null can mean "clear it". Blank
  /// text counts as not set.
  ReminderOptions copyWith({
    SilentChoice? silent,
    String? Function()? voicePath,
    ReminderTone? tone,
    VibrationChoice? vibration,
    String? Function()? title,
    String? Function()? body,
  }) => ReminderOptions(
    silent: silent ?? this.silent,
    voicePath: voicePath == null ? this.voicePath : voicePath(),
    tone: tone ?? this.tone,
    vibration: vibration ?? this.vibration,
    title: title == null ? this.title : _clean(title()),
    body: body == null ? this.body : _clean(body()),
  );

  static String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  String encode() => jsonEncode({
    'silent': silent.name,
    'sound': voicePath,
    'tone': tone.name,
    'vibration': vibration.name,
    'title': title,
    'body': body,
  });
}

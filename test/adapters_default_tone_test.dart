import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/adapters/default_tone.dart';
import 'package:leavecheck/domain/reminder_options.dart';

void main() {
  test('every tone is a valid WAV, and they differ', () {
    final all = [for (final t in ReminderTone.values) toneWav(t)];
    for (final w in all) {
      expect(String.fromCharCodes(w.sublist(0, 4)), 'RIFF');
      expect(w.length, greaterThan(1000));
    }
    expect(all.map((w) => w.length).toSet().length, greaterThan(1));
  });
}

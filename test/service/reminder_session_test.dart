import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/reminder_options.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/service/reminder_session.dart';

class FakeOutput implements ReminderOutput {
  final events = <String>[];
  final failingSounds = <String?>{};
  bool failShow = false;

  @override
  Future<void> show({required bool alert}) async {
    events.add(alert ? 'show' : 'rest');
    if (failShow) throw StateError('notifications');
  }

  @override
  Future<void> play(String? customPath, SilentChoice silent) async {
    if (failingSounds.contains(customPath)) throw StateError('sound');
    events.add('play ${customPath ?? 'default'} ${silent.name}');
  }

  @override
  Future<void> stopSound() async => events.add('stopSound');

  @override
  Future<void> cancel() async => events.add('cancel');
}

class FakeOptions implements ReminderOptionsStore {
  FakeOptions([this.options = const ReminderOptions()]);
  ReminderOptions options;
  bool fail = false;
  @override
  Future<ReminderOptions> read() async {
    if (fail) throw StateError('disk');
    return options;
  }
}

final reminder = StartReminder(
  ReminderSource.stay,
  LastPlace(const GeoPoint(1, 2), DateTime.utc(2026)),
);

const defaultPlay = 'play default aloud';

void main() {
  late FakeOutput out;
  late FakeOptions options;
  late ReminderSession session;

  void setup() {
    out = FakeOutput();
    options = FakeOptions();
    session = ReminderSession(output: out, options: options);
  }

  int plays() => out.events.where((e) => e.startsWith('play')).length;

  test('AC-3.1: plays 3 tries, 30 seconds apart, then rests', () {
    fakeAsync((f) {
      setup();
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, ['show', defaultPlay]);

      f.elapse(const Duration(seconds: 29));
      expect(plays(), 1);
      f.elapse(const Duration(seconds: 1));
      expect(plays(), 2);
      f.elapse(const Duration(seconds: 30));
      expect(plays(), 3);
      expect(out.events.last, defaultPlay);

      f.elapse(const Duration(seconds: 30));
      expect(plays(), 3);
      expect(out.events.last, 'rest');

      f.elapse(const Duration(minutes: 10));
      expect(plays(), 3);
    });
  });

  test('AC-3.2 and AC-3.3: stop ends sound, notification and repeats', () {
    fakeAsync((f) {
      setup();
      session.start(reminder);
      f.flushMicrotasks();
      session.stop();
      f.flushMicrotasks();
      expect(out.events.sublist(2), ['stopSound', 'cancel']);
      f.elapse(const Duration(minutes: 5));
      expect(plays(), 1);
    });
  });

  test('stopping during the first try still prevents repeats', () {
    fakeAsync((f) {
      setup();
      session.start(reminder);
      session.stop();
      f.elapse(const Duration(minutes: 5));
      expect(plays(), lessThanOrEqualTo(1));
    });
  });

  test('stop with nothing playing is harmless', () {
    fakeAsync((f) {
      setup();
      session.stop();
      f.flushMicrotasks();
      expect(plays(), 0);
    });
  });

  test('a new Reminder replaces one in progress with a fresh count', () {
    fakeAsync((f) {
      setup();
      session.start(reminder);
      f.elapse(const Duration(seconds: 30));
      session.start(reminder);
      f.flushMicrotasks();
      expect(plays(), 3);
      f.elapse(const Duration(seconds: 60));
      expect(plays(), 5);
      f.elapse(const Duration(seconds: 30));
      expect(out.events.last, 'rest');
    });
  });

  test('AC-3.5: the silent choice reaches the sound', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(silent: SilentChoice.vibrate);
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, contains('play default vibrate'));
    });
  });

  test('default is play aloud', () {
    expect(const ReminderOptions().silent, SilentChoice.aloud);
  });

  test('a custom sound is used when it plays', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(customSoundPath: 'voice.m4a');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, contains('play voice.m4a aloud'));
    });
  });

  test('AC-4.4: a custom sound that fails falls back to the default', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(customSoundPath: 'gone.m4a');
      out.failingSounds.add('gone.m4a');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, contains(defaultPlay));
    });
  });

  test('AC-4.3: unreadable options still give a working default', () {
    fakeAsync((f) {
      setup();
      options.fail = true;
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, ['show', defaultPlay]);
    });
  });

  test('a failed notification still plays sound and keeps repeating', () {
    fakeAsync((f) {
      setup();
      out.failShow = true;
      session.start(reminder);
      f.flushMicrotasks();
      expect(plays(), 1);
      f.elapse(const Duration(seconds: 30));
      expect(plays(), 2);
    });
  });

  test('all sounds failing still shows the notification, without error', () {
    fakeAsync((f) {
      setup();
      out.failingSounds.add(null);
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, ['show']);
      expect(f.pendingTimers, hasLength(1));
    });
  });

  group('options text', () {
    test('survives a round trip', () {
      final o = ReminderOptions.parse(
        const ReminderOptions(
          silent: SilentChoice.vibrate,
          customSoundPath: 'a.m4a',
        ).encode(),
      );
      expect(o.silent, SilentChoice.vibrate);
      expect(o.customSoundPath, 'a.m4a');
    });

    test('unreadable text gives the defaults', () {
      final o = ReminderOptions.parse('garbage');
      expect(o.silent, SilentChoice.aloud);
      expect(o.customSoundPath, isNull);
    });
  });
}

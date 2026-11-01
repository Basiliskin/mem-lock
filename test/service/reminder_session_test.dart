import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';
import 'package:leavecheck/domain/reminder_options.dart';
import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/service/reminder_session.dart';

class FakeOutput implements ReminderOutput {
  final events = <String>[];
  final failingSounds = <String?>{};
  bool failShow = false;
  ReminderOptions? shown;

  @override
  Future<void> show({
    required bool alert,
    required ReminderOptions options,
  }) async {
    shown = options;
    events.add(alert ? 'show' : 'rest');
    if (failShow) throw StateError('notifications');
  }

  @override
  Future<void> play(
    String? voicePath,
    ReminderTone tone,
    SilentChoice silent,
  ) async {
    final name =
        voicePath ?? (tone == ReminderTone.rising ? 'default' : tone.name);
    if (failingSounds.contains(name)) throw StateError('sound');
    events.add('play $name ${silent.name}');
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

  @override
  Future<void> write(ReminderOptions value) async => options = value;
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
      options.options = const ReminderOptions(voicePath: 'voice.m4a');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, contains('play voice.m4a aloud'));
    });
  });

  test('AC-4.4: a custom sound that fails falls back to the default', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(voicePath: 'gone.m4a');
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

  test(
    'a place message replaces the text, not the sound or the saved options',
    () {
      fakeAsync((f) {
        setup();
        options.options = const ReminderOptions(
          voicePath: 'v.m4a',
          body: 'Mine',
        );
        session.start(
          StartReminder(
            ReminderSource.reminderPlace,
            LastPlace(const GeoPoint(1, 2), DateTime.utc(2026)),
            placeMessage: 'Take your towel',
          ),
        );
        f.flushMicrotasks();
        expect(out.shown!.body, 'Take your towel');
        expect(out.shown!.voicePath, 'v.m4a');
        expect(options.options.body, 'Mine');
        f.elapse(reminderInterval * reminderTries);
        expect(out.shown!.body, 'Take your towel');
        session.stop();
      });
    },
  );

  test('without a place message the chosen text stays', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(body: 'Mine');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.shown!.body, 'Mine');
      session.stop();
    });
  });

  test('all sounds failing still shows the notification, without error', () {
    fakeAsync((f) {
      setup();
      out.failingSounds.add('default');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, ['show']);
      expect(f.pendingTimers, hasLength(1));
    });
  });

  test('AC-4.1: a change applies from the next Reminder', () {
    fakeAsync((f) {
      setup();
      session.start(reminder);
      f.flushMicrotasks();
      session.stop();
      f.flushMicrotasks();
      options.options = const ReminderOptions(
        tone: ReminderTone.bell,
        title: 'Папа, сумка?',
      );
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events.last, 'play bell aloud');
      expect(out.shown!.title, 'Папа, сумка?');
    });
  });

  test('AC-4.4: a chosen tone that fails falls back to the default', () {
    fakeAsync((f) {
      setup();
      options.options = const ReminderOptions(tone: ReminderTone.bell);
      out.failingSounds.add('bell');
      session.start(reminder);
      f.flushMicrotasks();
      expect(out.events, contains(defaultPlay));
    });
  });

  group('AC-4.5: test', () {
    const chosen = ReminderOptions(
      voicePath: 'v.m4a',
      silent: SilentChoice.vibrate,
    );

    test('plays one try with the given options, with no repeats', () {
      fakeAsync((f) {
        setup();
        session.test(chosen);
        f.flushMicrotasks();
        expect(out.events, ['show', 'play v.m4a vibrate']);
        expect(out.shown, same(chosen));
        f.elapse(const Duration(minutes: 5));
        expect(out.events, hasLength(2));
      });
    });

    test('falls back like a real Reminder', () {
      fakeAsync((f) {
        setup();
        out.failingSounds.add('v.m4a');
        session.test(chosen);
        f.flushMicrotasks();
        expect(out.events, contains('play default vibrate'));
      });
    });

    test('stop ends it', () {
      fakeAsync((f) {
        setup();
        session.test(chosen);
        f.flushMicrotasks();
        session.stop();
        f.flushMicrotasks();
        expect(out.events.sublist(2), ['stopSound', 'cancel']);
      });
    });
  });

  group('options text', () {
    test('survives a round trip', () {
      final o = ReminderOptions.parse(
        const ReminderOptions(
          silent: SilentChoice.vibrate,
          voicePath: 'a.m4a',
        ).encode(),
      );
      expect(o.silent, SilentChoice.vibrate);
      expect(o.voicePath, 'a.m4a');
    });

    test('all options survive a round trip', () {
      final o = ReminderOptions.parse(
        const ReminderOptions(
          tone: ReminderTone.pulse,
          vibration: VibrationChoice.strong,
          title: 'Т',
          body: 'Б',
        ).encode(),
      );
      expect(o.tone, ReminderTone.pulse);
      expect(o.vibration, VibrationChoice.strong);
      expect(o.title, 'Т');
      expect(o.body, 'Б');
    });

    test('options saved before S9 still load, with new defaults', () {
      final o = ReminderOptions.parse('{"silent":"vibrate","sound":"a.m4a"}');
      expect(o.silent, SilentChoice.vibrate);
      expect(o.voicePath, 'a.m4a');
      expect(o.tone, ReminderTone.rising);
      expect(o.vibration, VibrationChoice.normal);
      expect(o.title, isNull);
    });

    test('blank text counts as not set', () {
      final o = const ReminderOptions().copyWith(
        title: () => '  ',
        body: () => ' Да ',
      );
      expect(o.title, isNull);
      expect(o.body, 'Да');
    });

    test('copyWith can clear the voice and keeps the rest', () {
      final o = const ReminderOptions(
        voicePath: 'a',
        tone: ReminderTone.bell,
      ).copyWith(voicePath: () => null);
      expect(o.voicePath, isNull);
      expect(o.tone, ReminderTone.bell);
    });

    test('unreadable text gives the defaults', () {
      final o = ReminderOptions.parse('garbage');
      expect(o.silent, SilentChoice.aloud);
      expect(o.voicePath, isNull);
    });
  });
}

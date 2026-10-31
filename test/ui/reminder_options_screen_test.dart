import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/reminder_options.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/reminder_options_screen.dart';

class FakeStore implements ReminderOptionsStore {
  ReminderOptions saved = const ReminderOptions();
  bool failWrites = false;
  @override
  Future<ReminderOptions> read() async => saved;
  @override
  Future<void> write(ReminderOptions value) async {
    if (failWrites) throw StateError('disk');
    saved = value;
  }
}

class FakeTester implements ReminderTester {
  ReminderOptions? tested;
  int stops = 0;
  @override
  Future<void> test(ReminderOptions options) async => tested = options;
  @override
  Future<void> stop() async => stops++;
}

class FakeRecorder implements VoiceRecorder {
  bool allowed = true;
  bool failStart = false;
  String? result = 'new.m4a';
  int starts = 0;
  int stops = 0;
  @override
  Future<bool> start() async {
    if (failStart) throw StateError('mic');
    starts++;
    return allowed;
  }

  @override
  Future<String?> stop() async {
    stops++;
    return result;
  }
}

void main() {
  late FakeStore store;
  late FakeTester tester;
  late FakeRecorder recorder;

  setUp(() {
    store = FakeStore();
    tester = FakeTester();
    recorder = FakeRecorder();
  });

  Future<void> show(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 4000);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      MaterialApp(
        home: ReminderOptionsScreen(
          store: store,
          tester: tester,
          recorder: recorder,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pump();
    await t.pumpAndSettle();
  }

  testWidgets('AC-4.1: choices are saved as they are made', (t) async {
    await show(t);
    await tap(t, Strings.toneBell);
    await tap(t, Strings.vibrationStrong);
    await tap(t, Strings.silentVibrate);
    expect(store.saved.tone, ReminderTone.bell);
    expect(store.saved.vibration, VibrationChoice.strong);
    expect(store.saved.silent, SilentChoice.vibrate);
  });

  testWidgets('AC-4.1: text is saved, and clearing returns to default', (
    t,
  ) async {
    await show(t);
    final title = find.widgetWithText(TextField, Strings.reminderTitleLabel);
    await t.enterText(title, 'Папа, сумка?');
    await t.pumpAndSettle();
    expect(store.saved.title, 'Папа, сумка?');
    await t.enterText(title, '');
    await t.pumpAndSettle();
    expect(store.saved.title, isNull);
  });

  testWidgets('recording saves the voice and shows it is in use', (t) async {
    await show(t);
    await tap(t, Strings.recordVoice);
    expect(find.text(Strings.stopRecording), findsOneWidget);
    await tap(t, Strings.stopRecording);
    expect(store.saved.voicePath, 'new.m4a');
    expect(find.text(Strings.voiceInUse), findsOneWidget);
  });

  testWidgets('a refused microphone says so and keeps the old sound', (
    t,
  ) async {
    recorder.allowed = false;
    await show(t);
    await tap(t, Strings.recordVoice);
    expect(find.text(Strings.micRefused), findsOneWidget);
    expect(find.text(Strings.stopRecording), findsNothing);
    expect(store.saved.voicePath, isNull);
  });

  testWidgets('a failed recording says so and keeps the old voice', (t) async {
    store.saved = const ReminderOptions(voicePath: 'old.m4a');
    recorder.result = null;
    await show(t);
    await tap(t, Strings.recordVoice);
    await tap(t, Strings.stopRecording);
    expect(store.saved.voicePath, 'old.m4a');
    expect(find.text(Strings.recordFailed), findsOneWidget);
  });

  testWidgets('recording stops by itself at the limit', (t) async {
    await show(t);
    await tap(t, Strings.recordVoice);
    await t.pump(maxRecording);
    await t.pumpAndSettle();
    expect(recorder.stops, 1);
    expect(store.saved.voicePath, 'new.m4a');
  });

  testWidgets('choosing a tone stops using the voice', (t) async {
    store.saved = const ReminderOptions(voicePath: 'old.m4a');
    await show(t);
    await tap(t, Strings.toneBell);
    expect(store.saved.voicePath, isNull);
    expect(find.text(Strings.voiceInUse), findsNothing);
  });

  testWidgets('AC-4.5: test plays the current choices', (t) async {
    await show(t);
    await tap(t, Strings.toneBell);
    await tap(t, Strings.testReminder);
    expect(tester.tested!.tone, ReminderTone.bell);
    await tap(t, Strings.stopTest);
    expect(tester.stops, greaterThan(0));
  });

  testWidgets('a failed save is reported', (t) async {
    await show(t);
    store.failWrites = true;
    await tap(t, Strings.toneBell);
    expect(find.text(Strings.saveFailed), findsOneWidget);
  });

  testWidgets('no vibration with vibrate-only warns of no signal', (t) async {
    await show(t);
    await tap(t, Strings.silentVibrate);
    expect(find.text(Strings.nothingOnSilent), findsNothing);
    await tap(t, Strings.vibrationOff);
    expect(find.text(Strings.nothingOnSilent), findsOneWidget);
  });

  testWidgets('leaving stops a test in progress', (t) async {
    await show(t);
    await t.pumpWidget(const SizedBox());
    expect(tester.stops, 1);
  });
}

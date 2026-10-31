import 'dart:async';

import '../domain/detector.dart';
import '../domain/reminder_options.dart';
import '../ports/ports.dart';

const reminderTries = 3;
const reminderInterval = Duration(seconds: 30);

/// Runs one Reminder from first try to its end. A failing output never stops
/// the rest of the Reminder, because any part of it may be the one noticed.
class ReminderSession implements ReminderPlayer {
  ReminderSession({
    required ReminderOutput output,
    required ReminderOptionsStore options,
  }) : _output = output,
       _optionsStore = options;

  final ReminderOutput _output;
  final ReminderOptionsStore _optionsStore;

  /// Bumped by each start and stop, so work from an older one can bail out.
  int _run = 0;
  int _tries = 0;
  Timer? _timer;
  ReminderOptions _options = const ReminderOptions();

  @override
  Future<void> start(StartReminder reminder) async {
    final run = _begin();
    _tries = 0;
    try {
      _options = await _optionsStore.read();
    } on Object {
      _options = const ReminderOptions();
    }
    if (run == _run) await _fire(run);
  }

  @override
  Future<void> stop() async {
    _begin();
    await _quietly(_output.stopSound);
    await _quietly(_output.cancel);
  }

  int _begin() {
    _timer?.cancel();
    _timer = null;
    return ++_run;
  }

  Future<void> _fire(int run) async {
    _tries++;
    await _quietly(() => _output.show(alert: true));
    if (run != _run) return;
    await _playWithFallback();
    if (run != _run) return;
    _timer = Timer(reminderInterval, () => _next(run));
  }

  Future<void> _next(int run) async {
    if (run != _run) return;
    if (_tries < reminderTries) {
      await _fire(run);
    } else {
      await _quietly(() => _output.show(alert: false));
    }
  }

  Future<void> _playWithFallback() async {
    final custom = _options.customSoundPath;
    if (custom != null) {
      try {
        await _output.play(custom, _options.silent);
        return;
      } on Object {
        // Falls through to the default sound (AC-4.4).
      }
    }
    await _quietly(() => _output.play(null, _options.silent));
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Reported through the status warnings added in S11.
    }
  }
}

import 'dart:async';

import '../domain/detector.dart';
import '../domain/detector_json.dart';
import '../ports/ports.dart';

/// Connects the ports to the Detector. Events run strictly one at a time, and
/// a failing port never stops watching.
class Watcher {
  Watcher({
    required LocationSource location,
    required StateStore store,
    required ReminderPlayer reminders,
  }) : _location = location,
       _store = store,
       _reminders = reminders;

  final LocationSource _location;
  final StateStore _store;
  final ReminderPlayer _reminders;

  DetectorState state = DetectorState.initial();
  StreamSubscription<LocationFix>? _subscription;
  Future<void> _queue = Future.value();

  Future<void> start() async {
    state = await _load();
    await _quietly(() => _location.setMode(state.locationMode));
    _subscription = _location.fixes.listen(handle, onError: (Object _) {});
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> tick(DateTime now) => handle(Tick(now));

  Future<void> handle(DetectorEvent event) =>
      _queue = _queue.then((_) => _process(event));

  Future<DetectorState> _load() async {
    try {
      final saved = await _store.read();
      if (saved != null) return decodeState(saved);
    } on Object {
      // Unreadable state must not stop watching: start again from nothing.
    }
    return DetectorState.initial();
  }

  Future<void> _process(DetectorEvent event) async {
    final before = encodeState(state);
    final (next, decisions) = step(state, event);
    state = next;
    final after = encodeState(next);
    // Saved before acting, so a crash can't repeat a Reminder after a restart.
    if (after != before) await _quietly(() => _store.write(after));
    for (final d in decisions) {
      await _quietly(
        () => switch (d) {
          StartReminder() => _reminders.start(d),
          StopRepeats() => _reminders.stop(),
          SetLocationMode() => _location.setMode(d.mode),
        },
      );
    }
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Reported through the status warnings added in S11.
    }
  }
}

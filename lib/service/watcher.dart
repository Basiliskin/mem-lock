import 'dart:async';

import '../domain/detector.dart';
import '../domain/detector_json.dart';
import '../domain/last_place_record.dart';
import '../domain/quiet_place_record.dart';
import '../ports/ports.dart';

/// Connects the ports to the Detector. Events run strictly one at a time, and
/// a failing port never stops watching.
class Watcher {
  Watcher({
    required LocationSource location,
    required ActivitySource activity,
    required StateStore store,
    required ReminderPlayer reminders,
    required LastPlaceStore places,
    required QuietPlaceStore quiet,
    required StayChoiceStore stayChoice,
  }) : _location = location,
       _activity = activity,
       _store = store,
       _reminders = reminders,
       _places = places,
       _quiet = quiet,
       _stayChoice = stayChoice;

  final LocationSource _location;
  final ActivitySource _activity;
  final StateStore _store;
  final ReminderPlayer _reminders;
  final LastPlaceStore _places;
  final QuietPlaceStore _quiet;
  final StayChoiceStore _stayChoice;

  DetectorState state = DetectorState.initial();
  StreamSubscription<LocationFix>? _subscription;
  StreamSubscription<ActivityChanged>? _activitySubscription;
  Future<void> _queue = Future.value();

  Future<void> start() async {
    state = await _load();
    await _quietly(() => _location.setMode(state.locationMode));
    // These may have changed while the service wasn't running.
    await syncQuietPlaces();
    await syncStaySetting();
    _subscription = _location.fixes.listen(handle, onError: (Object _) {});
    _listenToActivity();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _activitySubscription?.cancel();
    _activitySubscription = null;
  }

  /// Asks for readings again, in turn with other events.
  Future<void> restartLocation() => _queue = _queue.then(
    (_) => _quietly(() => _location.setMode(state.locationMode)),
  );

  /// Listens again, because activity updates that failed to register while the
  /// permission was missing are not retried by the phone.
  Future<void> restartActivity() => _queue = _queue.then((_) async {
    if (_activitySubscription == null) return;
    await _quietly(() async => _activitySubscription?.cancel());
    _listenToActivity();
  });

  void _listenToActivity() {
    _activitySubscription = _activity.changes.listen(
      handle,
      onError: (Object _) {},
    );
  }

  Future<void> tick(DateTime now) => handle(Tick(now));

  /// Reads the Helper's list and passes it to the Detector, in turn with other
  /// events. A failed read keeps the list the Detector already has.
  Future<void> syncQuietPlaces() => _queue = _queue.then((_) async {
    final List<QuietPlaceRecord> records;
    try {
      records = await _quiet.read();
    } on Object {
      return;
    }
    await _process(
      QuietPlacesChanged(DateTime.now(), [for (final r in records) r.place]),
    );
  });

  /// Reads the Helper's choice and passes it to the Detector, in turn with
  /// other events. A failed read keeps the setting the Detector already has.
  Future<void> syncStaySetting() => _queue = _queue.then((_) async {
    final StayChoice choice;
    try {
      choice = await _stayChoice.read();
    } on Object {
      return;
    }
    await _process(SettingsChanged(DateTime.now(), choice.settings));
  });

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
      if (d is StartReminder) {
        // Saved first, so "I forgot something" always has a place to show.
        await _quietly(
          () => _places.save(
            LastPlaceRecord(d.lastPlace.point, d.lastPlace.time, d.source),
          ),
        );
      }
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
      // Lost permissions and location show up in ProtectionMonitor's checks.
    }
  }
}

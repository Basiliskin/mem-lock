import 'dart:async';

import '../domain/detector.dart';
import '../domain/home_wifi.dart';
import '../domain/last_place_record.dart';
import '../ports/ports.dart';

/// Connects the ports to the home Wi-Fi rules. Events run strictly one at a
/// time, and a failing port never stops watching.
class HomeWatcher {
  HomeWatcher({
    required LocationSource location,
    required LocationStatusStore locationStatus,
    required ActivitySource activity,
    required WifiSource wifi,
    required HomeWifiStore home,
    required StateStore store,
    required ReminderPlayer reminders,
    required LastPlaceStore places,
  }) : _location = location,
       _locationStatus = locationStatus,
       _activity = activity,
       _wifi = wifi,
       _home = home,
       _store = store,
       _reminders = reminders,
       _places = places;

  final LocationSource _location;
  final LocationStatusStore _locationStatus;
  final ActivitySource _activity;
  final WifiSource _wifi;
  final HomeWifiStore _home;
  final StateStore _store;
  final ReminderPlayer _reminders;
  final LastPlaceStore _places;

  HomeState state = const HomeState();
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<ActivityChanged>? _activitySubscription;
  Future<void> _queue = Future.value();
  bool _locationErrored = false;
  bool _locationFailing = false;

  Future<void> start() async {
    state = await _load();
    _subscriptions.add(
      _location.fixes.listen(
        (f) => handle(Sensed(f)),
        onError: (Object _) => _locationErrored = true,
      ),
    );
    await _quietly(() => _locationStatus.write(failing: false));
    await _quietly(() => _location.setMode(state.mode));
    await syncHome();
    _subscriptions.add(
      _wifi.changes.listen(
        (n) => handle(WifiChanged(DateTime.now(), n)),
        onError: (Object _) {},
      ),
    );
    _listenToActivity();
  }

  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _activitySubscription?.cancel();
    _activitySubscription = null;
  }

  /// Reads the saved home and the network now, in turn with other events. A
  /// failed read keeps what is already known.
  Future<void> syncHome() => _queue = _queue.then((_) async {
    try {
      await _process(HomeChanged(DateTime.now(), await _home.read()));
    } on Object {
      return;
    }
    try {
      await _process(WifiChanged(DateTime.now(), await _wifi.current()));
    } on Object {
      // The next change on the stream brings it.
    }
  });

  Future<void> tick(DateTime now) => handle(Sensed(Tick(now)));

  Future<void> restartLocation() => _queue = _queue.then(
    (_) => _quietly(() => _location.setMode(state.mode)),
  );

  /// A failed start of location is not retried by the phone, so ask again,
  /// and report it until a retry brings no error.
  Future<void> checkLocation() => _queue = _queue.then((_) async {
    final failing = _locationErrored;
    _locationErrored = false;
    if (failing != _locationFailing) {
      _locationFailing = failing;
      await _quietly(() => _locationStatus.write(failing: failing));
    }
    if (failing) await _quietly(() => _location.setMode(state.mode));
  });

  Future<void> restartActivity() => _queue = _queue.then((_) async {
    if (_activitySubscription == null) return;
    await _quietly(() async => _activitySubscription?.cancel());
    _listenToActivity();
  });

  void _listenToActivity() {
    _activitySubscription = _activity.changes.listen(
      (a) => handle(Sensed(a)),
      onError: (Object _) {},
    );
  }

  Future<void> handle(HomeEvent event) =>
      _queue = _queue.then((_) => _process(event));

  Future<HomeState> _load() async {
    try {
      return decodeHomeState(await _store.read());
    } on Object {
      return const HomeState();
    }
  }

  Future<void> _process(HomeEvent event) async {
    final before = encodeHomeState(state);
    final (next, decisions) = homeStep(state, event);
    state = next;
    final after = encodeHomeState(next);
    // Saved before acting, so a crash can't repeat a Reminder after a restart.
    if (after != before) await _quietly(() => _store.write(after));
    for (final d in decisions) {
      if (d is StartReminder) {
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

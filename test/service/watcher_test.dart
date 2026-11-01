import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';
import 'package:geo_alert/domain/quiet_place_record.dart';
import 'package:geo_alert/domain/reminder_place_record.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/service/watcher.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int m, [int s = 0]) => t0.add(Duration(minutes: m, seconds: s));
const cafe = GeoPoint(55.75, 37.61);
GeoPoint north(double m) => GeoPoint(cafe.lat + m / 111195, cafe.lng);

class FakeLocation implements LocationSource {
  final controller = StreamController<LocationFix>();
  final modes = <LocationMode>[];
  @override
  Stream<LocationFix> get fixes => controller.stream;
  @override
  Future<void> setMode(LocationMode mode) async => modes.add(mode);
}

class FakeLocationStatus implements LocationStatusStore {
  final written = <bool>[];
  @override
  Future<void> write({required bool failing}) async => written.add(failing);
}

class FakeActivity implements ActivitySource {
  final controller = StreamController<ActivityChanged>.broadcast();
  @override
  Stream<ActivityChanged> get changes => controller.stream;
}

class FakeStore implements StateStore {
  FakeStore([this.text]);
  String? text;
  bool failReads = false;
  @override
  Future<String?> read() async {
    if (failReads) throw StateError('disk');
    return text;
  }

  @override
  Future<void> write(String value) async => text = value;
}

class FakePlaces implements LastPlaceStore {
  LastPlaceRecord? record;
  bool fail = false;
  final log = <String>[];
  @override
  Future<List<LastPlaceRecord>> read() async => [?record];
  @override
  Future<void> save(LastPlaceRecord value) async {
    if (fail) throw StateError('disk');
    record = value;
  }
}

class FakeQuiet implements QuietPlaceStore {
  List<QuietPlaceRecord> saved = [];
  bool fail = false;
  @override
  Future<List<QuietPlaceRecord>> read() async {
    if (fail) throw StateError('disk');
    return saved;
  }

  @override
  Future<void> write(List<QuietPlaceRecord> places) async => saved = places;
}

class FakeReminderPlaces implements ReminderPlaceStore {
  List<ReminderPlaceRecord> saved = [];
  bool fail = false;
  @override
  Future<List<ReminderPlaceRecord>> read() async {
    if (fail) throw StateError('disk');
    return saved;
  }

  @override
  Future<void> write(List<ReminderPlaceRecord> places) async => saved = places;
}

class FakeChoice implements DetectionSettingsStore {
  DetectionSettings saved = DetectionSettings.normal;
  bool fail = false;
  @override
  Future<DetectionSettings> read() async {
    if (fail) throw StateError('disk');
    return saved;
  }

  @override
  Future<void> write(DetectionSettings value) async => saved = value;
}

class FakeReminders implements ReminderPlayer {
  final started = <StartReminder>[];
  int stopped = 0;
  @override
  Future<void> start(StartReminder reminder) async => started.add(reminder);
  @override
  Future<void> stop() async => stopped++;
}

void main() {
  late FakeLocationStatus locationStatus;
  setUp(() => locationStatus = FakeLocationStatus());
  late FakeLocation location;
  late FakeActivity activity;
  late FakeStore store;
  late FakeReminders reminders;
  late Watcher watcher;
  final places = FakePlaces();
  late FakeQuiet quiet;
  late FakeChoice choice;
  late FakeReminderPlaces reminderPlaces;

  setUp(() {
    activity = FakeActivity();
    quiet = FakeQuiet();
    choice = FakeChoice();
    reminderPlaces = FakeReminderPlaces();
  });

  Future<void> begin([String? saved]) async {
    location = FakeLocation();
    store = FakeStore(saved);
    reminders = FakeReminders();
    watcher = Watcher(
      locationStatus: locationStatus,
      location: location,
      activity: activity,
      store: store,
      reminders: reminders,
      places: places,
      quiet: quiet,
      detectionSettings: choice,
      reminderPlaces: reminderPlaces,
    );
    await watcher.start();
  }

  Future<void> send(LocationFix f) => watcher.handle(f);

  Future<void> walkOut() async {
    await send(LocationFix(at(6), north(200), 10));
    await send(LocationFix(at(6, 10), north(220), 10));
  }

  Future<void> settle() async {
    await send(LocationFix(at(0), cafe, 10));
    await watcher.tick(at(5));
  }

  group('activity signals', () {
    ActivityChanged act(int s, ActivityKind kind, [int confidence = 90]) =>
        ActivityChanged(at(0, s), kind, confidence);

    Future<void> boardRide() async {
      await send(LocationFix(at(0), cafe, 10));
      activity.controller.add(act(10, ActivityKind.inVehicle));
      await pumpEventQueue();
      await watcher.handle(Tick(at(0, 11)));
    }

    test('reach the Detector and start a Ride', () async {
      await begin();
      await boardRide();
      expect(watcher.state.phase, isA<OnRide>());
    });

    test('AC-2.1: getting off gives one Reminder', () async {
      await begin();
      await boardRide();
      activity.controller.add(act(20, ActivityKind.walking));
      await pumpEventQueue();
      await watcher.tick(at(0, 55));
      await watcher.tick(at(1, 30));
      expect(reminders.started, hasLength(1));
    });

    test('a stream error keeps watching', () async {
      await begin();
      activity.controller.addError(StateError('no play services'));
      await pumpEventQueue();
      await boardRide();
      expect(watcher.state.phase, isA<OnRide>());
    });

    test('restarting listens again, so a new grant takes effect', () async {
      var listens = 0;
      activity = FakeActivity();
      activity.controller.onListen = () => listens++;
      await begin();
      expect(listens, 1);
      await watcher.restartActivity();
      expect(listens, 2);
      await boardRide();
      expect(watcher.state.phase, isA<OnRide>());
    });

    test('restarting after stop does not listen again', () async {
      await begin();
      await watcher.stop();
      await watcher.restartActivity();
      expect(activity.controller.hasListener, isFalse);
    });

    test('stop cancels the subscription', () async {
      await begin();
      expect(activity.controller.hasListener, isTrue);
      await watcher.stop();
      expect(activity.controller.hasListener, isFalse);
    });

    test('a saved Ride continues after a restart', () async {
      await begin();
      await boardRide();
      await watcher.stop();
      activity = FakeActivity();
      final before = reminders;
      await begin(store.text);
      expect(watcher.state.phase, isA<OnRide>());
      activity.controller.add(act(20, ActivityKind.walking));
      await pumpEventQueue();
      await watcher.tick(at(0, 55));
      expect(before.started, isEmpty);
      expect(reminders.started, hasLength(1));
    });
  });

  test('a full visit starts one Reminder and sets the modes', () async {
    await begin();
    await settle();
    await walkOut();
    expect(reminders.started, hasLength(1));
    expect(location.modes, [
      LocationMode.precise,
      LocationMode.lowPower,
      LocationMode.precise,
    ]);
  });

  test('AC-10.1: the saved Stay choice applies from the start', () async {
    choice.saved = StayChoice.moreOften.settings;
    await begin();
    expect(watcher.state.settings.stayTime, const Duration(minutes: 3));
  });

  test('AC-10.1: a changed choice reaches the Detector', () async {
    await begin();
    choice.saved = StayChoice.lessOften.settings;
    await watcher.syncDetectionSettings();
    expect(watcher.state.settings.stayMeters, 100);
  });

  test('AC-12.5: saved Ride values reach the Detector', () async {
    await begin();
    choice.saved = const DetectionSettings(
      stayTime: Duration(minutes: 5),
      stayMeters: 75,
      vehicleKmh: 20,
      walkingAfterRide: Duration(seconds: 60),
    );
    await watcher.syncDetectionSettings();
    expect(watcher.state.settings.vehicleKmh, 20);
    expect(
      watcher.state.settings.walkingAfterRide,
      const Duration(seconds: 60),
    );
  });

  test('a failed read keeps the Stay setting', () async {
    choice.saved = StayChoice.lessOften.settings;
    await begin();
    choice.fail = true;
    await watcher.syncDetectionSettings();
    expect(watcher.state.settings.stayMeters, 100);
  });

  group('Reminder Places', () {
    const point = GeoPoint(55.75, 37.61);
    GeoPoint away(double m) => GeoPoint(point.lat + m / 111195, point.lng);
    final t0 = DateTime.utc(2026, 11, 1, 10);
    const record = ReminderPlaceRecord(
      ReminderPlace('p', point, 'Take your towel'),
      'Pool',
    );

    Future<void> visitAndLeave() async {
      await send(LocationFix(t0, point, 10));
      await send(
        LocationFix(t0.add(const Duration(seconds: 70)), away(100), 10),
      );
      await send(
        LocationFix(t0.add(const Duration(seconds: 80)), away(120), 10),
      );
    }

    test('the saved list applies from the start', () async {
      reminderPlaces.saved = [record];
      await begin();
      expect(watcher.state.reminderPlaces.single.message, 'Take your towel');
    });

    test('AC-11.2: leaving starts a Reminder with the message', () async {
      reminderPlaces.saved = [record];
      await begin();
      await visitAndLeave();
      expect(reminders.started.single.placeMessage, 'Take your towel');
    });

    test('AC-11.8: its Last Place is saved', () async {
      reminderPlaces.saved = [record];
      await begin();
      places.record = null;
      await visitAndLeave();
      expect(places.record!.source, ReminderSource.reminderPlace);
      expect(places.record!.point, point);
    });

    test('AC-11.7: a removed place gives no Reminder', () async {
      reminderPlaces.saved = [record];
      await begin();
      reminderPlaces.saved = [];
      await watcher.syncReminderPlaces();
      await visitAndLeave();
      expect(reminders.started, isEmpty);
    });

    test('a failed read keeps the list', () async {
      reminderPlaces.saved = [record];
      await begin();
      reminderPlaces.fail = true;
      await watcher.syncReminderPlaces();
      expect(watcher.state.reminderPlaces, hasLength(1));
    });
  });

  test('fixes arriving on the stream reach the Detector', () async {
    await begin();
    location.controller.add(LocationFix(at(0), cafe, 10));
    await pumpEventQueue();
    await watcher.tick(at(5));
    expect(decodeState(store.text!).phase, isA<InStay>());
  });

  test('AC-5.5: each Reminder saves its Last Place', () async {
    places.record = null;
    await begin();
    await settle();
    await walkOut();
    expect(places.record!.point, cafe);
    expect(places.record!.time, at(6, 10));
    await watcher.tick(at(12));
    await send(LocationFix(at(13), north(600), 10));
    await send(LocationFix(at(13, 10), north(620), 10));
    expect(places.record!.time, at(13, 10));
  });

  test('the Last Place is saved before the Reminder starts', () async {
    final order = <String>[];
    final p = _OrderPlaces(order);
    location = FakeLocation();
    store = FakeStore();
    watcher = Watcher(
      locationStatus: locationStatus,
      location: location,
      activity: activity,
      store: store,
      reminders: _OrderReminders(order),
      places: p,
      quiet: quiet,
      detectionSettings: FakeChoice(),
      reminderPlaces: FakeReminderPlaces(),
    );
    await watcher.start();
    await settle();
    await walkOut();
    expect(order, ['save', 'start']);
  });

  test('a failed save still starts the Reminder', () async {
    places.fail = true;
    addTearDown(() => places.fail = false);
    await begin();
    await settle();
    await walkOut();
    expect(reminders.started, hasLength(1));
  });

  test('coming back stops the repeats', () async {
    await begin();
    await settle();
    await walkOut();
    await send(LocationFix(at(7), cafe, 10));
    expect(reminders.stopped, 1);
  });

  group('invariant 6: restarts', () {
    test('state is saved, so a restart continues the Stay', () async {
      await begin();
      await settle();
      final saved = store.text;
      await begin(saved);
      await walkOut();
      expect(reminders.started, hasLength(1));
    });

    test('a restart resumes in the saved location mode', () async {
      await begin();
      await settle();
      await begin(store.text);
      expect(location.modes, [LocationMode.lowPower]);
    });

    test('a restart after a Reminder does not repeat it', () async {
      await begin();
      await settle();
      await walkOut();
      await begin(store.text);
      await watcher.tick(at(6, 20));
      expect(reminders.started, isEmpty);
    });

    test('unreadable saved state resets and keeps watching', () async {
      await begin('garbage');
      expect(watcher.state.phase, isA<Roaming>());
      await settle();
      await walkOut();
      expect(reminders.started, hasLength(1));
    });

    test('a failed storage read resets and keeps watching', () async {
      location = FakeLocation();
      store = FakeStore()..failReads = true;
      reminders = FakeReminders();
      watcher = Watcher(
        locationStatus: locationStatus,
        location: location,
        activity: activity,
        store: store,
        reminders: reminders,
        places: places,
        quiet: quiet,
        detectionSettings: FakeChoice(),
        reminderPlaces: FakeReminderPlaces(),
      );
      await watcher.start();
      expect(watcher.state.phase, isA<Roaming>());
    });
  });

  group('Quiet Places', () {
    final atCafe = QuietPlaceRecord(const QuietPlace('c', cafe), t0);

    test('AC-1.3: a place marked during the Stay gives no Reminder', () async {
      await begin();
      await settle();
      quiet.saved = [atCafe];
      await watcher.syncQuietPlaces();
      await walkOut();
      expect(reminders.started, isEmpty);
    });

    test('AC-6.3: a place removed during the Stay gives a Reminder', () async {
      quiet.saved = [atCafe];
      await begin();
      await settle();
      quiet.saved = [];
      await watcher.syncQuietPlaces();
      await walkOut();
      expect(reminders.started, hasLength(1));
    });

    test('a change made while the service was stopped is picked up', () async {
      await begin();
      final saved = store.text;
      quiet.saved = [atCafe];
      await begin(saved);
      await settle();
      await walkOut();
      expect(reminders.started, isEmpty);
    });

    test('a change is saved, so it survives a failed read later', () async {
      quiet.saved = [atCafe];
      await begin();
      expect(decodeState(store.text!).quietPlaces.single.id, 'c');
      quiet.fail = true;
      await begin(store.text);
      await settle();
      await walkOut();
      expect(reminders.started, isEmpty);
    });

    test('a failed read keeps the list and later events still run', () async {
      quiet.saved = [atCafe];
      await begin();
      quiet.fail = true;
      await watcher.syncQuietPlaces();
      expect(watcher.state.quietPlaces, hasLength(1));
      await settle();
      expect(watcher.state.phase, isA<InStay>());
    });

    test('a change does not disturb the Stay in progress', () async {
      await begin();
      await settle();
      quiet.saved = [atCafe];
      await watcher.syncQuietPlaces();
      expect(watcher.state.phase, isA<InStay>());
    });
  });

  test('events are handled in order even when sent together', () async {
    await begin();
    await Future.wait([
      send(LocationFix(at(0), cafe, 10)),
      watcher.tick(at(5)),
      send(LocationFix(at(6), north(200), 10)),
      send(LocationFix(at(6, 10), north(220), 10)),
    ]);
    expect(reminders.started, hasLength(1));
  });

  test('a failing Reminder does not stop later events', () async {
    final failing = _FailingReminders();
    location = FakeLocation();
    store = FakeStore();
    watcher = Watcher(
      locationStatus: locationStatus,
      location: location,
      activity: activity,
      store: store,
      reminders: failing,
      places: places,
      quiet: quiet,
      detectionSettings: FakeChoice(),
      reminderPlaces: FakeReminderPlaces(),
    );
    await watcher.start();
    await settle();
    await walkOut();
    await send(LocationFix(at(7), cafe, 10));
    expect(failing.calls, 2);
  });

  test('restarting location asks again in the current mode', () async {
    await begin();
    await settle();
    location.modes.clear();
    await watcher.restartLocation();
    expect(location.modes, [LocationMode.lowPower]);
  });

  test('stop ends the location subscription', () async {
    await begin();
    await watcher.stop();
    expect(location.controller.hasListener, isFalse);
  });

  group('location stream failure', () {
    late FakeLocation location;
    late Watcher failing;

    setUp(() async {
      location = FakeLocation();
      failing = Watcher(
        locationStatus: locationStatus,
        location: location,
        activity: FakeActivity(),
        store: FakeStore(),
        reminders: FakeReminders(),
        places: FakePlaces(),
        quiet: FakeQuiet(),
        detectionSettings: FakeChoice(),
        reminderPlaces: FakeReminderPlaces(),
      );
      await failing.start();
      await Future<void>.delayed(Duration.zero);
      locationStatus.written.clear();
      location.modes.clear();
    });

    Future<void> streamError() async {
      location.controller.addError(StateError('settings check failed'));
      await Future<void>.delayed(Duration.zero);
    }

    test('an error is reported and location is asked for again', () async {
      await streamError();
      await failing.checkLocation();
      expect(locationStatus.written, [true]);
      expect(location.modes, hasLength(1));
    });

    test('keeps retrying and reports once while errors continue', () async {
      await streamError();
      await failing.checkLocation();
      await streamError();
      await failing.checkLocation();
      expect(locationStatus.written, [true]);
      expect(location.modes, hasLength(2));
    });

    test('a retry with no new error clears the report', () async {
      await streamError();
      await failing.checkLocation();
      await failing.checkLocation();
      expect(locationStatus.written, [true, false]);
      expect(location.modes, hasLength(1));
    });

    test('a healthy stream never retries or reports', () async {
      await failing.checkLocation();
      await failing.checkLocation();
      expect(locationStatus.written, isEmpty);
      expect(location.modes, isEmpty);
    });
  });
}

class _FailingReminders implements ReminderPlayer {
  int calls = 0;
  @override
  Future<void> start(StartReminder reminder) async {
    calls++;
    throw StateError('no');
  }

  @override
  Future<void> stop() async {
    calls++;
    throw StateError('no');
  }
}

class _OrderPlaces implements LastPlaceStore {
  _OrderPlaces(this.order);
  final List<String> order;
  @override
  Future<List<LastPlaceRecord>> read() async => const [];
  @override
  Future<void> save(LastPlaceRecord value) async => order.add('save');
}

class _OrderReminders implements ReminderPlayer {
  _OrderReminders(this.order);
  final List<String> order;
  @override
  Future<void> start(StartReminder reminder) async => order.add('start');
  @override
  Future<void> stop() async {}
}

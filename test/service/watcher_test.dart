import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/detector_json.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';
import 'package:geo_alert/domain/quiet_place_record.dart';
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

class FakeChoice implements StayChoiceStore {
  StayChoice saved = StayChoice.normal;
  bool fail = false;
  @override
  Future<StayChoice> read() async {
    if (fail) throw StateError('disk');
    return saved;
  }

  @override
  Future<void> write(StayChoice value) async => saved = value;
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
  late FakeLocation location;
  late FakeStore store;
  late FakeReminders reminders;
  late Watcher watcher;
  final places = FakePlaces();
  late FakeQuiet quiet;
  late FakeChoice choice;

  setUp(() {
    quiet = FakeQuiet();
    choice = FakeChoice();
  });

  Future<void> begin([String? saved]) async {
    location = FakeLocation();
    store = FakeStore(saved);
    reminders = FakeReminders();
    watcher = Watcher(
      location: location,
      store: store,
      reminders: reminders,
      places: places,
      quiet: quiet,
      stayChoice: choice,
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
    choice.saved = StayChoice.moreOften;
    await begin();
    expect(watcher.state.settings.stayTime, const Duration(minutes: 3));
  });

  test('AC-10.1: a changed choice reaches the Detector', () async {
    await begin();
    choice.saved = StayChoice.lessOften;
    await watcher.syncStaySetting();
    expect(watcher.state.settings.stayMeters, 100);
  });

  test('a failed read keeps the Stay setting', () async {
    choice.saved = StayChoice.lessOften;
    await begin();
    choice.fail = true;
    await watcher.syncStaySetting();
    expect(watcher.state.settings.stayMeters, 100);
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
      location: location,
      store: store,
      reminders: _OrderReminders(order),
      places: p,
      quiet: quiet,
      stayChoice: FakeChoice(),
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
        location: location,
        store: store,
        reminders: reminders,
        places: places,
        quiet: quiet,
        stayChoice: FakeChoice(),
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
      location: location,
      store: store,
      reminders: failing,
      places: places,
      quiet: quiet,
      stayChoice: FakeChoice(),
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

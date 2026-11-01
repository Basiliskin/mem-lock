import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/quiet_place_record.dart';
import 'package:geo_alert/domain/reminder_place_record.dart';
import 'package:geo_alert/l10n/l10n.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/quiet_places_screen.dart';
import 'package:geo_alert/ui/reminder_places_screen.dart';

import '../support/l10n.dart';

const pool = GeoPoint(55.75, 37.61);
const far = GeoPoint(55.80, 37.70);
final now = DateTime(2026, 11, 1, 14, 32);

class FakePlaces implements ReminderPlaceStore {
  List<ReminderPlaceRecord> saved = [];
  bool failWrites = false;
  @override
  Future<List<ReminderPlaceRecord>> read() async => saved;
  @override
  Future<void> write(List<ReminderPlaceRecord> places) async {
    if (failWrites) throw StateError('disk');
    saved = places;
  }
}

class FakeQuiet implements QuietPlaceStore {
  List<QuietPlaceRecord> saved = [];
  bool failWrites = false;
  @override
  Future<List<QuietPlaceRecord>> read() async => saved;
  @override
  Future<void> write(List<QuietPlaceRecord> places) async {
    if (failWrites) throw StateError('disk');
    saved = places;
  }
}

class FakeFix implements CurrentFixSource {
  LocationFix? fix = LocationFix(now, pool, 10);
  @override
  Future<LocationFix?> currentFix() async => fix;
}

class FakeLink implements WatcherLink {
  int toldPlaces = 0;
  int toldQuiet = 0;
  @override
  void quietPlacesChanged() => toldQuiet++;
  @override
  void reminderPlacesChanged() => toldPlaces++;
  @override
  void languageChanged() {}
  @override
  void detectionSettingsChanged() {}
}

ReminderPlaceRecord place(String id, GeoPoint p, [String name = 'Бассейн']) =>
    ReminderPlaceRecord(ReminderPlace(id, p, 'Полотенце'), name);

void main() {
  late FakePlaces places;
  late FakeQuiet quiet;
  late FakeFix location;
  late FakeLink link;

  setUp(() {
    places = FakePlaces();
    quiet = FakeQuiet();
    location = FakeFix();
    link = FakeLink();
  });

  Future<void> pump(WidgetTester t, Widget home) async {
    t.view.physicalSize = const Size(1200, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: testLocale,
        home: home,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> show(WidgetTester t) => pump(
    t,
    ReminderPlacesScreen(
      store: places,
      quiet: quiet,
      location: location,
      link: link,
      now: () => now,
    ),
  );

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  Future<void> fill(WidgetTester t, String name, String message) async {
    await t.enterText(find.byKey(const ValueKey('place-name')), name);
    await t.enterText(find.byKey(const ValueKey('place-message')), message);
  }

  Future<void> mark(WidgetTester t) async {
    await fill(t, ' Бассейн ', ' Полотенце ');
    await tapText(t, l10n.markReminderPlace);
  }

  testWidgets('an empty list says so', (t) async {
    await show(t);
    expect(find.text(l10n.noReminderPlaces), findsOneWidget);
  });

  testWidgets('AC-11.1: marking saves here and tells the service', (t) async {
    await show(t);
    await mark(t);
    final r = places.saved.single;
    expect(r.name, 'Бассейн');
    expect(r.place.message, 'Полотенце');
    expect(r.place.point, pool);
    expect(link.toldPlaces, 1);
    expect(find.text(l10n.reminderPlaceSaved), findsOneWidget);
    expect(find.text('Бассейн'), findsOneWidget);
  });

  group('nothing is saved, and it says why', () {
    for (final (name, message) in [('', 'Текст'), ('Имя', ''), ('  ', '  ')]) {
      testWidgets('blank text "$name"/"$message"', (t) async {
        await show(t);
        await fill(t, name, message);
        await tapText(t, l10n.markReminderPlace);
        expect(places.saved, isEmpty);
        expect(find.text(l10n.reminderPlaceNeedsText), findsOneWidget);
      });
    }

    testWidgets('AC-11.6: no fix', (t) async {
      location.fix = null;
      await show(t);
      await mark(t);
      expect(places.saved, isEmpty);
      expect(link.toldPlaces, 0);
      expect(find.text(l10n.reminderPlaceNoFix), findsOneWidget);
    });

    testWidgets('AC-11.6: a fix too inaccurate to trust', (t) async {
      location.fix = LocationFix(now, pool, maxAccuracyMeters + 1);
      await show(t);
      await mark(t);
      expect(places.saved, isEmpty);
      expect(find.text(l10n.reminderPlaceNoFix), findsOneWidget);
    });

    testWidgets('the typed text is kept for another try', (t) async {
      location.fix = null;
      await show(t);
      await mark(t);
      location.fix = LocationFix(now, pool, 10);
      await tapText(t, l10n.markReminderPlace);
      expect(places.saved, hasLength(1));
    });

    testWidgets('the same place twice', (t) async {
      places.saved = [place('old', pool)];
      await show(t);
      await mark(t);
      expect(places.saved, hasLength(1));
      expect(find.text(l10n.alreadyReminderPlace), findsOneWidget);
    });

    testWidgets('a failed save', (t) async {
      places.failWrites = true;
      await show(t);
      await mark(t);
      expect(find.text(l10n.saveFailed), findsOneWidget);
      expect(link.toldPlaces, 0);
    });
  });

  group('AC-11.4: marking at a Quiet Place', () {
    setUp(
      () => quiet.saved = [
        QuietPlaceRecord(const QuietPlace('q', pool), now),
        QuietPlaceRecord(const QuietPlace('other', far), now),
      ],
    );

    testWidgets('keeping it quiet saves nothing', (t) async {
      await show(t);
      await mark(t);
      expect(find.text(l10n.clashIsQuiet), findsOneWidget);
      await tapText(t, l10n.keepQuiet);
      expect(places.saved, isEmpty);
      expect(quiet.saved, hasLength(2));
      expect(find.text(l10n.keptQuiet), findsOneWidget);
    });

    testWidgets('Back keeps it quiet', (t) async {
      await show(t);
      await mark(t);
      await t.tapAt(Offset.zero);
      await t.pumpAndSettle();
      expect(places.saved, isEmpty);
      expect(quiet.saved, hasLength(2));
    });

    testWidgets('choosing Reminder Place swaps, keeping other places', (
      t,
    ) async {
      await show(t);
      await mark(t);
      await tapText(t, l10n.makeReminderPlace);
      expect(places.saved, hasLength(1));
      expect(quiet.saved.single.place.id, 'other');
      expect(link.toldPlaces, 1);
      expect(link.toldQuiet, 1);
    });

    testWidgets('a failed save never leaves it as both', (t) async {
      quiet.failWrites = true;
      await show(t);
      await mark(t);
      await tapText(t, l10n.makeReminderPlace);
      expect(places.saved, isEmpty);
      expect(find.text(l10n.saveFailed), findsOneWidget);
    });
  });

  group('AC-11.4: marking a Quiet Place at a Reminder Place', () {
    Future<void> showQuiet(WidgetTester t) => pump(
      t,
      QuietPlacesScreen(
        store: quiet,
        reminderPlaces: places,
        location: location,
        link: link,
        now: () => now,
      ),
    );

    setUp(
      () => places.saved = [place('p', pool), place('other', far, 'Магазин')],
    );

    testWidgets('keeping the Reminder Place saves nothing', (t) async {
      await showQuiet(t);
      await tapText(t, l10n.markQuietPlace);
      expect(find.text(l10n.clashIsReminderPlace), findsOneWidget);
      await tapText(t, l10n.keepReminderPlace);
      expect(quiet.saved, isEmpty);
      expect(places.saved, hasLength(2));
    });

    testWidgets('choosing quiet swaps, keeping other places', (t) async {
      await showQuiet(t);
      await tapText(t, l10n.markQuietPlace);
      await tapText(t, l10n.makeQuiet);
      expect(quiet.saved, hasLength(1));
      expect(places.saved.single.place.id, 'other');
      expect(link.toldPlaces, 1);
      expect(link.toldQuiet, 1);
    });

    testWidgets('a failed save never leaves it as both', (t) async {
      places.failWrites = true;
      await showQuiet(t);
      await tapText(t, l10n.markQuietPlace);
      await tapText(t, l10n.makeQuiet);
      expect(quiet.saved, isEmpty);
      expect(find.text(l10n.saveFailed), findsOneWidget);
    });
  });

  group('AC-11.7: removing', () {
    setUp(() => places.saved = [place('a', pool), place('b', far, 'Магазин')]);

    testWidgets('confirming removes that one and tells the service', (t) async {
      await show(t);
      await tapText(t, l10n.removeNamed('Бассейн'));
      await tapText(t, l10n.confirmRemove);
      expect(places.saved.single.place.id, 'b');
      expect(link.toldPlaces, 1);
      expect(find.text(l10n.reminderPlaceRemoved), findsOneWidget);
    });

    testWidgets('cancelling keeps it', (t) async {
      await show(t);
      await tapText(t, l10n.removeNamed('Бассейн'));
      await tapText(t, l10n.cancel);
      expect(places.saved, hasLength(2));
      expect(link.toldPlaces, 0);
    });
  });
}

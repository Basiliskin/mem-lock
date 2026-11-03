import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';
import 'package:leavecheck/domain/quiet_place_record.dart';
import 'package:leavecheck/domain/reminder_place_record.dart';
import 'package:leavecheck/l10n/l10n.dart';

import '../support/l10n.dart';

import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/ui/quiet_places_screen.dart';

const home = GeoPoint(55.75, 37.61);
const shop = GeoPoint(55.80, 37.70);
final now = DateTime(2026, 11, 1, 14, 32);

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
  FakeFix(this.fix);
  LocationFix? fix;
  bool throws = false;
  @override
  Future<LocationFix?> currentFix() async {
    if (throws) throw StateError('location off');
    return fix;
  }
}

class FakeLink implements WatcherLink {
  int told = 0;
  bool fails = false;
  @override
  void quietPlacesChanged() {
    told++;
    if (fails) throw StateError('no service');
  }

  @override
  void reminderPlacesChanged() {}
  @override
  void languageChanged() {}

  @override
  void homeWifiChanged() {}
  @override
  void detectionSettingsChanged() {}
}

class _NoReminderPlaces implements ReminderPlaceStore {
  @override
  Future<List<ReminderPlaceRecord>> read() async => const [];
  @override
  Future<void> write(List<ReminderPlaceRecord> places) async {}
}

void main() {
  late FakeQuiet quiet;
  late FakeFix location;
  late FakeLink link;

  setUp(() {
    quiet = FakeQuiet();
    location = FakeFix(LocationFix(now, home, 10));
    link = FakeLink();
  });

  Future<void> show(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: testLocale,

        home: QuietPlacesScreen(
          store: quiet,
          reminderPlaces: _NoReminderPlaces(),
          location: location,
          link: link,
          now: () => now,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> mark(WidgetTester t) async {
    await t.tap(find.text(l10n.markQuietPlace));
    await t.pumpAndSettle();
  }

  QuietPlaceRecord saved(String id, GeoPoint p) =>
      QuietPlaceRecord(QuietPlace(id, p), now);

  testWidgets('an empty list says so', (t) async {
    await show(t);
    expect(find.text(l10n.noQuietPlaces), findsOneWidget);
  });

  testWidgets('AC-6.1: marking saves here and tells the service', (t) async {
    await show(t);
    await mark(t);
    expect(quiet.saved.single.place.point, home);
    expect(quiet.saved.single.markedAt, now);
    expect(link.told, 1);
    expect(find.text(l10n.quietMarkedAt(now)), findsOneWidget);
    expect(find.text(l10n.noQuietPlaces), findsNothing);
  });

  testWidgets('AC-6.2: a second place is added, not replacing', (t) async {
    quiet.saved = [saved('old', shop)];
    await show(t);
    await mark(t);
    expect(quiet.saved, hasLength(2));
    expect(quiet.saved.map((r) => r.place.id).toSet(), hasLength(2));
  });

  group('AC-6.4: no usable fix saves nothing and says why', () {
    Future<void> expectRefused(WidgetTester t) async {
      await show(t);
      await mark(t);
      expect(quiet.saved, isEmpty);
      expect(link.told, 0);
      expect(find.text(l10n.noFixToMark), findsOneWidget);
    }

    testWidgets('no fix', (t) async {
      location.fix = null;
      await expectRefused(t);
    });

    testWidgets('location failing', (t) async {
      location.throws = true;
      await expectRefused(t);
    });

    testWidgets('fix too inaccurate to trust', (t) async {
      location.fix = LocationFix(now, home, maxAccuracyMeters + 1);
      await expectRefused(t);
    });
  });

  testWidgets('a working retry clears the message', (t) async {
    location.fix = null;
    await show(t);
    await mark(t);
    location.fix = LocationFix(now, home, 10);
    await mark(t);
    expect(find.text(l10n.noFixToMark), findsNothing);
    expect(quiet.saved, hasLength(1));
  });

  testWidgets('marking the same place twice adds nothing', (t) async {
    quiet.saved = [saved('old', home)];
    await show(t);
    await mark(t);
    expect(quiet.saved, hasLength(1));
    expect(link.told, 0);
    expect(find.text(l10n.alreadyQuiet), findsOneWidget);
  });

  testWidgets('a failed save says so and shows no new place', (t) async {
    quiet.failWrites = true;
    await show(t);
    await mark(t);
    expect(find.text(l10n.saveFailed), findsOneWidget);
    expect(find.text(l10n.quietMarkedAt(now)), findsNothing);
    expect(link.told, 0);
  });

  testWidgets('a service that can not be told does not fail marking', (
    t,
  ) async {
    link.fails = true;
    await show(t);
    await mark(t);
    expect(quiet.saved, hasLength(1));
    expect(find.text(l10n.saveFailed), findsNothing);
  });

  group('removing', () {
    Future<void> pressRemove(WidgetTester t) async {
      await t.tap(find.text(l10n.remove));
      await t.pumpAndSettle();
    }

    testWidgets('AC-6.3: confirming removes that one and tells the service', (
      t,
    ) async {
      quiet.saved = [saved('a', home), saved('b', shop)];
      await show(t);
      await t.tap(find.text(l10n.remove).first);
      await t.pumpAndSettle();
      await t.tap(find.text(l10n.confirmRemove));
      await t.pumpAndSettle();
      expect(quiet.saved.single.place.id, 'b');
      expect(link.told, 1);
    });

    testWidgets('cancelling keeps it', (t) async {
      quiet.saved = [saved('a', home)];
      await show(t);
      await pressRemove(t);
      await t.tap(find.text(l10n.cancel));
      await t.pumpAndSettle();
      expect(quiet.saved, hasLength(1));
      expect(link.told, 0);
    });

    testWidgets('a failed save keeps it on screen and says so', (t) async {
      quiet.saved = [saved('a', home)];
      await show(t);
      quiet.failWrites = true;
      await pressRemove(t);
      await t.tap(find.text(l10n.confirmRemove));
      await t.pumpAndSettle();
      expect(find.text(l10n.remove), findsOneWidget);
      expect(find.text(l10n.saveFailed), findsOneWidget);
    });
  });
}

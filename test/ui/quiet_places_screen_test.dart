import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/quiet_place_record.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/quiet_places_screen.dart';

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
        home: QuietPlacesScreen(
          store: quiet,
          location: location,
          link: link,
          now: () => now,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> mark(WidgetTester t) async {
    await t.tap(find.text(Strings.markQuietPlace));
    await t.pumpAndSettle();
  }

  QuietPlaceRecord saved(String id, GeoPoint p) =>
      QuietPlaceRecord(QuietPlace(id, p), now);

  testWidgets('an empty list says so', (t) async {
    await show(t);
    expect(find.text(Strings.noQuietPlaces), findsOneWidget);
  });

  testWidgets('AC-6.1: marking saves here and tells the service', (t) async {
    await show(t);
    await mark(t);
    expect(quiet.saved.single.place.point, home);
    expect(quiet.saved.single.markedAt, now);
    expect(link.told, 1);
    expect(find.text(Strings.quietMarkedAt(now)), findsOneWidget);
    expect(find.text(Strings.noQuietPlaces), findsNothing);
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
      expect(find.text(Strings.noFixToMark), findsOneWidget);
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
    expect(find.text(Strings.noFixToMark), findsNothing);
    expect(quiet.saved, hasLength(1));
  });

  testWidgets('marking the same place twice adds nothing', (t) async {
    quiet.saved = [saved('old', home)];
    await show(t);
    await mark(t);
    expect(quiet.saved, hasLength(1));
    expect(link.told, 0);
    expect(find.text(Strings.alreadyQuiet), findsOneWidget);
  });

  testWidgets('a failed save says so and shows no new place', (t) async {
    quiet.failWrites = true;
    await show(t);
    await mark(t);
    expect(find.text(Strings.saveFailed), findsOneWidget);
    expect(find.text(Strings.quietMarkedAt(now)), findsNothing);
    expect(link.told, 0);
  });

  testWidgets('a service that can not be told does not fail marking', (
    t,
  ) async {
    link.fails = true;
    await show(t);
    await mark(t);
    expect(quiet.saved, hasLength(1));
    expect(find.text(Strings.saveFailed), findsNothing);
  });

  group('removing', () {
    Future<void> pressRemove(WidgetTester t) async {
      await t.tap(find.text(Strings.remove));
      await t.pumpAndSettle();
    }

    testWidgets('AC-6.3: confirming removes that one and tells the service', (
      t,
    ) async {
      quiet.saved = [saved('a', home), saved('b', shop)];
      await show(t);
      await t.tap(find.text(Strings.remove).first);
      await t.pumpAndSettle();
      await t.tap(find.text(Strings.confirmRemove));
      await t.pumpAndSettle();
      expect(quiet.saved.single.place.id, 'b');
      expect(link.told, 1);
    });

    testWidgets('cancelling keeps it', (t) async {
      quiet.saved = [saved('a', home)];
      await show(t);
      await pressRemove(t);
      await t.tap(find.text(Strings.cancel));
      await t.pumpAndSettle();
      expect(quiet.saved, hasLength(1));
      expect(link.told, 0);
    });

    testWidgets('a failed save keeps it on screen and says so', (t) async {
      quiet.saved = [saved('a', home)];
      await show(t);
      quiet.failWrites = true;
      await pressRemove(t);
      await t.tap(find.text(Strings.confirmRemove));
      await t.pumpAndSettle();
      expect(find.text(Strings.remove), findsOneWidget);
      expect(find.text(Strings.saveFailed), findsOneWidget);
    });
  });
}

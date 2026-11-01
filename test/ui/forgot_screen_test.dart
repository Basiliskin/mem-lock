import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/battery.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/domain/geo.dart';
import 'package:leavecheck/domain/last_place_record.dart';
import 'package:leavecheck/l10n/l10n.dart';

import '../support/l10n.dart';

import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/ui/forgot_screen.dart';
import 'package:leavecheck/ui/main_screen.dart';

final place = LastPlaceRecord(
  const GeoPoint(55.751244, 37.618423),
  DateTime(2026, 11, 1, 14, 32),
  ReminderSource.stay,
);

class FakeMap implements MapLauncher {
  FakeMap({this.works = true});
  bool works;
  bool fails = false;
  GeoPoint? opened;
  @override
  Future<bool> open(GeoPoint point) async {
    if (fails) throw StateError('no');
    opened = point;
    return works;
  }
}

class FakeHost implements BackgroundHost {
  @override
  Future<bool> isRunning() async => true;
  @override
  Future<bool> start() async => true;
}

class FakePlaces implements LastPlaceStore {
  FakePlaces([this.record]);
  LastPlaceRecord? record;
  @override
  Future<List<LastPlaceRecord>> read() async => [?record];
  @override
  Future<void> save(LastPlaceRecord value) async => record = value;
}

void main() {
  group('whenText', () {
    final now = DateTime(2026, 11, 1, 18);
    test('same day shows only the time', () {
      expect(
        l10n.whenText(DateTime(2026, 11, 1, 9, 5), now),
        l10n.whenToday('09:05'),
      );
    });
    test('another day also shows the date', () {
      expect(
        l10n.whenText(DateTime(2026, 10, 31, 14, 32), now),
        l10n.whenOtherDay('14:32', l10n.monthDay('31', 'm10')),
      );
    });
  });

  group('ForgotScreen', () {
    Future<void> show(WidgetTester t, MapLauncher map) => t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: testLocale,

        home: ForgotScreen(
          place: place,
          map: map,
          now: () => DateTime(2026, 11, 1, 18),
        ),
      ),
    );

    testWidgets('AC-5.1: shows calm text, the time and a map button', (
      t,
    ) async {
      await show(t, FakeMap());
      expect(find.text(l10n.dontWorry), findsOneWidget);
      expect(find.text(l10n.whenToday('14:32')), findsOneWidget);
      expect(find.text(l10n.openMap), findsOneWidget);
    });

    testWidgets('AC-5.2: the button opens the map at the Last Place', (
      t,
    ) async {
      final map = FakeMap();
      await show(t, map);
      await t.tap(find.text(l10n.openMap));
      await t.pumpAndSettle();
      expect(map.opened, place.point);
      expect(find.textContaining('55.75124'), findsNothing);
    });

    testWidgets('AC-5.6: nothing is opened without the tap', (t) async {
      final map = FakeMap();
      await show(t, map);
      await t.pumpAndSettle();
      expect(map.opened, isNull);
    });

    testWidgets('AC-5.4: no map app shows a message and coordinates', (
      t,
    ) async {
      await show(t, FakeMap(works: false));
      await t.tap(find.text(l10n.openMap));
      await t.pumpAndSettle();
      expect(find.textContaining(l10n.noMapApp), findsOneWidget);
      expect(find.textContaining('55.75124, 37.61842'), findsOneWidget);
      expect(find.text(l10n.whenToday('14:32')), findsOneWidget);
    });

    testWidgets('a map error is treated the same way', (t) async {
      await show(t, FakeMap()..fails = true);
      await t.tap(find.text(l10n.openMap));
      await t.pumpAndSettle();
      expect(find.textContaining(l10n.noMapApp), findsOneWidget);
    });
  });

  group('previous place', () {
    final previous = LastPlaceRecord(
      const GeoPoint(55.8, 37.7),
      DateTime(2026, 11, 1, 11, 5),
      ReminderSource.stay,
    );

    Future<void> showBoth(WidgetTester t, MapLauncher map) => t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: testLocale,

        home: ForgotScreen(
          place: place,
          previous: previous,
          map: map,
          now: () => DateTime(2026, 11, 1, 18),
        ),
      ),
    );

    testWidgets('shows its time and its own map button', (t) async {
      await showBoth(t, FakeMap());
      expect(find.text(l10n.whenToday('14:32')), findsOneWidget);
      expect(find.text(l10n.previousToday('11:05')), findsOneWidget);
      expect(find.text(l10n.openPreviousMap), findsOneWidget);
    });

    testWidgets('each button opens its own place', (t) async {
      final map = FakeMap();
      await showBoth(t, map);
      await t.tap(find.text(l10n.openPreviousMap));
      await t.pumpAndSettle();
      expect(map.opened, previous.point);
      await t.tap(find.text(l10n.openMap));
      await t.pumpAndSettle();
      expect(map.opened, place.point);
    });

    testWidgets('no map app shows the coordinates of the tapped place', (
      t,
    ) async {
      await showBoth(t, FakeMap(works: false));
      await t.tap(find.text(l10n.openPreviousMap));
      await t.pumpAndSettle();
      expect(find.textContaining('55.80000, 37.70000'), findsOneWidget);
    });

    testWidgets('with one place there is no previous button', (t) async {
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: testLocale,

          home: ForgotScreen(place: place, map: FakeMap()),
        ),
      );
      expect(find.text(l10n.openPreviousMap), findsNothing);
    });
  });

  group('MainScreen', () {
    Future<ValueNotifier<int>> show(WidgetTester t, FakePlaces places) async {
      final requests = ValueNotifier(0);
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: testLocale,

          home: MainScreen(
            host: FakeHost(),
            places: places,
            map: FakeMap(),
            forgotRequests: requests,
            health: FakeHealth(),
            battery: FakeBattery(),
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
      return requests;
    }

    testWidgets('no Last Place, no forgot button', (t) async {
      await show(t, FakePlaces());
      expect(find.text(l10n.actionForgot), findsNothing);
    });

    testWidgets('the forgot button opens the screen', (t) async {
      await show(t, FakePlaces(place));
      await t.tap(find.text(l10n.actionForgot));
      await t.pumpAndSettle();
      expect(find.text(l10n.dontWorry), findsOneWidget);
    });

    testWidgets('the notification button opens the screen', (t) async {
      final requests = await show(t, FakePlaces(place));
      requests.value++;
      await t.pumpAndSettle();
      expect(find.text(l10n.dontWorry), findsOneWidget);
    });

    testWidgets('a request made before the screen opened still counts', (
      t,
    ) async {
      final requests = ValueNotifier(1);
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: testLocale,

          home: MainScreen(
            host: FakeHost(),
            places: FakePlaces(place),
            map: FakeMap(),
            forgotRequests: requests,
            health: FakeHealth(),
            battery: FakeBattery(),
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(l10n.dontWorry), findsOneWidget);
    });

    testWidgets('a notification request with no place stays on main', (
      t,
    ) async {
      final requests = await show(t, FakePlaces());
      requests.value++;
      await t.pumpAndSettle();
      expect(find.text(l10n.dontWorry), findsNothing);
      expect(find.text(l10n.protecting), findsOneWidget);
    });
  });

  group('LastPlaceRecord text', () {
    test('survives a round trip', () {
      final back = LastPlaceRecord.parse(place.encode())!;
      expect(back.point, place.point);
      expect(back.time, place.time);
      expect(back.source, ReminderSource.stay);
    });
    test('unreadable text gives nothing', () {
      expect(LastPlaceRecord.parse('garbage'), isNull);
      expect(LastPlaceRecord.parse('{}'), isNull);
    });
  });
}

class FakeHealth implements HealthCheck {
  FakeHealth([this.problem]);
  ProtectionProblem? problem;
  final fixed = <ProtectionProblem>[];
  bool fails = false;
  @override
  Future<ProtectionProblem?> check() async {
    if (fails) throw StateError('plugin');
    return problem;
  }

  @override
  Future<void> fix(ProtectionProblem problem) async => fixed.add(problem);
}

class FakeBattery implements BatterySource {
  FakeBattery([this.reading = const BatteryReading(80, charging: false)]);
  BatteryReading reading;
  bool fails = false;
  @override
  Future<BatteryReading> read() async {
    if (fails) throw StateError('plugin');
    return reading;
  }
}

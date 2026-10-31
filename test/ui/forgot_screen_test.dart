import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/forgot_screen.dart';
import 'package:geo_alert/ui/main_screen.dart';

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
  Future<LastPlaceRecord?> read() async => record;
  @override
  Future<void> save(LastPlaceRecord value) async => record = value;
}

void main() {
  group('whenText', () {
    final now = DateTime(2026, 11, 1, 18);
    test('same day shows only the time', () {
      expect(
        Strings.whenText(DateTime(2026, 11, 1, 9, 5), now),
        'Вы были здесь до 09:05',
      );
    });
    test('another day also shows the date', () {
      expect(
        Strings.whenText(DateTime(2026, 10, 31, 14, 32), now),
        'Вы были здесь до 14:32, 31 октября',
      );
    });
  });

  group('ForgotScreen', () {
    Future<void> show(WidgetTester t, MapLauncher map) => t.pumpWidget(
      MaterialApp(
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
      expect(find.text(Strings.dontWorry), findsOneWidget);
      expect(find.text('Вы были здесь до 14:32'), findsOneWidget);
      expect(find.text(Strings.openMap), findsOneWidget);
    });

    testWidgets('AC-5.2: the button opens the map at the Last Place', (
      t,
    ) async {
      final map = FakeMap();
      await show(t, map);
      await t.tap(find.text(Strings.openMap));
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
      await t.tap(find.text(Strings.openMap));
      await t.pumpAndSettle();
      expect(find.textContaining(Strings.noMapApp), findsOneWidget);
      expect(find.textContaining('55.75124, 37.61842'), findsOneWidget);
      expect(find.text('Вы были здесь до 14:32'), findsOneWidget);
    });

    testWidgets('a map error is treated the same way', (t) async {
      await show(t, FakeMap()..fails = true);
      await t.tap(find.text(Strings.openMap));
      await t.pumpAndSettle();
      expect(find.textContaining(Strings.noMapApp), findsOneWidget);
    });
  });

  group('MainScreen', () {
    Future<ValueNotifier<int>> show(WidgetTester t, FakePlaces places) async {
      final requests = ValueNotifier(0);
      await t.pumpWidget(
        MaterialApp(
          home: MainScreen(
            host: FakeHost(),
            places: places,
            map: FakeMap(),
            forgotRequests: requests,
            health: FakeHealth(),
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
      return requests;
    }

    testWidgets('no Last Place, no forgot button', (t) async {
      await show(t, FakePlaces());
      expect(find.text(Strings.actionForgot), findsNothing);
    });

    testWidgets('the forgot button opens the screen', (t) async {
      await show(t, FakePlaces(place));
      await t.tap(find.text(Strings.actionForgot));
      await t.pumpAndSettle();
      expect(find.text(Strings.dontWorry), findsOneWidget);
    });

    testWidgets('the notification button opens the screen', (t) async {
      final requests = await show(t, FakePlaces(place));
      requests.value++;
      await t.pumpAndSettle();
      expect(find.text(Strings.dontWorry), findsOneWidget);
    });

    testWidgets('a request made before the screen opened still counts', (
      t,
    ) async {
      final requests = ValueNotifier(1);
      await t.pumpWidget(
        MaterialApp(
          home: MainScreen(
            host: FakeHost(),
            places: FakePlaces(place),
            map: FakeMap(),
            forgotRequests: requests,
            health: FakeHealth(),
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(Strings.dontWorry), findsOneWidget);
    });

    testWidgets('a notification request with no place stays on main', (
      t,
    ) async {
      final requests = await show(t, FakePlaces());
      requests.value++;
      await t.pumpAndSettle();
      expect(find.text(Strings.dontWorry), findsNothing);
      expect(find.text(Strings.protecting), findsOneWidget);
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

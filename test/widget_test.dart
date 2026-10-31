import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/main_screen.dart';

class FakeHost implements BackgroundHost {
  FakeHost({this.running = false, this.startWorks = true});
  bool running;
  bool startWorks;
  int starts = 0;
  @override
  Future<bool> isRunning() async => running;
  @override
  Future<bool> start() async {
    starts++;
    running = startWorks;
    return startWorks;
  }
}

Future<void> show(WidgetTester t, BackgroundHost host) async {
  await t.pumpWidget(
    MaterialApp(
      home: MainScreen(
        host: host,
        places: _NoPlaces(),
        map: _NoMap(),
        forgotRequests: ValueNotifier(0),
        helperSettings: (_) => const Text('helper-settings'),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('AC-8.4: a running service shows protecting', (t) async {
    await show(t, FakeHost(running: true));
    expect(find.text(Strings.protecting), findsOneWidget);
    expect(find.text(Strings.nothingToDo), findsOneWidget);
    expect(find.text(Strings.enable), findsNothing);
  });

  testWidgets('a stopped service never claims protection', (t) async {
    await show(t, FakeHost());
    expect(find.text(Strings.notProtecting), findsOneWidget);
    expect(find.text(Strings.protecting), findsNothing);
    expect(find.text(Strings.enable), findsOneWidget);
  });

  testWidgets('enabling starts the service and updates status', (t) async {
    final host = FakeHost();
    await show(t, host);
    await t.tap(find.text(Strings.enable));
    await t.pumpAndSettle();
    expect(host.starts, 1);
    expect(find.text(Strings.protecting), findsOneWidget);
  });

  group('Helper entry', () {
    Future<void> hold(WidgetTester t, Duration time) async {
      final g = await t.startGesture(
        t.getCenter(find.text(Strings.helperEntry)),
      );
      await t.pump(time);
      await g.up();
      await t.pumpAndSettle();
    }

    testWidgets('a 2-second press opens the Helper settings', (t) async {
      await show(t, FakeHost(running: true));
      await hold(t, const Duration(seconds: 2));
      expect(find.text('helper-settings'), findsOneWidget);
    });

    testWidgets('a short press or tap does not', (t) async {
      await show(t, FakeHost(running: true));
      await hold(t, const Duration(seconds: 1));
      expect(find.text('helper-settings'), findsNothing);
      await t.tap(find.text(Strings.helperEntry));
      await t.pumpAndSettle();
      expect(find.text('helper-settings'), findsNothing);
    });

    testWidgets('TalkBack has an equal action', (t) async {
      await show(t, FakeHost(running: true));
      final handle = t.ensureSemantics();
      t
          .getSemantics(find.text(Strings.helperEntry))
          .owner!
          .performAction(
            t.getSemantics(find.text(Strings.helperEntry)).id,
            SemanticsAction.longPress,
          );
      await t.pumpAndSettle();
      expect(find.text('helper-settings'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('a failed start says so and still offers the button', (t) async {
    await show(t, FakeHost(startWorks: false));
    await t.tap(find.text(Strings.enable));
    await t.pumpAndSettle();
    expect(find.text(Strings.notProtecting), findsOneWidget);
    expect(find.text(Strings.startFailed), findsOneWidget);
    expect(find.text(Strings.enable), findsOneWidget);
  });
}

class _NoPlaces implements LastPlaceStore {
  @override
  Future<LastPlaceRecord?> read() async => null;
  @override
  Future<void> save(LastPlaceRecord value) async {}
}

class _NoMap implements MapLauncher {
  @override
  Future<bool> open(GeoPoint point) async => false;
}

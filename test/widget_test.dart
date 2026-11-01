import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/battery.dart';
import 'package:geo_alert/domain/geo.dart';
import 'package:geo_alert/domain/last_place_record.dart';
import 'package:geo_alert/l10n/l10n.dart';

import 'support/l10n.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: testLocale,

      home: MainScreen(
        host: host,
        places: _NoPlaces(),
        map: _NoMap(),
        forgotRequests: ValueNotifier(0),
        health: FakeHealth(),
        battery: FakeBattery(),
        helperSettings: (_) => const Text('helper-settings'),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('AC-8.4: a running service shows protecting', (t) async {
    await show(t, FakeHost(running: true));
    expect(find.text(l10n.protecting), findsOneWidget);
    expect(find.text(l10n.nothingToDo), findsOneWidget);
    expect(find.text(l10n.enable), findsNothing);
  });

  testWidgets('a stopped service never claims protection', (t) async {
    await show(t, FakeHost());
    expect(find.text(l10n.notProtecting), findsOneWidget);
    expect(find.text(l10n.protecting), findsNothing);
    expect(find.text(l10n.enable), findsOneWidget);
  });

  testWidgets('enabling starts the service and updates status', (t) async {
    final host = FakeHost();
    await show(t, host);
    await t.tap(find.text(l10n.enable));
    await t.pumpAndSettle();
    expect(host.starts, 1);
    expect(find.text(l10n.protecting), findsOneWidget);
  });

  group('warnings', () {
    Future<void> showWith(WidgetTester t, FakeHost host, FakeHealth h) async {
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: testLocale,

          home: MainScreen(
            host: host,
            places: _NoPlaces(),
            map: _NoMap(),
            forgotRequests: ValueNotifier(0),
            health: h,
            battery: FakeBattery(),
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    final reasons = {
      ProtectionProblem.locationOff: l10n.problemLocationOff,
      ProtectionProblem.locationPermission: l10n.problemLocationPermission,
      ProtectionProblem.notifications: l10n.problemNotifications,
      ProtectionProblem.activityPermission: l10n.problemActivityPermission,
    };
    for (final e in reasons.entries) {
      testWidgets('AC-8.2: ${e.key.name} warns with the reason and a fix', (
        t,
      ) async {
        final h = FakeHealth(e.key);
        await showWith(t, FakeHost(running: true), h);
        expect(find.text(l10n.notProtecting), findsOneWidget);
        expect(find.text(l10n.protecting), findsNothing);
        expect(find.text(e.value), findsOneWidget);
        await t.tap(find.text(l10n.fix));
        await t.pump();
        expect(h.fixed, [e.key]);
      });
    }

    testWidgets('AC-8.3: returning after a fix clears the warning', (t) async {
      final h = FakeHealth(ProtectionProblem.locationOff);
      await showWith(t, FakeHost(running: true), h);
      h.problem = null;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.text(l10n.protecting), findsOneWidget);
      expect(find.text(l10n.fix), findsNothing);
    });

    testWidgets('a change is noticed while the screen stays open', (t) async {
      final h = FakeHealth();
      await showWith(t, FakeHost(running: true), h);
      h.problem = ProtectionProblem.locationOff;
      await t.pump(const Duration(seconds: 6));
      await t.pump();
      expect(find.text(l10n.notProtecting), findsOneWidget);
    });

    testWidgets('a stopped service with a problem offers the fix first', (
      t,
    ) async {
      await showWith(
        t,
        FakeHost(),
        FakeHealth(ProtectionProblem.locationPermission),
      );
      expect(find.text(l10n.fix), findsOneWidget);
      expect(find.text(l10n.enable), findsNothing);
    });

    testWidgets('a failing check does not clear a warning', (t) async {
      final h = FakeHealth(ProtectionProblem.locationOff);
      await showWith(t, FakeHost(running: true), h);
      h.fails = true;
      await t.pump(const Duration(seconds: 6));
      await t.pump();
      expect(find.text(l10n.notProtecting), findsOneWidget);
      expect(find.text(l10n.protecting), findsNothing);
    });
  });

  group('Helper entry', () {
    Future<void> hold(WidgetTester t, Duration time) async {
      final g = await t.startGesture(t.getCenter(find.text(l10n.helperEntry)));
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
      await t.tap(find.text(l10n.helperEntry));
      await t.pumpAndSettle();
      expect(find.text('helper-settings'), findsNothing);
    });

    testWidgets('TalkBack has an equal action', (t) async {
      await show(t, FakeHost(running: true));
      final handle = t.ensureSemantics();
      t
          .getSemantics(find.text(l10n.helperEntry))
          .owner!
          .performAction(
            t.getSemantics(find.text(l10n.helperEntry)).id,
            SemanticsAction.longPress,
          );
      await t.pumpAndSettle();
      expect(find.text('helper-settings'), findsOneWidget);
      handle.dispose();
    });
  });

  group('LowBatteryNote', () {
    Future<void> showBattery(WidgetTester t, FakeBattery battery) async {
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: testLocale,

          home: MainScreen(
            host: FakeHost(running: true),
            places: _NoPlaces(),
            map: _NoMap(),
            forgotRequests: ValueNotifier(0),
            health: FakeHealth(),
            battery: battery,
            helperSettings: (_) => const Text('helper-settings'),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows while the battery is low', (t) async {
      await showBattery(
        t,
        FakeBattery(const BatteryReading(15, charging: false)),
      );
      expect(find.text(l10n.lowBattery), findsOneWidget);
      expect(find.text(l10n.protecting), findsOneWidget);
    });

    testWidgets('hidden when fine, and once charging', (t) async {
      final b = FakeBattery();
      await showBattery(t, b);
      expect(find.text(l10n.lowBattery), findsNothing);
      b.reading = const BatteryReading(15, charging: false);
      await t.pump(const Duration(seconds: 6));
      await t.pump();
      expect(find.text(l10n.lowBattery), findsOneWidget);
      b.reading = const BatteryReading(15, charging: true);
      await t.pump(const Duration(seconds: 6));
      await t.pump();
      expect(find.text(l10n.lowBattery), findsNothing);
    });

    testWidgets('a failing reading leaves the screen working', (t) async {
      await showBattery(t, FakeBattery()..fails = true);
      expect(find.text(l10n.protecting), findsOneWidget);
      expect(find.text(l10n.lowBattery), findsNothing);
    });
  });

  testWidgets('a failed start says so and still offers the button', (t) async {
    await show(t, FakeHost(startWorks: false));
    await t.tap(find.text(l10n.enable));
    await t.pumpAndSettle();
    expect(find.text(l10n.notProtecting), findsOneWidget);
    expect(find.text(l10n.startFailed), findsOneWidget);
    expect(find.text(l10n.enable), findsOneWidget);
  });
}

class _NoPlaces implements LastPlaceStore {
  @override
  Future<List<LastPlaceRecord>> read() async => const [];
  @override
  Future<void> save(LastPlaceRecord value) async {}
}

class _NoMap implements MapLauncher {
  @override
  Future<bool> open(GeoPoint point) async => false;
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

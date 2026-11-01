import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/l10n/l10n.dart';
import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/ui/advanced_settings_screen.dart';
import 'package:leavecheck/ui/helper_settings_screen.dart';
import 'package:leavecheck/ui/stay_setting_screen.dart';

import '../support/l10n.dart';

class FakeStore implements DetectionSettingsStore {
  FakeStore([this.saved = DetectionSettings.normal]);
  DetectionSettings saved;
  bool failWrites = false;
  int writes = 0;
  @override
  Future<DetectionSettings> read() async => saved;
  @override
  Future<void> write(DetectionSettings value) async {
    if (failWrites) throw StateError('disk');
    writes++;
    saved = value;
  }
}

class FakeLink implements WatcherLink {
  int told = 0;
  @override
  void quietPlacesChanged() {}
  @override
  void reminderPlacesChanged() {}
  @override
  void languageChanged() {}
  @override
  void detectionSettingsChanged() => told++;
}

Finder field(DetectionValue v) => find.byKey(ValueKey('field-${v.name}'));

void main() {
  late FakeLink link;
  setUp(() => link = FakeLink());

  Future<void> pump(WidgetTester t, Widget home) async {
    t.view.physicalSize = const Size(1200, 4000);
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

  Future<void> show(WidgetTester t, FakeStore store) =>
      pump(t, AdvancedSettingsScreen(store: store, link: link));

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  Future<void> type(WidgetTester t, DetectionValue v, String text) async {
    await t.enterText(field(v), text);
    await t.pump();
  }

  String shown(WidgetTester t, DetectionValue v) =>
      t.widget<TextField>(field(v)).controller!.text;

  group('AC-12.1: values', () {
    testWidgets('shows all four with limits, and saves them', (t) async {
      final store = FakeStore();
      await show(t, store);
      expect(shown(t, DetectionValue.stayTime), '5');
      expect(shown(t, DetectionValue.stayArea), '75');
      expect(shown(t, DetectionValue.vehicleSpeed), '14.4');
      expect(shown(t, DetectionValue.walkingTime), '30');
      expect(
        find.text(l10n.advancedRange('1', '30', l10n.unitMinutes, '5')),
        findsOneWidget,
      );

      await type(t, DetectionValue.stayTime, '10');
      await type(t, DetectionValue.stayArea, '120');
      await type(t, DetectionValue.vehicleSpeed, '12,5');
      await type(t, DetectionValue.walkingTime, '45');
      await tapText(t, l10n.saveValues);

      expect(store.saved.stayTime, const Duration(minutes: 10));
      expect(store.saved.stayMeters, 120);
      expect(store.saved.vehicleKmh, 12.5);
      expect(store.saved.walkingAfterRide, const Duration(seconds: 45));
      expect(link.told, 1);
      expect(find.text(l10n.valuesSaved), findsOneWidget);
    });

    testWidgets('the Ride time limit is not offered', (t) async {
      await show(t, FakeStore());
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('saving untouched keeps exact recommended values', (t) async {
      final store = FakeStore();
      await show(t, store);
      await tapText(t, l10n.saveValues);
      expect(store.saved.vehicleKmh, 14.4);
      expect(store.saved.exactChoice, StayChoice.normal);
    });

    testWidgets('− and + step, snap to the step and stop at limits', (t) async {
      await show(t, FakeStore());
      Future<void> press(String tip) async {
        await t.tap(find.byTooltip(tip));
        await t.pump();
      }

      final speed = l10n.advancedSpeed;
      await press(l10n.increaseValue(speed));
      expect(shown(t, DetectionValue.vehicleSpeed), '15');
      await press(l10n.decreaseValue(speed));
      expect(shown(t, DetectionValue.vehicleSpeed), '14');

      final area = l10n.advancedStayArea;
      await press(l10n.increaseValue(area));
      expect(shown(t, DetectionValue.stayArea), '80');
      await type(t, DetectionValue.stayArea, '298');
      await press(l10n.increaseValue(area));
      expect(shown(t, DetectionValue.stayArea), '300');
      await press(l10n.increaseValue(area));
      expect(shown(t, DetectionValue.stayArea), '300');

      await type(t, DetectionValue.stayTime, '1');
      await press(l10n.decreaseValue(l10n.advancedStayTime));
      expect(shown(t, DetectionValue.stayTime), '1');
    });
  });

  testWidgets('− and + start from recommended after unusable text', (t) async {
    await show(t, FakeStore());
    for (final text in ['abc', 'NaN', '1e999']) {
      await type(t, DetectionValue.vehicleSpeed, text);
      await t.tap(find.byTooltip(l10n.increaseValue(l10n.advancedSpeed)));
      await t.pump();
      expect(shown(t, DetectionValue.vehicleSpeed), '15');
    }
  });

  group('AC-12.2: outside the limits', () {
    final cases = {
      DetectionValue.stayTime: ['0', '31', '2.5', '', 'abc'],
      DetectionValue.stayArea: ['29', '301'],
      DetectionValue.vehicleSpeed: ['6.9', '30.1', 'NaN'],
      DetectionValue.walkingTime: ['9', '121'],
    };
    cases.forEach((value, texts) {
      for (final text in texts) {
        testWidgets('${value.name} "$text" is not saved', (t) async {
          final store = FakeStore();
          await show(t, store);
          await type(t, value, text);
          await tapText(t, l10n.saveValues);
          expect(store.writes, 0);
          expect(link.told, 0);
          expect(find.byKey(ValueKey('error-${value.name}')), findsOneWidget);
        });
      }
    });

    testWidgets('the message names the value and its limits', (t) async {
      await show(t, FakeStore());
      await type(t, DetectionValue.stayTime, '31');
      await tapText(t, l10n.saveValues);
      expect(
        find.text(
          l10n.advancedLimit(
            l10n.advancedStayTime,
            '1',
            '30',
            l10n.unitMinutes,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('out of limits wins over a risk warning', (t) async {
      final store = FakeStore();
      await show(t, store);
      await type(t, DetectionValue.stayTime, '20');
      await type(t, DetectionValue.stayArea, '999');
      await tapText(t, l10n.saveValues);
      expect(find.text(l10n.saveAnyway), findsNothing);
      expect(store.writes, 0);
    });
  });

  group('AC-12.3: risk warning', () {
    Future<void> risky(WidgetTester t, FakeStore store) async {
      await show(t, store);
      await type(t, DetectionValue.stayTime, '16');
      await tapText(t, l10n.saveValues);
    }

    testWidgets('nothing is saved until Save anyway', (t) async {
      final store = FakeStore();
      await risky(t, store);
      expect(find.text(l10n.riskStayTime), findsOneWidget);
      expect(store.writes, 0);
      await tapText(t, l10n.saveAnyway);
      expect(store.saved.stayTime, const Duration(minutes: 16));
      expect(find.text(l10n.riskStayTime), findsNothing);
      expect(link.told, 1);
    });

    testWidgets('Change saves nothing and keeps the typed value', (t) async {
      final store = FakeStore();
      await risky(t, store);
      await tapText(t, l10n.changeValues);
      expect(find.text(l10n.saveAnyway), findsNothing);
      expect(store.writes, 0);
      expect(shown(t, DetectionValue.stayTime), '16');
    });

    testWidgets('editing closes the warning, so a new value is checked', (
      t,
    ) async {
      await risky(t, FakeStore());
      await type(t, DetectionValue.stayTime, '25');
      expect(find.text(l10n.saveAnyway), findsNothing);
    });

    testWidgets('a value at its threshold gives no warning', (t) async {
      final store = FakeStore();
      await show(t, store);
      await type(t, DetectionValue.stayTime, '15');
      await tapText(t, l10n.saveValues);
      expect(find.text(l10n.saveAnyway), findsNothing);
      expect(store.writes, 1);
    });
  });

  const advanced = DetectionSettings(
    stayTime: Duration(minutes: 20),
    stayMeters: 200,
    vehicleKmh: 20,
    walkingAfterRide: Duration(seconds: 60),
  );

  testWidgets('AC-12.4: reset returns every value and saves', (t) async {
    final store = FakeStore(advanced);
    await show(t, store);
    await type(t, DetectionValue.stayArea, '100');
    await tapText(t, l10n.resetToRecommended);
    expect(store.saved.exactChoice, StayChoice.normal);
    expect(store.saved.vehicleKmh, 14.4);
    expect(store.saved.walkingAfterRide, const Duration(seconds: 30));
    expect(shown(t, DetectionValue.stayArea), '75');
    expect(shown(t, DetectionValue.vehicleSpeed), '14.4');
    expect(find.text(l10n.valuesReset), findsOneWidget);
    expect(link.told, 1);
  });

  group('AC-12.5: choices and advanced values', () {
    testWidgets('shows the current preset, then custom values', (t) async {
      await show(t, FakeStore());
      expect(find.text(l10n.advancedNow(l10n.stayNormal)), findsOneWidget);
      await type(t, DetectionValue.stayArea, '120');
      await tapText(t, l10n.saveValues);
      expect(find.text(l10n.advancedNow(l10n.advancedCustom)), findsOneWidget);
      expect(find.text(l10n.advancedPresetHelp), findsOneWidget);
    });

    testWidgets('a preset replaces only Stay values, at once', (t) async {
      final store = FakeStore(advanced);
      await show(t, store);
      await tapText(t, l10n.stayLessOften);
      expect(store.saved.stayTime, const Duration(minutes: 10));
      expect(store.saved.stayMeters, 100);
      expect(store.saved.vehicleKmh, 20);
      expect(store.saved.walkingAfterRide, const Duration(seconds: 60));
      expect(link.told, 1);
      expect(shown(t, DetectionValue.stayTime), '10');
      // Custom Ride values mean the state stays custom.
      expect(find.text(l10n.advancedNow(l10n.advancedCustom)), findsOneWidget);
    });

    testWidgets('a preset does not save unchecked typed Ride values', (
      t,
    ) async {
      final store = FakeStore();
      await show(t, store);
      await type(t, DetectionValue.vehicleSpeed, '999');
      await tapText(t, l10n.stayMoreOften);
      expect(store.saved.vehicleKmh, 14.4);
      expect(shown(t, DetectionValue.vehicleSpeed), '999');
    });

    testWidgets('the simple screen says advanced values are in use', (t) async {
      await pump(t, StaySettingScreen(store: FakeStore(advanced), link: link));
      expect(find.text(l10n.stayCustomNote), findsOneWidget);
    });

    testWidgets('the simple screen has no note for a preset', (t) async {
      await pump(t, StaySettingScreen(store: FakeStore(), link: link));
      expect(find.text(l10n.stayCustomNote), findsNothing);
    });
  });

  testWidgets('a failed save says so and does not tell the service', (t) async {
    final store = FakeStore()..failWrites = true;
    await show(t, store);
    await type(t, DetectionValue.stayArea, '120');
    await tapText(t, l10n.saveValues);
    expect(find.text(l10n.saveFailed), findsOneWidget);
    expect(find.text(l10n.valuesSaved), findsNothing);
    expect(link.told, 0);
  });

  testWidgets('a failed read shows recommended values', (t) async {
    await show(t, _BrokenStore());
    expect(shown(t, DetectionValue.stayTime), '5');
  });

  testWidgets('AC-12.6: reached from the Helper settings menu', (t) async {
    Widget stub(BuildContext _) => const SizedBox();
    await pump(
      t,
      HelperSettingsScreen(
        reminderOptions: stub,
        staySetting: stub,
        advancedSettings: (_) => const Text('advanced-opened'),
        quietPlaces: stub,
        reminderPlaces: stub,
        language: stub,
      ),
    );
    await tapText(t, l10n.advancedSettings);
    expect(find.text('advanced-opened'), findsOneWidget);
  });
}

class _BrokenStore extends FakeStore {
  @override
  Future<DetectionSettings> read() async => throw StateError('disk');
}

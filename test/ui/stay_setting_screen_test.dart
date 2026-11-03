import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/detector.dart';
import 'package:leavecheck/l10n/l10n.dart';

import '../support/l10n.dart';

import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/ui/stay_setting_screen.dart';

class FakeStore implements DetectionSettingsStore {
  FakeStore([this.saved = DetectionSettings.normal]);
  DetectionSettings saved;
  bool failWrites = false;
  @override
  Future<DetectionSettings> read() async => saved;
  @override
  Future<void> write(DetectionSettings value) async {
    if (failWrites) throw StateError('disk');
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
  void homeWifiChanged() {}
  @override
  void detectionSettingsChanged() => told++;
}

void main() {
  late FakeLink link;
  setUp(() => link = FakeLink());

  Future<void> show(WidgetTester t, FakeStore store) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: testLocale,

        home: StaySettingScreen(store: store, link: link),
      ),
    );
    await t.pumpAndSettle();
  }

  bool chosen(WidgetTester t, String label) => t
      .widget<Semantics>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Semantics))
            .first,
      )
      .properties
      .selected!;

  testWidgets('AC-10.2: Normal is chosen when nothing was picked', (t) async {
    await show(t, FakeStore());
    expect(chosen(t, l10n.stayNormal), isTrue);
    expect(chosen(t, l10n.stayMoreOften), isFalse);
  });

  testWidgets('AC-10.1: picking saves and tells the service', (t) async {
    final store = FakeStore();
    await show(t, store);
    await t.tap(find.text(l10n.stayLessOften));
    await t.pumpAndSettle();
    expect(store.saved.choice, StayChoice.lessOften);
    expect(link.told, 1);
    expect(chosen(t, l10n.stayLessOften), isTrue);
  });

  group('with advanced values saved', () {
    const advanced = DetectionSettings(
      stayTime: Duration(minutes: 20),
      stayMeters: 200,
      vehicleKmh: 20,
      walkingAfterRide: Duration(seconds: 60),
    );

    testWidgets('AC-12.5: no choice is shown as chosen', (t) async {
      await show(t, FakeStore(advanced));
      expect(chosen(t, l10n.stayNormal), isFalse);
      expect(chosen(t, l10n.stayMoreOften), isFalse);
      expect(chosen(t, l10n.stayLessOften), isFalse);
    });

    testWidgets('AC-12.5: picking replaces only the Stay values', (t) async {
      final store = FakeStore(advanced);
      await show(t, store);
      await t.tap(find.text(l10n.stayMoreOften));
      await t.pumpAndSettle();
      expect(store.saved.choice, StayChoice.moreOften);
      expect(store.saved.vehicleKmh, 20);
      expect(store.saved.walkingAfterRide, const Duration(seconds: 60));
    });
  });

  testWidgets('a failed save says so and does not tell the service', (t) async {
    final store = FakeStore()..failWrites = true;
    await show(t, store);
    await t.tap(find.text(l10n.stayLessOften));
    await t.pumpAndSettle();
    expect(find.text(l10n.saveFailed), findsOneWidget);
    expect(link.told, 0);
    expect(chosen(t, l10n.stayNormal), isTrue);
  });
}

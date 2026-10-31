import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/stay_setting_screen.dart';

class FakeStore implements StayChoiceStore {
  FakeStore([this.saved = StayChoice.normal]);
  StayChoice saved;
  bool failWrites = false;
  @override
  Future<StayChoice> read() async => saved;
  @override
  Future<void> write(StayChoice value) async {
    if (failWrites) throw StateError('disk');
    saved = value;
  }
}

class FakeLink implements WatcherLink {
  int told = 0;
  @override
  void quietPlacesChanged() {}
  @override
  void staySettingChanged() => told++;
}

void main() {
  late FakeLink link;
  setUp(() => link = FakeLink());

  Future<void> show(WidgetTester t, FakeStore store) async {
    await t.pumpWidget(
      MaterialApp(
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
    expect(chosen(t, Strings.stayNormal), isTrue);
    expect(chosen(t, Strings.stayMoreOften), isFalse);
  });

  testWidgets('AC-10.1: picking saves and tells the service', (t) async {
    final store = FakeStore();
    await show(t, store);
    await t.tap(find.text(Strings.stayLessOften));
    await t.pumpAndSettle();
    expect(store.saved, StayChoice.lessOften);
    expect(link.told, 1);
    expect(chosen(t, Strings.stayLessOften), isTrue);
  });

  testWidgets('a failed save says so and does not tell the service', (t) async {
    final store = FakeStore()..failWrites = true;
    await show(t, store);
    await t.tap(find.text(Strings.stayLessOften));
    await t.pumpAndSettle();
    expect(find.text(Strings.saveFailed), findsOneWidget);
    expect(link.told, 0);
    expect(chosen(t, Strings.stayNormal), isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/check_items.dart';
import 'package:leavecheck/l10n/l10n.dart';
import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/ui/check_items_screen.dart';
import 'package:leavecheck/ui/check_screen.dart';

import '../support/l10n.dart';

class FakeItems implements CheckItemStore {
  FakeItems(this.items);
  List<CheckItem> items;

  @override
  Future<List<CheckItem>> read() async => items;

  @override
  Future<void> write(List<CheckItem> value) async => items = value;
}

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: testLocale,
  home: home,
);

void main() {
  final two = FakeItems([
    const CheckItem.builtIn(BuiltInItem.keys),
    const CheckItem.builtIn(BuiltInItem.glasses, on: false),
    const CheckItem.custom('Umbrella'),
  ]);

  testWidgets('asks one item at a time, skipping ones turned off', (t) async {
    var done = 0;
    await t.pumpWidget(
      app(CheckScreen(items: two, onAllDone: () => done++, onGoBack: () {})),
    );
    await t.pumpAndSettle();
    expect(find.text('${l10n.itemKeys}?'), findsOneWidget);
    await t.tap(find.text('✓ ${l10n.checkYes}'));
    await t.pump();
    expect(find.text('Umbrella?'), findsOneWidget);
    expect(done, 0);
    await t.tap(find.text('✓ ${l10n.checkYes}'));
    await t.pump();
    expect(find.text(l10n.checkAllDone), findsOneWidget);
    expect(done, 1);
  });

  testWidgets('"No" goes back without finishing', (t) async {
    var back = 0;
    var done = 0;
    await t.pumpWidget(
      app(
        CheckScreen(
          items: two,
          onAllDone: () => done++,
          onGoBack: () => back++,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('✗ ${l10n.checkNoGoBack}'));
    expect((back, done), (1, 0));
  });

  testWidgets('with nothing chosen it asks one general question', (t) async {
    await t.pumpWidget(
      app(CheckScreen(items: FakeItems([]), onAllDone: () {}, onGoBack: () {})),
    );
    await t.pumpAndSettle();
    expect(find.text(l10n.checkHaveEverything), findsOneWidget);
  });

  testWidgets('the Helper turns items off and adds their own', (t) async {
    final store = FakeItems(List.of(defaultCheckItems));
    await t.pumpWidget(app(CheckItemsScreen(store: store)));
    await t.pumpAndSettle();
    await t.tap(find.byType(Switch).first);
    await t.pump();
    expect(store.items.first.on, isFalse);
    await t.enterText(find.byType(TextField), 'Umbrella');
    await t.tap(find.text('＋ ${l10n.addItem}'));
    await t.pump();
    expect(store.items.last.text, 'Umbrella');
  });
}

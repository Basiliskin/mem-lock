import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/language.dart';
import 'package:geo_alert/l10n/l10n.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/language_screen.dart';
import 'package:geo_alert/ui/localized_app.dart';

class FakeStore implements LanguageStore {
  AppLanguage? saved;
  bool failWrites = false;
  @override
  Future<AppLanguage?> read() async => saved;
  @override
  Future<void> write(AppLanguage? value) async {
    if (failWrites) throw StateError('disk');
    saved = value;
  }
}

class FakeLink implements WatcherLink {
  int told = 0;
  @override
  void quietPlacesChanged() {}
  @override
  void detectionSettingsChanged() {}
  @override
  void languageChanged() => told++;
}

void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));
  late FakeStore store;
  late FakeLink link;
  late ValueNotifier<AppLanguage?> language;

  setUp(() {
    store = FakeStore();
    link = FakeLink();
    language = ValueNotifier(null);
  });

  Future<void> show(WidgetTester t, {String phone = 'ru'}) async {
    t.platformDispatcher.localesTestValue = [Locale(phone)];
    addTearDown(t.platformDispatcher.clearLocalesTestValue);
    await t.pumpWidget(
      LocalizedApp(
        language: language,
        home: LanguageScreen(store: store, link: link, language: language),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('AC-13.1: follows a Russian phone', (t) async {
    await show(t);
    expect(find.text(ru.languageSetting), findsOneWidget);
  });

  testWidgets('AC-13.2: another phone language gives English', (t) async {
    await show(t, phone: 'de');
    expect(find.text(en.languageSetting), findsOneWidget);
  });

  testWidgets(
    'AC-13.3: a choice saves, tells the service and applies at once',
    (t) async {
      await show(t);
      await t.tap(find.text(en.languageEnglish));
      await t.pumpAndSettle();

      expect(store.saved, AppLanguage.en);
      expect(link.told, 1);
      expect(find.text(en.languageSetting), findsOneWidget);
      expect(find.text(en.reminderTitle), findsOneWidget);
    },
  );

  testWidgets('choosing the phone again clears the saved language', (t) async {
    store.saved = AppLanguage.en;
    language.value = AppLanguage.en;
    await show(t);
    await t.tap(find.text(en.languagePhone));
    await t.pumpAndSettle();

    expect(store.saved, isNull);
    expect(find.text(ru.languageSetting), findsOneWidget);
  });

  testWidgets('a failed save changes nothing and says so', (t) async {
    store.failWrites = true;
    await show(t);
    await t.tap(find.text(en.languageEnglish));
    await t.pumpAndSettle();

    expect(link.told, 0);
    expect(find.text(ru.languageSetting), findsOneWidget);
    expect(find.text(ru.saveFailed), findsOneWidget);
  });
}

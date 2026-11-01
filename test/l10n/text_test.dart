import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/language.dart';
import 'package:leavecheck/l10n/current_text.dart';
import 'package:leavecheck/l10n/l10n.dart';
import 'package:leavecheck/ports/ports.dart';

class FakeLanguageStore implements LanguageStore {
  FakeLanguageStore([this.saved]);
  AppLanguage? saved;
  bool failReads = false;
  @override
  Future<AppLanguage?> read() async {
    if (failReads) throw StateError('disk');
    return saved;
  }

  @override
  Future<void> write(AppLanguage? value) async => saved = value;
}

void main() {
  test('the location disclosure names location and background use', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final ru =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync()) as Map;
    expect(
      en['setupLocationText'],
      allOf(contains('location'), contains('even when the app is closed')),
    );
    expect(
      ru['setupLocationText'],
      allOf(contains('геолокацию'), contains('даже когда приложение закрыто')),
    );
  });

  test('the app is called LeaveCheck in both languages', () {
    for (final arb in ['lib/l10n/app_ru.arb', 'lib/l10n/app_en.arb']) {
      final strings = jsonDecode(File(arb).readAsStringSync()) as Map;
      expect(strings['appName'], 'LeaveCheck');
    }
  });

  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('AC-13.3, AC-13.4: text without a screen', () {
    Future<String> title(FakeLanguageStore store, String phone) async =>
        (await CurrentText(
          store: store,
          phoneLanguage: () => phone,
        ).load()).reminderTitle;

    test('a saved language beats the phone', () async {
      expect(
        await title(FakeLanguageStore(AppLanguage.en), 'ru'),
        en.reminderTitle,
      );
    });

    test('nothing saved follows the phone', () async {
      expect(await title(FakeLanguageStore(), 'ru'), ru.reminderTitle);
      expect(await title(FakeLanguageStore(), 'de'), en.reminderTitle);
    });

    test('unreadable storage follows the phone', () async {
      final store = FakeLanguageStore()..failReads = true;
      expect(await title(store, 'ru'), ru.reminderTitle);
    });

    test('a new choice reaches the next load', () async {
      final store = FakeLanguageStore(AppLanguage.ru);
      expect(await title(store, 'ru'), ru.reminderTitle);
      store.saved = AppLanguage.en;
      expect(await title(store, 'ru'), en.reminderTitle);
    });
  });

  group('dates', () {
    final now = DateTime(2026, 11, 1, 18);
    final yesterday = DateTime(2026, 10, 31, 14, 32);

    test('Russian', () {
      expect(
        ru.whenText(DateTime(2026, 11, 1, 9, 5), now),
        'Вы были здесь до 09:05',
      );
      expect(ru.whenText(yesterday, now), 'Вы были здесь до 14:32, 31 октября');
      expect(
        ru.previousWhen(yesterday, now),
        'Предыдущее: до 14:32, 31 октября',
      );
      expect(ru.quietMarkedAt(yesterday), 'Отмечено 31 октября в 14:32');
    });

    test('English', () {
      expect(
        en.whenText(yesterday, now),
        'You were here until 14:32, October 31',
      );
      expect(
        en.previousWhen(yesterday, now),
        'Previous: until 14:32, October 31',
      );
      expect(en.quietMarkedAt(yesterday), 'Marked October 31 at 14:32');
    });
  });

  test('both translation files have the same text keys', () {
    Set<String> keys(String lang) => (jsonDecode(
      File('lib/l10n/app_$lang.arb').readAsStringSync(),
    ) as Map<String, dynamic>).keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys('en'), keys('ru'));
  });

  test('no Russian is left in the code', () {
    final cyrillic = RegExp('[А-Яа-яЁё]');
    final found = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('generated') &&
            cyrillic.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(found, isEmpty);
  });
}

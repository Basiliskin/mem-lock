import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/language.dart';
import '../l10n/current_text.dart';
import '../l10n/generated/app_localizations.dart';
import '../ports/ports.dart';

class PrefsLanguage implements LanguageStore {
  static const _key = 'language';
  final _prefs = SharedPreferencesAsync();

  /// Null, meaning follow the phone, when nothing was picked or the saved text
  /// is unknown.
  @override
  Future<AppLanguage?> read() async =>
      AppLanguage.values.asNameMap()[await _prefs.getString(_key)];

  @override
  Future<void> write(AppLanguage? value) =>
      value == null ? _prefs.remove(_key) : _prefs.setString(_key, value.name);
}

Future<AppLocalizations> currentText() => CurrentText(
  store: PrefsLanguage(),
  phoneLanguage: () => PlatformDispatcher.instance.locale.languageCode,
).load();

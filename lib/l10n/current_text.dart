import 'dart:ui';

import '../domain/language.dart';
import '../ports/ports.dart';
import 'generated/app_localizations.dart';

/// Text without a screen, for the service and notifications. Read each time,
/// so a new choice reaches the next Reminder.
class CurrentText {
  CurrentText({
    required LanguageStore store,
    required String Function() phoneLanguage,
  }) : _store = store,
       _phoneLanguage = phoneLanguage;

  final LanguageStore _store;
  final String Function() _phoneLanguage;

  Future<AppLocalizations> load() async {
    AppLanguage? saved;
    try {
      saved = await _store.read();
    } on Object {
      // Unreadable storage must not stop a Reminder: follow the phone.
    }
    return lookupAppLocalizations(
      Locale(resolveLanguage(saved, _phoneLanguage()).name),
    );
  }
}

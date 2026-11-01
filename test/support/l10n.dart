import 'package:flutter/widgets.dart';
import 'package:geo_alert/l10n/generated/app_localizations.dart';

/// Run the suite in English with `flutter test --dart-define=TEST_LANG=en`.
const testLanguage = String.fromEnvironment('TEST_LANG', defaultValue: 'ru');
const testLocale = Locale(testLanguage);
final l10n = lookupAppLocalizations(testLocale);

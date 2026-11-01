import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/language.dart';
import '../l10n/l10n.dart';

/// Shows [home] in the chosen language, changing at once when it changes.
class LocalizedApp extends StatelessWidget {
  const LocalizedApp({super.key, required this.language, required this.home});

  final ValueListenable<AppLanguage?> language;
  final Widget home;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: language,
    builder: (_, saved, _) => MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: saved == null ? null : Locale(saved.name),
      // The first language alone decides, as it does in the service.
      localeListResolutionCallback: (locales, _) => Locale(
        resolveLanguage(
          null,
          locales == null || locales.isEmpty ? '' : locales.first.languageCode,
        ).name,
      ),
      home: home,
    ),
  );
}

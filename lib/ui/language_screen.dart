import 'package:flutter/material.dart';

import '../domain/language.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    required this.store,
    required this.link,
    required this.language,
  });

  final LanguageStore store;
  final WatcherLink link;

  /// The app's current choice; null follows the phone.
  final ValueNotifier<AppLanguage?> language;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _failed = false;

  Future<void> _pick(AppLanguage? language) async {
    try {
      await widget.store.write(language);
      // With no service running, it reads the choice at the next Reminder.
      widget.link.languageChanged();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    widget.language.value = language;
    if (mounted) setState(() => _failed = false);
  }

  Widget _option(AppLanguage? language, String label) {
    final chosen = language == widget.language.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: chosen,
        button: true,
        child: ListTile(
          minTileHeight: 64,
          selected: chosen,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: chosen ? 3 : 1),
          ),
          leading: Icon(
            chosen ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(label, style: const TextStyle(fontSize: 20)),
          onTap: () => _pick(language),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(text.languageSetting)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _option(null, text.languagePhone),
          _option(AppLanguage.ru, text.languageRussian),
          _option(AppLanguage.en, text.languageEnglish),
          if (_failed)
            Semantics(
              liveRegion: true,
              child: Text(
                text.saveFailed,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          const SizedBox(height: 12),
          Text(text.languagePreview, style: const TextStyle(fontSize: 16)),
          Text(text.reminderTitle, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

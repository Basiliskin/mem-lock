import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class HelperSettingsScreen extends StatelessWidget {
  const HelperSettingsScreen({
    super.key,
    required this.reminderOptions,
    required this.staySetting,
    required this.quietPlaces,
    required this.language,
  });

  final WidgetBuilder reminderOptions;
  final WidgetBuilder staySetting;
  final WidgetBuilder quietPlaces;
  final WidgetBuilder language;

  Widget _link(BuildContext context, String text, WidgetBuilder builder) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: builder)),
            child: Text(text, style: const TextStyle(fontSize: 20)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.helperSettings)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _link(context, context.l10n.reminderOptions, reminderOptions),
        _link(context, context.l10n.staySetting, staySetting),
        _link(context, context.l10n.quietPlaces, quietPlaces),
        _link(context, context.l10n.languageSetting, language),
      ],
    ),
  );
}

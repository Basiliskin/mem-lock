import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class HelperSettingsScreen extends StatelessWidget {
  const HelperSettingsScreen({
    super.key,
    required this.reminderOptions,
    this.staySetting,
    this.advancedSettings,
    this.quietPlaces,
    this.reminderPlaces,
    this.homeWifi,
    required this.language,
  });

  final WidgetBuilder reminderOptions;
  // Each is hidden when null, so a feature that is switched off has no link.
  final WidgetBuilder? staySetting;
  final WidgetBuilder? advancedSettings;
  final WidgetBuilder? quietPlaces;
  final WidgetBuilder? reminderPlaces;
  final WidgetBuilder? homeWifi;
  final WidgetBuilder language;

  Widget _link(BuildContext context, String text, WidgetBuilder? builder) =>
      builder == null
      ? const SizedBox.shrink()
      : Padding(
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
        _link(context, context.l10n.homeWifi, homeWifi),
        _link(context, context.l10n.reminderOptions, reminderOptions),
        _link(context, context.l10n.staySetting, staySetting),
        _link(context, context.l10n.advancedSettings, advancedSettings),
        _link(context, context.l10n.quietPlaces, quietPlaces),
        _link(context, context.l10n.reminderPlaces, reminderPlaces),
        _link(context, context.l10n.languageSetting, language),
      ],
    ),
  );
}

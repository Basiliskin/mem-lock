import 'package:flutter/material.dart';

import '../l10n/strings.dart';

class HelperSettingsScreen extends StatelessWidget {
  const HelperSettingsScreen({
    super.key,
    required this.reminderOptions,
    required this.quietPlaces,
  });

  final WidgetBuilder reminderOptions;
  final WidgetBuilder quietPlaces;

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
    appBar: AppBar(title: const Text(Strings.helperSettings)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _link(context, Strings.reminderOptions, reminderOptions),
        _link(context, Strings.quietPlaces, quietPlaces),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ports/ports.dart';

/// The Helper's settings in home Wi-Fi mode: a short list, each row opening
/// its own page.
class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({
    super.key,
    required this.home,
    required this.items,
    required this.homeWifi,
    required this.whatToCheck,
    required this.howToRemind,
    required this.language,
  });

  final HomeWifiStore home;
  final CheckItemStore items;
  final WidgetBuilder homeWifi;
  final WidgetBuilder whatToCheck;
  final WidgetBuilder howToRemind;
  final WidgetBuilder language;

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  String? _network;
  int? _itemsOn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? network;
    int? itemsOn;
    try {
      network = (await widget.home.read())?.network;
    } on Object {
      network = null;
    }
    try {
      itemsOn = (await widget.items.read()).where((i) => i.on).length;
    } on Object {
      itemsOn = null;
    }
    if (mounted) {
      setState(() {
        _network = network;
        _itemsOn = itemsOn;
      });
    }
  }

  Future<void> _open(WidgetBuilder builder) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    _load();
  }

  Widget _row(String icon, String title, String? value, WidgetBuilder page) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _open(page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (value != null)
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(text.helperSettings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row('📶', text.homeWifi, _network ?? text.notSet, widget.homeWifi),
          _row(
            '✅',
            text.whatToCheck,
            _itemsOn == null ? null : text.itemsOn(_itemsOn!),
            widget.whatToCheck,
          ),
          _row('🔊', text.howToRemind, null, widget.howToRemind),
          _row('🌐', text.languageSetting, null, widget.language),
        ],
      ),
    );
  }
}

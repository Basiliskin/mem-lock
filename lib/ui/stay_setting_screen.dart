import 'package:flutter/material.dart';

import '../domain/detector.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';

class StaySettingScreen extends StatefulWidget {
  const StaySettingScreen({super.key, required this.store, required this.link});

  final StayChoiceStore store;
  final WatcherLink link;

  @override
  State<StaySettingScreen> createState() => _StaySettingScreenState();
}

class _StaySettingScreenState extends State<StaySettingScreen> {
  StayChoice? _choice;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    StayChoice choice;
    try {
      choice = await widget.store.read();
    } on Object {
      choice = StayChoice.normal;
    }
    if (mounted) setState(() => _choice = choice);
  }

  Future<void> _pick(StayChoice choice) async {
    try {
      await widget.store.write(choice);
      // With no service running, it reads the choice when it next starts.
      widget.link.staySettingChanged();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) {
      setState(() {
        _choice = choice;
        _failed = false;
      });
    }
  }

  String _label(StayChoice choice) => switch (choice) {
    StayChoice.moreOften => Strings.stayMoreOften,
    StayChoice.normal => Strings.stayNormal,
    StayChoice.lessOften => Strings.stayLessOften,
  };

  Widget _option(StayChoice choice) {
    final chosen = choice == _choice;
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
          title: Text(_label(choice), style: const TextStyle(fontSize: 20)),
          subtitle: Text(
            Strings.stayHint(choice.settings.stayTime.inMinutes),
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () => _pick(choice),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(Strings.staySetting)),
    body: _choice == null
        ? const SizedBox.shrink()
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final c in StayChoice.values) _option(c),
              if (_failed)
                Semantics(
                  liveRegion: true,
                  child: const Text(
                    Strings.saveFailed,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
            ],
          ),
  );
}

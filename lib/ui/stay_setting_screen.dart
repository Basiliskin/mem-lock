import 'package:flutter/material.dart';

import '../domain/detector.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';

class StaySettingScreen extends StatefulWidget {
  const StaySettingScreen({super.key, required this.store, required this.link});

  final DetectionSettingsStore store;
  final WatcherLink link;

  @override
  State<StaySettingScreen> createState() => _StaySettingScreenState();
}

class _StaySettingScreenState extends State<StaySettingScreen> {
  DetectionSettings? _settings;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    DetectionSettings settings;
    try {
      settings = await widget.store.read();
    } on Object {
      settings = DetectionSettings.normal;
    }
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _pick(StayChoice choice) async {
    final settings = _settings!.withChoice(choice);
    try {
      await widget.store.write(settings);
      // With no service running, it reads the choice when it next starts.
      widget.link.detectionSettingsChanged();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) {
      setState(() {
        _settings = settings;
        _failed = false;
      });
    }
  }

  String _label(StayChoice choice) => switch (choice) {
    StayChoice.moreOften => context.l10n.stayMoreOften,
    StayChoice.normal => context.l10n.stayNormal,
    StayChoice.lessOften => context.l10n.stayLessOften,
  };

  Widget _option(StayChoice choice) {
    final chosen = choice == _settings!.choice;
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
            context.l10n.stayHint(choice.settings.stayTime.inMinutes),
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () => _pick(choice),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.staySetting)),
    body: _settings == null
        ? const SizedBox.shrink()
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_settings!.choice == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.stayCustomNote,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              for (final c in StayChoice.values) _option(c),
              if (_failed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    context.l10n.saveFailed,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
            ],
          ),
  );
}

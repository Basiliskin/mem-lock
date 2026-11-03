import 'package:flutter/material.dart';

import '../domain/home_wifi.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'usable_fix.dart';

/// The Helper marks the home network while at home and connected to it.
class HomeWifiScreen extends StatefulWidget {
  const HomeWifiScreen({
    super.key,
    required this.store,
    required this.wifi,
    required this.location,
    required this.link,
  });

  final HomeWifiStore store;
  final WifiSource wifi;
  final CurrentFixSource location;
  final WatcherLink link;

  @override
  State<HomeWifiScreen> createState() => _HomeWifiScreenState();
}

class _HomeWifiScreenState extends State<HomeWifiScreen> {
  HomeWifi? _home;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final home = await widget.store.read();
      if (mounted) setState(() => _home = home);
    } on Object {
      if (mounted) setState(() => _message = context.l10n.saveFailed);
    }
  }

  Future<void> _run(Future<String> Function() action) async {
    final failed = context.l10n.saveFailed;
    setState(() {
      _busy = true;
      _message = null;
    });
    String message;
    try {
      message = await action();
    } on Object {
      message = failed;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = message;
      });
    }
  }

  void _tell() {
    try {
      widget.link.homeWifiChanged();
    } on Object {
      // The service reads it again when it next starts.
    }
  }

  Future<void> _set() => _run(() async {
    final text = context.l10n;
    String? network;
    try {
      network = await widget.wifi.current();
    } on Object {
      network = null;
    }
    if (network == null) return text.homeWifiNotConnected;
    final fix = await usableFix(widget.location);
    if (fix == null) return text.homeWifiNoFix;
    final home = HomeWifi(network, fix.point);
    await widget.store.write(home);
    _home = home;
    _tell();
    return text.homeWifiSaved;
  });

  Future<void> _remove() => _run(() async {
    final text = context.l10n;
    await widget.store.write(null);
    _home = null;
    _tell();
    return text.homeWifiRemoved;
  });

  @override
  Widget build(BuildContext context) {
    final text = context.l10n;
    final home = _home;
    return Scaffold(
      appBar: AppBar(title: Text(text.homeWifi)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(text.homeWifiHelp, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Text(
            home == null
                ? text.homeWifiNone
                : text.homeWifiCurrent(home.network),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: FilledButton(
              onPressed: _busy ? null : _set,
              child: Text(
                text.homeWifiSet,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          if (home != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: OutlinedButton(
                onPressed: _busy ? null : _remove,
                child: Text(
                  text.homeWifiRemove,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                _message!,
                style: const TextStyle(fontSize: 18),
                semanticsLabel: _message,
              ),
            ),
        ],
      ),
    );
  }
}

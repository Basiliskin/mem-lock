import 'package:flutter/material.dart';

import '../domain/detector.dart';
import '../domain/quiet_place_record.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';

class QuietPlacesScreen extends StatefulWidget {
  const QuietPlacesScreen({
    super.key,
    required this.store,
    required this.location,
    required this.link,
    this.now = DateTime.now,
  });

  final QuietPlaceStore store;
  final CurrentFixSource location;
  final WatcherLink link;
  final DateTime Function() now;

  @override
  State<QuietPlacesScreen> createState() => _QuietPlacesScreenState();
}

class _QuietPlacesScreenState extends State<QuietPlacesScreen> {
  List<QuietPlaceRecord> _places = const [];
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final places = await widget.store.read();
      if (mounted) setState(() => _places = places);
    } on Object {
      if (mounted) setState(() => _message = Strings.saveFailed);
    }
  }

  /// Marked only from a fresh, trustworthy reading, because the Helper is
  /// standing there now and a wrong place would silence the wrong Reminders.
  Future<LocationFix?> _usableFix() async {
    try {
      final fix = await widget.location.currentFix();
      return fix != null && fix.accuracyMeters <= maxAccuracyMeters
          ? fix
          : null;
    } on Object {
      return null;
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String? message;
    try {
      message = await action();
    } on Object {
      message = Strings.saveFailed;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = message;
      });
    }
  }

  Future<void> _save(List<QuietPlaceRecord> places) async {
    await widget.store.write(places);
    if (mounted) setState(() => _places = places);
    try {
      widget.link.quietPlacesChanged();
    } on Object {
      // The service reads the saved list again whenever it starts.
    }
  }

  Future<void> _mark() => _run(() async {
    final fix = await _usableFix();
    if (fix == null) return Strings.noFixToMark;
    final current = await widget.store.read();
    if (coversPoint(current, fix.point)) return Strings.alreadyQuiet;
    final now = widget.now();
    await _save([
      ...current,
      QuietPlaceRecord(
        QuietPlace('${now.millisecondsSinceEpoch}', fix.point),
        now,
      ),
    ]);
    return null;
  });

  Future<void> _remove(QuietPlaceRecord record) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          Strings.removeQuestion,
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.cancel, style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              Strings.confirmRemove,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(() async {
      final current = await widget.store.read();
      await _save([
        for (final r in current)
          if (r.place.id != record.place.id) r,
      ]);
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.quietPlaces)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _places.isEmpty
                    ? const Text(
                        Strings.noQuietPlaces,
                        style: TextStyle(fontSize: 20),
                      )
                    : ListView(
                        children: [for (final r in _places) _placeRow(r)],
                      ),
              ),
              if (message != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFFFF3C4),
                    child: Text(message, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: FilledButton(
                  onPressed: _busy ? null : _mark,
                  child: const Text(
                    Strings.markQuietPlace,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeRow(QuietPlaceRecord r) {
    final p = r.place.point;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.quietMarkedAt(r.markedAt),
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: OutlinedButton(
              onPressed: _busy ? null : () => _remove(r),
              child: const Text(Strings.remove, style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

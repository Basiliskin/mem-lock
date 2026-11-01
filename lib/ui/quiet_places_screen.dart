import 'package:flutter/material.dart';

import '../domain/detector.dart';
import '../domain/quiet_place_record.dart';
import '../domain/reminder_place_record.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'usable_fix.dart';

class QuietPlacesScreen extends StatefulWidget {
  const QuietPlacesScreen({
    super.key,
    required this.store,
    required this.reminderPlaces,
    required this.location,
    required this.link,
    this.now = DateTime.now,
  });

  final QuietPlaceStore store;
  final ReminderPlaceStore reminderPlaces;
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
      if (mounted) setState(() => _message = context.l10n.saveFailed);
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    final text = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    String? message;
    try {
      message = await action();
    } on Object {
      message = text.saveFailed;
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

  Future<void> _mark() {
    final text = context.l10n;
    return _run(() async {
      final fix = await usableFix(widget.location);
      if (fix == null) return text.noFixToMark;
      final current = await widget.store.read();
      if (coversPoint(current, fix.point)) return text.alreadyQuiet;
      final others = await widget.reminderPlaces.read();
      final clashing = reminderPlacesClashing(others, fix.point);
      if (clashing.isNotEmpty) {
        if (!await _askMakeQuiet()) return text.keptReminderPlace;
        // Given up first: a failure here can't leave the place as both, and
        // trying again still works.
        await widget.reminderPlaces.write([
          for (final r in others)
            if (!clashing.contains(r)) r,
        ]);
        try {
          widget.link.reminderPlacesChanged();
        } on Object {
          // The service reads the saved list again whenever it starts.
        }
      }
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
  }

  /// True when the Helper chose to make it quiet. Back keeps it as it is,
  /// because nothing should change without a clear answer.
  Future<bool> _askMakeQuiet() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.clashIsReminderPlace,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              context.l10n.keepReminderPlace,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.makeQuiet,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _remove(QuietPlaceRecord record) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.removeQuestion,
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel, style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.confirmRemove,
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
      appBar: AppBar(title: Text(context.l10n.quietPlaces)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _places.isEmpty
                    ? Text(
                        context.l10n.noQuietPlaces,
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
                  child: Text(
                    context.l10n.markQuietPlace,
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
                  context.l10n.quietMarkedAt(r.markedAt),
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
              child: Text(context.l10n.remove, style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

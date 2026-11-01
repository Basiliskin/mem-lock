import 'package:flutter/material.dart';

import '../domain/detector.dart';
import '../domain/quiet_place_record.dart';
import '../domain/reminder_place_record.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'usable_fix.dart';

class ReminderPlacesScreen extends StatefulWidget {
  const ReminderPlacesScreen({
    super.key,
    required this.store,
    required this.quiet,
    required this.location,
    required this.link,
    this.now = DateTime.now,
  });

  final ReminderPlaceStore store;
  final QuietPlaceStore quiet;
  final CurrentFixSource location;
  final WatcherLink link;
  final DateTime Function() now;

  @override
  State<ReminderPlacesScreen> createState() => _ReminderPlacesScreenState();
}

class _ReminderPlacesScreenState extends State<ReminderPlacesScreen> {
  final _name = TextEditingController();
  final _text = TextEditingController();
  List<ReminderPlaceRecord> _places = const [];
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    super.dispose();
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

  void _tell(void Function() send) {
    try {
      send();
    } on Object {
      // The service reads the saved lists again whenever it starts.
    }
  }

  Future<void> _save(List<ReminderPlaceRecord> places) async {
    await widget.store.write(places);
    if (mounted) setState(() => _places = places);
    _tell(widget.link.reminderPlacesChanged);
  }

  /// True when the Helper chose to make it a Reminder Place. Back keeps it
  /// quiet, because nothing should change without a clear answer.
  Future<bool> _askMakeReminderPlace() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.clashIsQuiet,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              context.l10n.keepQuiet,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.makeReminderPlace,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _mark() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final message = _text.text.trim();
    return _run(() async {
      if (name.isEmpty || message.isEmpty) return l10n.reminderPlaceNeedsText;
      final fix = await usableFix(widget.location);
      if (fix == null) return l10n.reminderPlaceNoFix;
      final current = await widget.store.read();
      if (coversReminderPoint(current, fix.point)) {
        return l10n.alreadyReminderPlace;
      }
      final quiet = await widget.quiet.read();
      if (coversPoint(quiet, fix.point)) {
        if (!await _askMakeReminderPlace()) return l10n.keptQuiet;
        // Given up first: a failure here can't leave the place as both, and
        // trying again still works.
        await widget.quiet.write([
          for (final r in quiet)
            if (r.place.point.distanceTo(fix.point) > quietPlaceMeters) r,
        ]);
        _tell(widget.link.quietPlacesChanged);
      }
      final now = widget.now();
      await _save([
        ...current,
        ReminderPlaceRecord(
          ReminderPlace('${now.millisecondsSinceEpoch}', fix.point, message),
          name,
        ),
      ]);
      _name.clear();
      _text.clear();
      return l10n.reminderPlaceSaved;
    });
  }

  Future<void> _remove(ReminderPlaceRecord record) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.removeReminderPlaceQuestion,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.confirmRemove,
              style: const TextStyle(fontSize: 20),
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
      return l10n.reminderPlaceRemoved;
    });
  }

  Widget _row(ReminderPlaceRecord r) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          r.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(r.place.message, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: OutlinedButton(
            onPressed: _busy ? null : () => _remove(r),
            child: Text(
              context.l10n.removeNamed(r.name),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = _message;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminderPlaces)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.reminderPlacesHelp, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            if (_places.isEmpty)
              Text(l10n.noReminderPlaces, style: const TextStyle(fontSize: 20)),
            for (final r in _places) _row(r),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('place-name'),
              controller: _name,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: l10n.reminderPlaceName,
                hintText: l10n.reminderPlaceNameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('place-message'),
              controller: _text,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: l10n.reminderPlaceMessage,
                hintText: l10n.reminderPlaceMessageHint,
              ),
            ),
            const SizedBox(height: 16),
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
                  l10n.markReminderPlace,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

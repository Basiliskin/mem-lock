import 'package:flutter/material.dart';

import '../domain/check_items.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'check_item_text.dart';

const _blue = Color(0xFF1E3A8A);
const _green = Color(0xFF16A34A);
const _doneGreen = Color(0xFF065F46);

/// After leaving home: one thing at a time, with one big answer each.
class CheckScreen extends StatefulWidget {
  const CheckScreen({
    super.key,
    required this.items,
    required this.onAllDone,
    required this.onGoBack,
  });

  final CheckItemStore items;

  /// The Wearer has everything, so the Reminder stops.
  final VoidCallback onAllDone;

  /// The Wearer is missing something and goes back.
  final VoidCallback onGoBack;

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  List<CheckItem>? _items;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<CheckItem> items;
    try {
      items = await widget.items.read();
    } on Object {
      items = defaultCheckItems;
    }
    final on = items.where((i) => i.on).toList();
    if (mounted) setState(() => _items = on);
  }

  void _yes() {
    setState(() => _step++);
    if (_step >= _items!.length) widget.onAllDone();
  }

  void _skip() {
    widget.onAllDone();
    Navigator.of(context).maybePop();
  }

  Widget _button(String label, Color bg, Color fg, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          height: 76,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = context.l10n;
    final items = _items;
    if (items == null) {
      return const Scaffold(backgroundColor: _blue, body: SizedBox.shrink());
    }
    // With nothing chosen, one general question.
    final asking = items.isEmpty ? 1 : items.length;
    if (_step >= asking) return _done(context);
    final item = items.isEmpty ? null : items[_step];
    return Scaffold(
      backgroundColor: _blue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🏠 ${text.checkLeftHome}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < asking; i++)
                    Expanded(
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item == null ? '🎒' : checkItemIcon(item),
                        style: const TextStyle(fontSize: 120),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item == null
                            ? text.checkHaveEverything
                            : '${checkItemLabel(context, item)}?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _button('✓ ${text.checkYes}', _green, Colors.white, _yes),
              _button(
                '✗ ${text.checkNoGoBack}',
                Colors.white24,
                Colors.white,
                widget.onGoBack,
              ),
              TextButton(
                onPressed: _skip,
                child: Text(
                  text.checkSkip,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _done(BuildContext context) {
    final text = context.l10n;
    return Scaffold(
      backgroundColor: _doneGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '✅',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 96),
              ),
              Text(
                text.checkAllDone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text.checkGoodTrip,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 24),
              _button(
                text.checkClose,
                Colors.white,
                _doneGreen,
                () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

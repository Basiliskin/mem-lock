import 'package:flutter/material.dart';

import '../domain/check_items.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'check_item_text.dart';

/// The Helper chooses what the Wearer is asked about after leaving home.
/// Every change is saved straight away.
class CheckItemsScreen extends StatefulWidget {
  const CheckItemsScreen({super.key, required this.store});

  final CheckItemStore store;

  @override
  State<CheckItemsScreen> createState() => _CheckItemsScreenState();
}

class _CheckItemsScreenState extends State<CheckItemsScreen> {
  final _new = TextEditingController();
  List<CheckItem>? _items;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<CheckItem> items;
    try {
      items = await widget.store.read();
    } on Object {
      items = defaultCheckItems;
    }
    if (mounted) setState(() => _items = items);
  }

  Future<void> _save(List<CheckItem> items) async {
    setState(() => _items = items);
    var failed = false;
    try {
      await widget.store.write(items);
    } on Object {
      failed = true;
    }
    if (mounted) setState(() => _saveFailed = failed);
  }

  void _add() {
    final value = _new.text.trim();
    if (value.isEmpty) return;
    _new.clear();
    _save([..._items!, CheckItem.custom(value)]);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.l10n;
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text('✅ ${text.whatToCheck}')),
      body: items == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final (i, item) in items.indexed)
                          ListTile(
                            minTileHeight: 64,
                            leading: Text(
                              checkItemIcon(item),
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              checkItemLabel(context, item),
                              style: const TextStyle(fontSize: 20),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.builtIn == null)
                                  IconButton(
                                    tooltip: text.removeItem,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _save([
                                      ...items.take(i),
                                      ...items.skip(i + 1),
                                    ]),
                                  ),
                                Switch(
                                  value: item.on,
                                  onChanged: (v) => _save([
                                    for (final (j, it) in items.indexed)
                                      j == i ? it.withOn(v) : it,
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _new,
                                style: const TextStyle(fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: text.addItemHint,
                                ),
                                onSubmitted: (_) => _add(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _add,
                              child: Text('＋ ${text.addItem}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_saveFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      text.saveFailed,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../ports/ports.dart';

/// Shows setup until it has been finished once, then the main screen.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.store,
    required this.setup,
    required this.main,
  });

  final SetupStore store;
  final Widget Function(VoidCallback onDone) setup;
  final WidgetBuilder main;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool? _done;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool done;
    try {
      done = await widget.store.isDone();
    } on Object {
      done = false;
    }
    if (mounted) setState(() => _done = done);
  }

  @override
  Widget build(BuildContext context) => switch (_done) {
    null => const Scaffold(body: SizedBox.shrink()),
    true => widget.main(context),
    false => widget.setup(() => setState(() => _done = true)),
  };
}

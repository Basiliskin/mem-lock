import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../ports/ports.dart';

const _ok = Color(0xFF0B6B2E);
const _bad = Color(0xFFB3141C);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.host});

  final BackgroundHost host;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool? _running;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final running = await widget.host.isRunning();
    if (mounted) setState(() => _running = running);
  }

  Future<void> _enable() async {
    final running = await widget.host.start();
    if (mounted) {
      setState(() {
        _running = running;
        _failed = !running;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _running;
    if (running == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      backgroundColor: running ? _ok : _bad,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  running ? Icons.check : Icons.priority_high,
                  size: 88,
                  color: Colors.white,
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    running ? Strings.protecting : Strings.notProtecting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (running)
                  const Text(
                    Strings.nothingToDo,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                if (!running) ...[
                  if (_failed)
                    const Text(
                      Strings.startFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _bad,
                      ),
                      onPressed: _enable,
                      child: const Text(
                        Strings.enable,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

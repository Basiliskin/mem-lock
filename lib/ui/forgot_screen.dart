import 'package:flutter/material.dart';

import '../domain/geo.dart';
import '../domain/last_place_record.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({
    super.key,
    required this.place,
    this.previous,
    required this.map,
    this.now = DateTime.now,
  });

  final LastPlaceRecord place;
  final LastPlaceRecord? previous;
  final MapLauncher map;
  final DateTime Function() now;

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  /// The place that no map app could open.
  GeoPoint? _noMapFor;

  Future<void> _open(GeoPoint point) async {
    var opened = false;
    try {
      opened = await widget.map.open(point);
    } on Object {
      opened = false;
    }
    if (mounted) setState(() => _noMapFor = opened ? null : point);
  }

  @override
  Widget build(BuildContext context) {
    final p = _noMapFor;
    final previous = widget.previous;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      Strings.dontWorry,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Strings.whenText(widget.place.time, widget.now()),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      Strings.goBackAdvice,
                      style: TextStyle(fontSize: 20),
                    ),
                    if (previous != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        Strings.previousWhen(previous.time, widget.now()),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 64),
                        child: OutlinedButton(
                          onPressed: () => _open(previous.point),
                          child: const Text(
                            Strings.openPreviousMap,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                    if (p != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFFFF3C4),
                          child: Text(
                            '${Strings.noMapApp} '
                            '${Strings.coordinates}: '
                            '${p.lat.toStringAsFixed(5)}, '
                            '${p.lng.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                height: 64,
                child: FilledButton(
                  onPressed: () => _open(widget.place.point),
                  child: const Text(
                    Strings.openMap,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    Strings.toMain,
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
}

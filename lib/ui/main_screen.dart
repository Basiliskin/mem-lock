import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../domain/last_place_record.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';
import 'forgot_screen.dart';

const _ok = Color(0xFF0B6B2E);
const _bad = Color(0xFFB3141C);
const _helperPress = Duration(seconds: 2);

/// Quick settings can change location without the app ever leaving the screen.
const _statusRefresh = Duration(seconds: 5);

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.host,
    required this.places,
    required this.map,
    required this.forgotRequests,
    required this.health,
    required this.battery,
    required this.helperSettings,
  });

  final BackgroundHost host;
  final LastPlaceStore places;
  final MapLauncher map;
  final HealthCheck health;
  final BatterySource battery;

  /// Goes up each time the notification's "I forgot something" is tapped.
  final ValueListenable<int> forgotRequests;

  /// What the Helper's long press opens.
  final WidgetBuilder helperSettings;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool? _running;
  bool _failed = false;
  ProtectionProblem? _problem;
  Timer? _timer;
  List<LastPlaceRecord> _places = const [];
  bool _lowBattery = false;
  int _handledRequests = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.forgotRequests.addListener(_onForgotRequest);
    _refresh().then((_) => _onForgotRequest());
    _timer = Timer.periodic(_statusRefresh, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.forgotRequests.removeListener(_onForgotRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final running = await widget.host.isRunning();
    final places = await _readPlaces();
    final lowBattery = await _readLowBattery();
    // A failed check keeps the last answer, so it can't clear a warning.
    var problem = _problem;
    try {
      problem = await widget.health.check();
    } on Object {
      // Checked again shortly.
    }
    if (mounted) {
      setState(() {
        _problem = problem;
        _running = running;
        _places = places;
        _lowBattery = lowBattery;
      });
    }
  }

  Future<List<LastPlaceRecord>> _readPlaces() async {
    try {
      return await widget.places.read();
    } on Object {
      return const [];
    }
  }

  Future<bool> _readLowBattery() async {
    try {
      return (await widget.battery.read()).isLow;
    } on Object {
      return false;
    }
  }

  Future<void> _onForgotRequest() async {
    if (widget.forgotRequests.value <= _handledRequests) return;
    _handledRequests = widget.forgotRequests.value;
    final places = await _readPlaces();
    if (!mounted || places.isEmpty) return;
    setState(() => _places = places);
    _openForgot(places);
  }

  void _openForgot(List<LastPlaceRecord> places) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ForgotScreen(
        place: places.first,
        previous: places.length > 1 ? places[1] : null,
        map: widget.map,
      ),
    ),
  );

  void _openHelper() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: widget.helperSettings));

  Widget _helperEntry() => Semantics(
    container: true,
    onLongPress: _openHelper,
    child: RawGestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: _helperPress),
              (r) => r.onLongPress = _openHelper,
            ),
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: const Center(
          child: Text(
            Strings.helperEntry,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF3D3D3D)),
          ),
        ),
      ),
    ),
  );

  String _reason(ProtectionProblem problem) => switch (problem) {
    ProtectionProblem.locationOff => Strings.problemLocationOff,
    ProtectionProblem.locationPermission => Strings.problemLocationPermission,
    ProtectionProblem.notifications => Strings.problemNotifications,
    ProtectionProblem.activityPermission => Strings.problemActivityPermission,
  };

  Future<void> _fix(ProtectionProblem problem) async {
    try {
      await widget.health.fix(problem);
    } on Object {
      // The warning stays until the problem is really gone.
    }
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
    final serviceRunning = _running;
    if (serviceRunning == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final problem = _problem;
    final running = serviceRunning && problem == null;
    return Scaffold(
      backgroundColor: running ? _ok : _bad,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
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
                        if (problem != null)
                          Text(
                            _reason(problem),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        if (problem == null && _failed)
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
                            onPressed: problem == null
                                ? _enable
                                : () => _fix(problem),
                            child: Text(
                              problem == null ? Strings.enable : Strings.fix,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_lowBattery)
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3C4),
                          border: Border.all(color: const Color(0xFF7A5C00)),
                        ),
                        child: const Text(
                          Strings.lowBattery,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  if (_places.isNotEmpty)
                    SizedBox(
                      height: 96,
                      child: OutlinedButton(
                        onPressed: () => _openForgot(_places),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              Strings.actionForgot,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Strings.whenText(
                                _places.first.time,
                                DateTime.now(),
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _helperEntry(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

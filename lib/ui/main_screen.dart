import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/home_wifi.dart';
import '../domain/last_place_record.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';
import 'forgot_screen.dart';

const _ok = Color(0xFF0B6B2E);
const _okBg = Color(0xFFE3F5EC);
const _bad = Color(0xFFB3141C);
const _badBg = Color(0xFFFDE8E8);
const _warn = Color(0xFF8A4B00);
const _warnBg = Color(0xFFFFF3DF);

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
    this.homeWifi,
    this.homeWifiScreen,
    this.checkRequests,
    this.checkScreen,
  });

  /// Set in home Wi-Fi mode: without a home Wi-Fi nothing is watched.
  final HomeWifiStore? homeWifi;
  final WidgetBuilder? homeWifiScreen;

  /// Goes up each time the Reminder itself is tapped; opens [checkScreen].
  final ValueListenable<int>? checkRequests;
  final WidgetBuilder? checkScreen;

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
  int _handledChecks = 0;
  HomeWifi? _home;
  bool _homeRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.forgotRequests.addListener(_onForgotRequest);
    widget.checkRequests?.addListener(_onCheckRequest);
    _refresh().then((_) {
      _onForgotRequest();
      _onCheckRequest();
    });
    _timer = Timer.periodic(_statusRefresh, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.forgotRequests.removeListener(_onForgotRequest);
    widget.checkRequests?.removeListener(_onCheckRequest);
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
    var home = _home;
    var homeRead = _homeRead;
    try {
      home = await widget.homeWifi?.read();
      homeRead = true;
    } on Object {
      // Read again shortly.
    }
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
        _home = home;
        _homeRead = homeRead;
      });
    }
  }

  void _onCheckRequest() {
    final requests = widget.checkRequests;
    final screen = widget.checkScreen;
    if (requests == null || screen == null) return;
    if (requests.value <= _handledChecks) return;
    _handledChecks = requests.value;
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: screen));
    }
  }

  Future<void> _openHomeWifi() async {
    final screen = widget.homeWifiScreen;
    if (screen == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: screen));
    _refresh();
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

  /// A plain button: the old 2-second hold was too hard to find.
  Widget _helperEntry() => SizedBox(
    height: 56,
    child: TextButton.icon(
      onPressed: _openHelper,
      icon: const Text('👪', style: TextStyle(fontSize: 22)),
      label: Text(
        context.l10n.helperSettings,
        style: const TextStyle(fontSize: 18, color: Color(0xFF3D3D3D)),
      ),
    ),
  );

  String _reason(ProtectionProblem problem) => switch (problem) {
    ProtectionProblem.locationOff => context.l10n.problemLocationOff,
    ProtectionProblem.locationNotStarting =>
      context.l10n.problemLocationNotStarting,
    ProtectionProblem.locationPermission =>
      context.l10n.problemLocationPermission,
    ProtectionProblem.notifications => context.l10n.problemNotifications,
    ProtectionProblem.activityPermission =>
      context.l10n.problemActivityPermission,
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

  Widget _bigButton(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    ),
  );

  Widget _row(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFDDE2EA))),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 17, color: Color(0xFF5B6472)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final serviceRunning = _running;
    if (serviceRunning == null || (widget.homeWifi != null && !_homeRead)) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final text = context.l10n;
    final problem = _problem;
    final notSet = widget.homeWifi != null && _home == null;
    final running = serviceRunning && problem == null;
    final homeMode = widget.homeWifi != null;
    final (
      Color fg,
      Color bg,
      String icon,
      String title,
      String? detail,
    ) = notSet
        ? (_warn, _warnBg, '📶', text.statusNotSet, text.statusNotSetText)
        : running
        ? (
            _ok,
            _okBg,
            homeMode ? '🏠' : '✓',
            homeMode ? text.statusAllGood : text.protecting,
            homeMode ? text.statusAllGoodText : text.nothingToDo,
          )
        : (
            problem == null ? _bad : _warn,
            problem == null ? _badBg : _warnBg,
            '⚠️',
            homeMode && problem != null
                ? text.statusNeedsAttention
                : text.notProtecting,
            problem != null
                ? _reason(problem)
                : _failed
                ? text.startFailed
                : null,
          );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: fg.withAlpha(40), spreadRadius: 10),
                      ],
                    ),
                    child: ExcludeSemantics(
                      child: Text(icon, style: const TextStyle(fontSize: 64)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ],
                ],
              ),
            ),
            if (notSet)
              _bigButton(text.setupOpenHome, _openHomeWifi)
            else if (problem != null)
              _bigButton(text.fix, () => _fix(problem))
            else if (!serviceRunning)
              _bigButton(text.enable, _enable),
            if (!notSet && (_home != null || _places.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    if (_home case final home?)
                      _row(text.homeWifi, home.network),
                    if (_places.isNotEmpty)
                      _row(
                        text.lastReminder,
                        text.whenText(_places.first.time, DateTime.now()),
                      ),
                  ],
                ),
              ),
            if (_lowBattery)
              Semantics(
                liveRegion: true,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    border: Border.all(color: const Color(0xFF7A5C00)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    text.lowBattery,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            if (_places.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFDDE2EA),
                        width: 2,
                      ),
                    ),
                    onPressed: () => _openForgot(_places),
                    child: Text(
                      text.actionForgot,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _helperEntry(),
          ],
        ),
      ),
    );
  }
}

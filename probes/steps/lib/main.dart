import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

import 'guide.dart';
import 'steps_log.dart';

void main() => runApp(const MaterialApp(home: ProbePage()));

/// Time to put the phone away, so handling it isn't mistaken for walking.
const _settle = Duration(seconds: 15);

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  File? _file;
  Directory? _dir;
  String? _error;
  Analysis _progress = analyze(const []);
  GuideActivity? _activity;
  bool _settling = false;
  bool _doorClosed = false;
  DateTime? _startedAt;
  String? _results;
  final _subs = <StreamSubscription<dynamic>>[];
  final _window = <double>[];
  Timer? _motionTimer;
  Timer? _settleTimer;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Progress comes from the logs, so it survives closing the app.
  Future<void> _load() async {
    final dir = await getExternalStorageDirectory();
    _dir = dir;
    if (mounted) setState(() => _progress = analyze(_readLogs()));
  }

  List<LogEntry> _readLogs() {
    final dir = _dir;
    if (dir == null) return const [];
    return [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.jsonl')) ...parseLog(f.readAsStringSync()),
    ];
  }

  // Written straight away, so a killed app loses as little as possible.
  void _log(String kind, [Map<String, dynamic> data = const {}]) {
    _file?.writeAsStringSync(
      '${LogEntry(DateTime.now(), kind, data).toLine()}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<bool> _startLogging() async {
    if (_file != null) return true;
    final results = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.notification,
    ].request();
    final denied = results.entries.where((e) => !e.value.isGranted).toList();
    if (denied.isNotEmpty) {
      setState(
        () => _error = 'Permission missing: ${denied.map((e) => e.key)}',
      );
      return false;
    }
    setState(() => _error = null);

    final dir = _dir ?? await getExternalStorageDirectory();
    _dir = dir;
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    _file = File('${dir!.path}/steps-$stamp.jsonl');
    _log('probe_start');

    // Only keeps the app running with the phone locked, as the real Watcher
    // does. Positions are thrown away: this probe logs no places.
    _subs.add(
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.low,
          // Fused location can wrongly report location as off; see S15.
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 30),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Steps probe',
            notificationText: 'Logging a test',
            enableWakeLock: true,
          ),
        ),
      ).listen(
        (_) {},
        onError: (Object e) => _log('keep_alive_error', {'error': '$e'}),
      ),
    );

    // Only whether Wi-Fi is connected, never the network's name.
    _subs.add(
      Connectivity().onConnectivityChanged.listen(
        (r) => _log('wifi', {'connected': r.contains(ConnectivityResult.wifi)}),
        onError: (Object e) => _log('wifi_error', {'error': '$e'}),
      ),
    );

    // Logs only the steps since the last signal, never the running total.
    int? lastTotal;
    _subs.add(
      Pedometer.stepCountStream.listen((e) {
        final steps = stepsSince(lastTotal, e.steps);
        lastTotal = e.steps;
        _log('step', {'steps': steps});
      }, onError: (Object e) => _log('step_error', {'error': '$e'})),
    );
    _subs.add(
      Pedometer.pedestrianStatusStream.listen(
        (s) => _log('pedestrian', {'status': s.status}),
        onError: (Object e) => _log('pedestrian_error', {'error': '$e'}),
      ),
    );
    _subs.add(
      accelerometerEventStream().listen(
        (e) => _window.add(_magnitude(e)),
        onError: (Object e) => _log('motion_error', {'error': '$e'}),
      ),
    );
    _motionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _log('motion', {'std': motionStd(_window)});
      _window.clear();
    });
    _subs.add(
      ActivityRecognition()
          .activityStream(runForegroundService: false)
          .listen(
            (a) => _log('activity', {
              'kind': a.typeString,
              'confidence': a.confidence,
            }),
            onError: (Object e) => _log('activity_error', {'error': '$e'}),
          ),
    );
    return true;
  }

  double _magnitude(AccelerometerEvent e) =>
      sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

  Future<void> _stopLogging() async {
    _motionTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _log('probe_stop');
    _file = null;
  }

  Future<void> _begin(GuideActivity activity) async {
    if (needsWifi(activity)) {
      final now = await Connectivity().checkConnectivity();
      if (!now.contains(ConnectivityResult.wifi)) {
        setState(() => _error = 'Connect to the home Wi-Fi first.');
        return;
      }
    }
    setState(() {
      _doorClosed = false;
      _error = null;
    });
    if (!await _startLogging()) return;
    setState(() {
      _activity = activity;
      _settling = true;
      _results = null;
    });
    _settleTimer = Timer(_settle, () {
      _log('segment_start', {'type': activity.type});
      unawaited(Vibration.vibrate(duration: 800));
      setState(() {
        _settling = false;
        _startedAt = DateTime.now();
      });
      var told = activity.minimum == Duration.zero;
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!told && _elapsed >= activity.minimum) {
          told = true;
          unawaited(Vibration.vibrate(pattern: [0, 400, 300, 400]));
        }
        setState(() {});
      });
    });
  }

  Duration get _elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  bool get _minimumReached =>
      _activity != null && _elapsed >= _activity!.minimum;

  Future<void> _finish() async {
    _settleTimer?.cancel();
    _clock?.cancel();
    if (!_settling) _log(_minimumReached ? 'segment_end' : 'segment_cancel');
    await _stopLogging();
    setState(() {
      _activity = null;
      _settling = false;
      _startedAt = null;
      _progress = analyze(_readLogs());
    });
  }

  void _showResults() =>
      setState(() => _results = analyze(_readLogs()).report());

  /// The report as text, with the raw logs attached so they can be re-analysed.
  /// Logs hold no places and no running step total.
  Future<void> _share() async {
    final logs = _dir == null
        ? <File>[]
        : [
            for (final f in _dir!.listSync().whereType<File>())
              if (f.path.endsWith('.jsonl')) f,
          ];
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Steps probe results',
          text: analyze(_readLogs()).report(),
          files: [for (final f in logs) XFile(f.path)],
        ),
      );
    } on Exception catch (e) {
      if (mounted) setState(() => _error = 'Could not share: $e');
    }
  }

  Widget _big(String label, VoidCallback? onTap) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    ),
  );

  String _clockText(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  List<Widget> _running(GuideActivity a) {
    final min = a.minimum;
    final Widget text;
    final String button;
    if (_settling) {
      text = Text(
        'Lock the phone, put it on your body and stand or sit still. It '
        'vibrates once in ${_settle.inSeconds} s. Then begin:\n\n${a.howTo}',
      );
      button = 'Cancel';
    } else {
      final left = min - _elapsed;
      text = Text(
        '${a.howTo}\n\n'
        '${min == Duration.zero
            ? 'Time so far: ${_clockText(_elapsed)}. All of it counts.'
            : _minimumReached
            ? 'Minimum reached. Stop, then tap Done.'
            : 'Keep going for ${_clockText(left)}. It vibrates twice when '
                  'the time is up.'}',
      );
      button = _minimumReached ? 'Done' : 'Stop early (will not count)';
    }
    return [
      Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      text,
      if (!_settling && a.type == leaveHome.type && !_doorClosed)
        _big('Door closed', () {
          _log('door_closed');
          setState(() => _doorClosed = true);
        }),
      _big(button, _finish),
    ];
  }

  List<Widget> _checklist() {
    final goals = guideGoals(_progress);
    final next = nextGoal(goals);
    return [
      if (noStepsSeen(_progress))
        const Text(
          'Warning: walks so far gave no step signals. Check the permission '
          'or try another phone before doing the full set.',
          style: TextStyle(color: Colors.red),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      Text(
        next == null ? 'All done. Tap Show results.' : 'Next: ${next.title}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (next != null)
        for (final a in next.activities)
          _big('Start: ${a.title}', () => _begin(a)),
      const Divider(height: 32),
      for (final g in goals)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Icon(
            g.complete ? Icons.check_circle : Icons.circle_outlined,
          ),
          title: Text('${g.title}: ${g.done} of ${g.needed} ${g.unit}'),
          children: [
            for (final a in g.activities) _big(a.title, () => _begin(a)),
          ],
        ),
      _big('Show results', _showResults),
      _big('Share results', _share),
      if (_results != null) ...[
        const SizedBox(height: 8),
        SelectableText(_results!),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    return Scaffold(
      appBar: AppBar(title: const Text('Steps probe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: activity != null ? _running(activity) : _checklist(),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

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
  IOSink? _sink;
  String? _path;
  String _status = 'Not logging';
  int _lines = 0;
  String? _segment;
  bool _settling = false;
  final _subs = <StreamSubscription<dynamic>>[];
  final _window = <double>[];
  Timer? _motionTimer;
  Timer? _settleTimer;

  bool get _logging => _sink != null;

  void _log(String kind, [Map<String, dynamic> data = const {}]) {
    _sink?.writeln(LogEntry(DateTime.now(), kind, data).toLine());
    _sink?.flush();
    if (mounted) setState(() => _lines++);
  }

  Future<void> _start() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.notification,
    ].request();
    final denied = results.entries.where((e) => !e.value.isGranted).toList();
    if (denied.isNotEmpty) {
      setState(
        () => _status = 'Permission missing: ${denied.map((e) => e.key)}',
      );
      return;
    }

    final dir = await getExternalStorageDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir!.path}/steps-$stamp.jsonl');
    setState(() {
      _sink = file.openWrite(mode: FileMode.append);
      _path = file.path;
      _status = 'Logging';
    });
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
      ).listen((_) {}, onError: (Object e) => _log('keep_alive_error', {'error': '$e'})),
    );

    // The count itself is never logged (AC-14.3), only that a step happened.
    _subs.add(
      Pedometer.stepCountStream.listen(
        (_) => _log('step'),
        onError: (Object e) => _log('step_error', {'error': '$e'}),
      ),
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
  }

  double _magnitude(AccelerometerEvent e) =>
      sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

  Future<void> _stop() async {
    _motionTimer?.cancel();
    _settleTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _log('probe_stop');
    await _sink?.close();
    setState(() {
      _sink = null;
      _segment = null;
      _settling = false;
      _status = 'Stopped';
    });
  }

  void _begin(String type) {
    setState(() {
      _segment = type;
      _settling = true;
    });
    _settleTimer = Timer(_settle, () {
      _log('segment_start', {'type': type});
      unawaited(Vibration.vibrate(duration: 800));
      setState(() => _settling = false);
    });
  }

  void _end() {
    _settleTimer?.cancel();
    if (!_settling) _log('segment_end');
    setState(() {
      _segment = null;
      _settling = false;
    });
  }

  Widget _big(String label, VoidCallback? onTap) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Steps probe')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$_status · $_lines lines'),
        if (_path != null) SelectableText(_path!),
        if (!_logging) _big('Start logging', _start),
        if (_logging && _segment == null) ...[
          const Text('Choose what you are about to do:'),
          _big('Walk', () => _begin('walk')),
          _big('Sit still', () => _begin('sit')),
          _big('Ride in a vehicle', () => _begin('vehicle')),
          _big('Stop logging', _stop),
        ],
        if (_segment != null) ...[
          Text(
            _settling
                ? 'Lock the phone, put it on your body and stand or sit still. '
                      'It will vibrate in ${_settle.inSeconds} s.'
                : _segment == 'walk'
                ? 'Start walking now, at least 2 minutes. Then tap End.'
                : 'Carry on for at least 5 minutes without walking. Then tap End.',
          ),
          _big(_settling ? 'Cancel' : 'End', _end),
        ],
      ],
    ),
  );
}

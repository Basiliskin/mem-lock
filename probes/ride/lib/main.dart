import 'dart:async';
import 'dart:io';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ride_log.dart';

void main() => runApp(const MaterialApp(home: ProbePage()));

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  IOSink? _sink;
  String? _path;
  String _status = 'Not logging';
  String _lastActivity = '-';
  String? _rideType;
  int _lines = 0;
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _heartbeat;

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
    final file = File('${dir!.path}/ride-$stamp.jsonl');
    setState(() {
      _sink = file.openWrite(mode: FileMode.append);
      _path = file.path;
      _status = 'Logging';
    });
    _log('probe_start');

    _subs.add(
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Ride probe',
            notificationText: 'Logging a test journey',
            enableWakeLock: true,
          ),
        ),
      ).listen(
        (p) => _log('location', {
          'lat': p.latitude,
          'lng': p.longitude,
          'accuracy': p.accuracy,
          'speed': p.speed,
        }),
        onError: (Object e) => _log('location_error', {'error': '$e'}),
      ),
    );

    _subs.add(
      ActivityRecognition().activityStream(runForegroundService: false).listen((
        a,
      ) {
        _log('activity', {'kind': a.typeString, 'confidence': a.confidence});
        if (mounted) {
          setState(() => _lastActivity = '${a.typeString} ${a.confidence}%');
        }
      }, onError: (Object e) => _log('activity_error', {'error': '$e'})),
    );

    _heartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _log('heartbeat'),
    );
  }

  Future<void> _stop() async {
    _heartbeat?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _log('probe_stop');
    await _sink?.close();
    setState(() {
      _sink = null;
      _rideType = null;
      _status = 'Stopped';
    });
  }

  void _startRide(String type) {
    _log('ride_start', {'train': type});
    setState(() => _rideType = type);
  }

  void _gotOff() {
    _log('got_off');
    setState(() => _rideType = null);
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
    appBar: AppBar(title: const Text('Ride probe')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$_status · $_lines lines · activity: $_lastActivity'),
        if (_path != null) SelectableText(_path!),
        if (!_logging) _big('Start logging', _start),
        if (_logging && _rideType == null) ...[
          const Text('Tap when you board:'),
          for (final t in const ['metro', 'train', 'bus', 'tram'])
            _big(t, () => _startRide(t)),
          _big('Stop logging', _stop),
        ],
        if (_rideType != null) ...[
          Text('On a $_rideType. Tap at your first step on the platform:'),
          _big('I got off and started walking', _gotOff),
        ],
      ],
    ),
  );
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'wifi_log.dart';

void main() => runApp(
  MaterialApp(
    title: 'Wi-Fi probe',
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: const ProbePage(),
  ),
);

const _channel = MethodChannel('probe/wifi');

/// Asking more often than this is pointless: Android allows 4 scans in 2
/// minutes unless throttling is turned off in developer options.
const _scanEvery = Duration(seconds: 10);
const _pollEvery = Duration(seconds: 3);

/// Scans averaged into a new point.
const _scansPerPoint = 3;

/// A scan this alike to a point counts as being there. A starting guess.
const _nearDb = 10.0;

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  Directory? _dir;
  File? _file;
  String _salt = '';
  String? _error;
  List<LogEntry> _old = const [];
  List<WifiPoint> _points = [];

  List<ApReading> _scan = const [];
  DateTime? _scanAt;
  int _refused = 0;
  final _names = <String, String>{};
  String? _nearId;

  /// A point tapped as "here", until the next scan arrives.
  String? _waitingAt;

  String? _collecting;
  final _collected = <List<ApReading>>[];

  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<void> _start() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
    if (!(results[Permission.locationWhenInUse]?.isGranted ?? false)) {
      setState(() => _error = 'Location permission is needed to read Wi-Fi.');
      return;
    }
    final dir = (await getExternalStorageDirectory())!;
    final saltFile = File('${dir.path}/salt.txt');
    if (!saltFile.existsSync()) {
      final r = Random.secure();
      saltFile.writeAsStringSync(
        List.generate(16, (_) => r.nextInt(256).toRadixString(16)).join(),
      );
    }
    _dir = dir;
    _salt = saltFile.readAsStringSync();
    _old = _readLogs();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    _file = File('${dir.path}/wifi-$stamp.jsonl');
    _log('probe_start');
    await WakelockPlus.enable();
    setState(() => _points = pointsIn(_old));

    _timers
      ..add(Timer.periodic(_scanEvery, (_) => _askScan()))
      ..add(Timer.periodic(_pollEvery, (_) => _readScan()));
    await _askScan();
  }

  List<LogEntry> _readLogs() {
    final dir = _dir;
    if (dir == null) return const [];
    return [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.jsonl')) ...parseLog(f.readAsStringSync()),
    ];
  }

  void _log(String kind, [Map<String, dynamic> data = const {}]) {
    _file?.writeAsStringSync(
      '${LogEntry(DateTime.now(), kind, data).toLine()}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> _askScan() async {
    try {
      final ok = await _channel.invokeMethod<bool>('startScan') ?? false;
      if (!ok) {
        _log('scan_refused');
        setState(() => _refused++);
      }
    } on PlatformException catch (e) {
      setState(() => _error = 'Scan failed: ${e.message}');
    }
  }

  /// Logs a scan when Android has a newer one. Names stay on the phone; only
  /// hidden ids and signals are logged.
  Future<void> _readScan() async {
    final List<dynamic> raw;
    try {
      raw = await _channel.invokeMethod<List<dynamic>>('scanResults') ?? [];
    } on PlatformException catch (e) {
      setState(() => _error = 'Reading Wi-Fi failed: ${e.message}');
      return;
    }
    if (raw.isEmpty) return;
    final now = DateTime.now();
    final newestAge = raw
        .map((r) => ((r as Map)['ageMs'] as num).toInt())
        .reduce(min);
    final scanAt = now.subtract(Duration(milliseconds: newestAge));
    if (_scanAt != null && !scanAt.isAfter(_scanAt!.add(_pollEvery))) return;

    final readings = <ApReading>[];
    for (final r in raw.cast<Map<dynamic, dynamic>>()) {
      // Older results are left over from earlier scans.
      if ((r['ageMs'] as num) - newestAge > 10000) continue;
      final ap = hideAp(_salt, r['bssid'] as String);
      _names[ap] = (r['ssid'] as String?)?.isNotEmpty ?? false
          ? r['ssid'] as String
          : 'hidden';
      readings.add(ApReading(ap, (r['rssi'] as num).toInt()));
    }
    readings.sort((a, b) => b.rssi.compareTo(a.rssi));
    _log('scan', {
      'aps': [for (final r in readings) r.toJson()],
    });
    setState(() {
      _scan = readings;
      _scanAt = scanAt;
    });
    if (_waitingAt != null) {
      setState(() => _waitingAt = null);
      unawaited(Vibration.vibrate(pattern: [0, 100, 100, 100]));
    }
    _collect(readings);
    _checkNear(readings);
  }

  /// Logs and vibrates when the nearest point changes, as the real app would
  /// trigger.
  void _checkNear(List<ApReading> scan) {
    final best = nearest(_points, scan);
    final id = best != null && best.$2 <= _nearDb ? best.$1.id : null;
    if (id == _nearId) return;
    _nearId = id;
    _log('near', {
      'id': id,
      if (best != null && best.$2.isFinite) 'dB': best.$2,
    });
    if (id != null) unawaited(Vibration.vibrate(duration: 300));
  }

  Future<void> _addPoint() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final text = TextEditingController(text: 'Point ${_points.length + 1}');
        return AlertDialog(
          title: const Text('New point'),
          content: TextField(
            controller: text,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name, e.g. Front door',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, text.text.trim()),
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    _collected.clear();
    setState(() => _collecting = name);
  }

  void _collect(List<ApReading> scan) {
    final name = _collecting;
    if (name == null) return;
    _collected.add(scan);
    if (_collected.length < _scansPerPoint) {
      setState(() {});
      return;
    }
    final aps = fingerprintOf(_collected);
    _collected.clear();
    if (aps.isEmpty) {
      setState(() {
        _collecting = null;
        _error = 'No steady access points here, so "$name" was not saved.';
      });
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    _log('point_added', {
      'id': id,
      'name': name,
      'aps': [for (final a in aps) a.toJson()],
    });
    unawaited(Vibration.vibrate(pattern: [0, 200, 150, 200]));
    setState(() {
      _collecting = null;
      _points = [..._points, WifiPoint(id, name, aps)];
    });
  }

  void _here(WifiPoint p) {
    _log('at_point', {'id': p.id});
    unawaited(Vibration.vibrate(duration: 100));
    setState(() => _waitingAt = p.id);
  }

  Future<void> _remove(WifiPoint p) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${p.name}?'),
        content: const Text('Its earlier records stay in the logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    _log('point_removed', {'id': p.id});
    setState(() => _points = _points.where((x) => x.id != p.id).toList());
  }

  Future<void> _share() async {
    final dir = _dir;
    if (dir == null) return;
    try {
      final temp = await getTemporaryDirectory();
      final zip = File('${temp.path}/wifi-probe-logs.zip');
      await zip.writeAsBytes(
        zipLogs({
          for (final f in dir.listSync().whereType<File>())
            if (f.path.endsWith('.jsonl'))
              f.uri.pathSegments.last: f.readAsBytesSync(),
        }),
      );
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Wi-Fi probe results',
          text: analyzeWifi(_readLogs()).report(),
          files: [XFile(zip.path, mimeType: 'application/zip')],
        ),
      );
    } on Exception catch (e) {
      setState(() => _error = 'Could not share: $e');
    }
  }

  void _showResults() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(analyzeWifi(_readLogs()).report()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final best = nearest(_points, _scan);
    final scanAge = _scanAt == null
        ? null
        : DateTime.now().difference(_scanAt!).inSeconds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi probe'),
        actions: [
          IconButton(
            tooltip: 'Show results',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showResults,
          ),
          IconButton(
            tooltip: 'Share results',
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      floatingActionButton: _collecting == null
          ? FloatingActionButton.extended(
              onPressed: _scan.isEmpty ? null : _addPoint,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add point here'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          Text(
            '${_scan.length} access points heard'
            '${scanAge == null ? ', waiting for a scan' : ', last scan $scanAge s ago'}'
            ' · $_refused refused by Android',
          ),
          if (_refused > 0)
            const Text(
              'Scans are limited. To scan more often, turn off "Wi-Fi scan '
              'throttling" in Developer options.',
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 12),
          if (_collecting != null)
            Card(
              child: ListTile(
                leading: const CircularProgressIndicator(),
                title: Text('Recording "$_collecting"'),
                subtitle: Text(
                  'Stand still here. Scan ${_collected.length + 1} of '
                  '$_scansPerPoint.',
                ),
                trailing: TextButton(
                  onPressed: () => setState(() {
                    _collecting = null;
                    _collected.clear();
                  }),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              title: Text(
                best == null
                    ? 'No points yet'
                    : best.$2 <= _nearDb
                    ? 'Near: ${best.$1.name}'
                    : 'Not near any point',
              ),
              subtitle: best == null
                  ? const Text('Walk to a spot and tap "Add point here".')
                  : Text(
                      'Most like ${best.$1.name}: '
                      '${best.$2.toStringAsFixed(1)} dB '
                      '(near is ${_nearDb.toStringAsFixed(0)} dB or less)',
                    ),
            ),
          ),
          for (final p in _points)
            _PointCard(
              point: p,
              scan: _scan,
              names: _names,
              isNearest: best?.$1.id == p.id,
              waiting: _waitingAt == p.id,
              onHere: () => _here(p),
              onRemove: () => _remove(p),
            ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.point,
    required this.scan,
    required this.names,
    required this.isNearest,
    required this.waiting,
    required this.onHere,
    required this.onRemove,
  });

  final WifiPoint point;
  final List<ApReading> scan;
  final Map<String, String> names;
  final bool isNearest;
  final bool waiting;
  final VoidCallback onHere;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final distance = distanceTo(point, scan);
    return Card(
      shape: isNearest
          ? RoundedRectangleBorder(
              side: BorderSide(color: colors.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    point.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(scan.isEmpty ? '-' : '${distance.toStringAsFixed(1)} dB'),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            if (point.aps.length >= 3)
              SizedBox(height: 220, child: _radar(colors))
            else
              Text(
                'Only ${point.aps.length} steady access points here, too few '
                'for a chart.',
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                _legend(colors.primary, 'Recorded'),
                _legend(colors.tertiary, 'Now'),
              ],
            ),
            for (final (i, a) in point.aps.indexed)
              Text(
                '${i + 1}. ${names[a.ap] ?? 'not heard yet'}: '
                '${a.rssi} dBm recorded, ${_now(a.ap)} now',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: waiting
                  ? const Text(
                      'Stand still here until it vibrates twice (next scan, '
                      'up to 30 s).',
                      textAlign: TextAlign.center,
                    )
                  : OutlinedButton.icon(
                      onPressed: onHere,
                      icon: const Icon(Icons.my_location),
                      label: const Text("I'm here now"),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _now(String ap) {
    final rssi = rssiIn(scan, ap);
    return rssi == floorRssi ? 'not heard' : '$rssi dBm';
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 4),
      Text(label),
    ],
  );

  /// Stronger signals reach further out. The scale is fixed from not heard
  /// (centre) to -30 dBm (edge), so charts can be compared.
  Widget _radar(ColorScheme colors) {
    double value(int rssi) => (rssi - floorRssi).clamp(0, 70).toDouble();
    RadarDataSet set(List<double> values, Color color, double alpha) =>
        RadarDataSet(
          dataEntries: [for (final v in values) RadarEntry(value: v)],
          borderColor: color,
          fillColor: color.withValues(alpha: alpha),
          borderWidth: 2,
          entryRadius: 2,
        );
    final n = point.aps.length;
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 3,
        ticksTextStyle: const TextStyle(fontSize: 0),
        radarBorderData: BorderSide(color: colors.outlineVariant),
        gridBorderData: BorderSide(color: colors.outlineVariant),
        tickBorderData: BorderSide(color: colors.outlineVariant),
        getTitle: (i, _) => RadarChartTitle(text: '${i + 1}'),
        dataSets: [
          // Fixes the scale.
          set(List.filled(n, 70), Colors.transparent, 0),
          set([for (final a in point.aps) value(a.rssi)], colors.primary, 0.2),
          set(
            [for (final a in point.aps) value(rssiIn(scan, a.ap))],
            colors.tertiary,
            0.15,
          ),
        ],
      ),
    );
  }
}

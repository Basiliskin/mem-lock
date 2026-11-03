import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// One line of the probe's log. Pure Dart, so the report tool can read it.
class LogEntry {
  LogEntry(this.time, this.kind, this.data);

  factory LogEntry.parse(String line) {
    final map = jsonDecode(line) as Map<String, dynamic>;
    return LogEntry(
      DateTime.parse(map['time'] as String),
      map['kind'] as String,
      (map['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  final DateTime time;
  final String kind;
  final Map<String, dynamic> data;

  String toLine() => jsonEncode({
    'time': time.toUtc().toIso8601String(),
    'kind': kind,
    'data': data,
  });
}

/// Reads a log, skipping lines a killed app may have cut off.
List<LogEntry> parseLog(String text) {
  final entries = <LogEntry>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    try {
      entries.add(LogEntry.parse(line));
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  return entries;
}

/// A Wi-Fi access point's address, hidden. The same address gives the same id
/// with the same [salt], so logs can be compared, but the id can't be looked
/// up in public Wi-Fi maps to find the building.
String hideAp(String salt, String bssid) => sha256
    .convert(utf8.encode('$salt:${bssid.toLowerCase()}'))
    .toString()
    .substring(0, 12);

/// Signals weaker than this are treated as not heard.
const floorRssi = -100;
const pointAps = 5;

class ApReading {
  const ApReading(this.ap, this.rssi);

  factory ApReading.fromJson(Map<String, dynamic> m) =>
      ApReading(m['ap'] as String, (m['rssi'] as num).toInt());

  final String ap;
  final int rssi;

  Map<String, dynamic> toJson() => {'ap': ap, 'rssi': rssi};
}

/// A marked spot, described by its strongest access points.
class WifiPoint {
  const WifiPoint(this.id, this.name, this.aps);

  final String id;
  final String name;
  final List<ApReading> aps;
}

/// The [top] access points heard in at least half of [scans], strongest first,
/// each with its average signal.
List<ApReading> fingerprintOf(
  List<List<ApReading>> scans, {
  int top = pointAps,
}) {
  final heard = <String, List<int>>{};
  for (final scan in scans) {
    for (final r in scan) {
      (heard[r.ap] ??= []).add(r.rssi);
    }
  }
  final steady = [
    for (final MapEntry(key: ap, value: values) in heard.entries)
      if (values.length * 2 >= scans.length)
        ApReading(ap, (values.reduce((a, b) => a + b) / values.length).round()),
  ]..sort((a, b) => b.rssi.compareTo(a.rssi));
  return steady.take(top).toList();
}

int rssiIn(List<ApReading> scan, String ap) {
  for (final r in scan) {
    if (r.ap == ap) return r.rssi;
  }
  return floorRssi;
}

/// How unlike [point] a [scan] is, in dB. 0 is identical. Access points the
/// scan doesn't hear count as [floorRssi].
double distanceTo(WifiPoint point, List<ApReading> scan) {
  if (point.aps.isEmpty) return double.infinity;
  var sum = 0.0;
  for (final a in point.aps) {
    final d = a.rssi - rssiIn(scan, a.ap);
    sum += d * d;
  }
  return sqrt(sum / point.aps.length);
}

/// The point most like [scan], or null with no points.
(WifiPoint, double)? nearest(List<WifiPoint> points, List<ApReading> scan) {
  (WifiPoint, double)? best;
  for (final p in points) {
    final d = distanceTo(p, scan);
    if (best == null || d < best.$2) best = (p, d);
  }
  return best;
}

/// The points left after replaying additions and removals in order.
List<WifiPoint> pointsIn(List<LogEntry> log) {
  final points = <String, WifiPoint>{};
  for (final e in log) {
    if (e.kind == 'point_added') {
      final id = e.data['id'] as String;
      points[id] = WifiPoint(id, e.data['name'] as String, [
        for (final a in e.data['aps'] as List<dynamic>)
          ApReading.fromJson(a as Map<String, dynamic>),
      ]);
    } else if (e.kind == 'point_removed') {
      points.remove(e.data['id']);
    }
  }
  return points.values.toList();
}

List<ApReading> scanOf(LogEntry e) => [
  for (final a in e.data['aps'] as List<dynamic>)
    ApReading.fromJson(a as Map<String, dynamic>),
];

/// A "here" tap is checked against the first scan after it, within this
/// long. Scans can be a minute apart, so the tester waits at the point for it.
const markWindow = Duration(seconds: 30);

/// A scan this little before a tap still counts, since it may have finished
/// as the tester tapped.
const markLead = Duration(seconds: 3);

/// One "I'm at this point" tap, checked against the scan nearest in time.
class MarkCheck {
  MarkCheck(this.point, this.found, this.ownDistance, this.otherDistance);

  final WifiPoint point;

  /// The point the scan looked most like, or null with no scan near the tap.
  final WifiPoint? found;
  final double? ownDistance;

  /// Distance to the closest other point; the gap to [ownDistance] is the
  /// safety margin.
  final double? otherDistance;

  bool get correct => found?.id == point.id;
}

class WifiAnalysis {
  WifiAnalysis(this.points, this.marks, this.scans, this.throttled, this.gaps);

  final List<WifiPoint> points;
  final List<MarkCheck> marks;
  final int scans;
  final int throttled;

  /// Time between scans, sorted.
  final List<Duration> gaps;

  int get correct => marks.where((m) => m.correct).length;

  Duration? get medianGap => gaps.isEmpty ? null : gaps[gaps.length ~/ 2];

  String report() {
    final b = StringBuffer()
      ..writeln(
        '${points.length} points, $scans scans, $throttled refused by Android'
        ', median ${medianGap?.inSeconds ?? '-'} s between scans',
      )
      ..writeln('Points (distance in dB, lower is more alike):');
    for (final p in points) {
      final others = [
        for (final o in points)
          if (o.id != p.id) '${o.name} ${_dB(distanceTo(p, o.aps))}',
      ];
      b.writeln(
        '  ${p.name}: ${p.aps.length} access points'
        '${others.isEmpty ? '' : ', from others: ${others.join(', ')}'}',
      );
    }
    b.writeln(
      '"I\'m here" taps: $correct of ${marks.length} matched the right point',
    );
    for (final m in marks) {
      b.writeln(
        '  ${m.point.name}: '
        '${m.found == null ? 'no scan within ${markWindow.inSeconds} s' : 'looked like ${m.found!.name}'}'
        ', own ${_dB(m.ownDistance)}, nearest other ${_dB(m.otherDistance)}',
      );
    }
    return b.toString();
  }
}

String _dB(double? d) =>
    d == null || d.isInfinite ? '-' : '${d.toStringAsFixed(1)} dB';

WifiAnalysis analyzeWifi(List<LogEntry> input) {
  final log = [...input]..sort((a, b) => a.time.compareTo(b.time));
  final points = pointsIn(log);
  final byId = {for (final p in points) p.id: p};
  final scans = log.where((e) => e.kind == 'scan').toList();

  final gaps = [
    for (var i = 1; i < scans.length; i++)
      scans[i].time.difference(scans[i - 1].time),
  ]..sort();

  final marks = <MarkCheck>[];
  for (final e in log.where((e) => e.kind == 'at_point')) {
    final point = byId[e.data['id']];
    if (point == null) continue;
    LogEntry? closest;
    for (final s in scans) {
      final after = s.time.difference(e.time);
      if (after < -markLead) continue;
      if (after <= markWindow) closest = s;
      break;
    }
    if (closest == null) {
      marks.add(MarkCheck(point, null, null, null));
      continue;
    }
    final scan = scanOf(closest);
    final others = [
      for (final p in points)
        if (p.id != point.id) distanceTo(p, scan),
    ]..sort();
    marks.add(
      MarkCheck(
        point,
        nearest(points, scan)?.$1,
        distanceTo(point, scan),
        others.isEmpty ? null : others.first,
      ),
    );
  }

  return WifiAnalysis(
    points,
    marks,
    scans.length,
    log.where((e) => e.kind == 'scan_refused').length,
    gaps,
  );
}

/// All the logs in one file, for sharing. Keys are file names.
Uint8List zipLogs(Map<String, List<int>> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.addFile(ArchiveFile.bytes(key, value));
  }
  return ZipEncoder().encodeBytes(archive);
}

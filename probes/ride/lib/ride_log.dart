import 'dart:convert';

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

/// Reads a log, skipping lines that can't be read. A killed app can leave the
/// last line cut off, and that must not lose the rest of a journey.
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

const _walkingKinds = {'WALKING', 'ON_FOOT', 'RUNNING'};
const minConfidence = 50;
const reminderLimit = Duration(seconds: 60);
const requiredRides = 10;
const requiredWithinLimit = 8;

bool _isWalking(LogEntry e) =>
    e.kind == 'activity' &&
    _walkingKinds.contains(e.data['kind']) &&
    ((e.data['confidence'] as num?) ?? 0) >= minConfidence;

class Ride {
  Ride(this.train, this.delay, this.sawVehicle, this.walkingDuringRide);

  final String train;

  /// From tapping "got off" to the first confident walking signal, or null if
  /// none came before the next ride started.
  final Duration? delay;
  final bool sawVehicle;
  final int walkingDuringRide;

  bool get withinLimit => delay != null && delay! <= reminderLimit;
}

enum Verdict { pass, fail, notEnoughRides }

class Analysis {
  Analysis(this.rides, this.longestGap);

  final List<Ride> rides;
  final Duration longestGap;

  /// Fails as soon as a pass is no longer possible only when all rides are in:
  /// below the required count the result is simply not enough data.
  Verdict get verdict {
    if (rides.length < requiredRides) return Verdict.notEnoughRides;
    final good = rides.where((r) => r.withinLimit).length;
    return good * requiredRides >= requiredWithinLimit * rides.length
        ? Verdict.pass
        : Verdict.fail;
  }

  String report() {
    final b = StringBuffer();
    for (final (i, r) in rides.indexed) {
      b.writeln(
        'Ride ${i + 1} (${r.train}): '
        'delay ${r.delay == null ? 'none detected' : '${r.delay!.inSeconds} s'}, '
        'vehicle seen ${r.sawVehicle ? 'yes' : 'no'}, '
        'walking during ride ${r.walkingDuringRide}',
      );
    }
    b.writeln('Within ${reminderLimit.inSeconds} s, by type:');
    for (final type in rides.map((r) => r.train).toSet()) {
      final of = rides.where((r) => r.train == type);
      b.writeln(
        '  $type: ${of.where((r) => r.withinLimit).length} of ${of.length}',
      );
    }
    b.writeln('Longest gap in the log: ${longestGap.inSeconds} s');
    b.writeln(switch (verdict) {
      Verdict.pass => 'Early FT-2: pass',
      Verdict.fail => 'Early FT-2: fail',
      Verdict.notEnoughRides =>
        'Early FT-2: not enough rides (${rides.length} of $requiredRides)',
    });
    return b.toString();
  }
}

Analysis analyze(List<LogEntry> input) {
  final log = [...input]..sort((a, b) => a.time.compareTo(b.time));

  var longestGap = Duration.zero;
  for (var i = 1; i < log.length; i++) {
    final gap = log[i].time.difference(log[i - 1].time);
    if (gap > longestGap) longestGap = gap;
  }

  final rides = <Ride>[];
  for (var i = 0; i < log.length; i++) {
    if (log[i].kind != 'ride_start') continue;

    var sawVehicle = false;
    var walking = 0;
    var j = i + 1;
    for (; j < log.length; j++) {
      final e = log[j];
      if (e.kind == 'got_off' || e.kind == 'ride_start') break;
      if (e.kind == 'activity' && e.data['kind'] == 'IN_VEHICLE') {
        sawVehicle = true;
      }
      if (_isWalking(e)) walking++;
    }
    if (j >= log.length || log[j].kind != 'got_off') continue;

    final gotOff = log[j].time;
    Duration? delay;
    for (var k = j + 1; k < log.length; k++) {
      if (log[k].kind == 'ride_start') break;
      if (_isWalking(log[k])) {
        delay = log[k].time.difference(gotOff);
        break;
      }
    }
    rides.add(
      Ride(
        (log[i].data['train'] as String?) ?? 'unknown',
        delay,
        sawVehicle,
        walking,
      ),
    );
  }
  return Analysis(rides, longestGap);
}

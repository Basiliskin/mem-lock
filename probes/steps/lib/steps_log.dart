import 'dart:convert';
import 'dart:math';

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

/// How much the acceleration size varied over a window, in m/s².
double motionStd(List<double> magnitudes) {
  if (magnitudes.isEmpty) return 0;
  final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
  final sum = magnitudes.fold<double>(0, (t, m) => t + (m - mean) * (m - mean));
  return sqrt(sum / magnitudes.length);
}

enum Source { step, pedestrian, motion, activity }

const _candidates = [Source.step, Source.pedestrian, Source.motion];
const _walkingKinds = {'WALKING', 'ON_FOOT', 'RUNNING'};
const minConfidence = 50;
const motionThreshold = 1.5;

/// Tapping End moves the phone, so signals just before the tap don't count.
const endMargin = Duration(seconds: 15);
const requiredWalks = 10;
const requiredStill = 4;

/// "Clear benefit" for AC-14.2: seen on 90% of walks, this much sooner than
/// Activity Recognition, and no more false signals than it gives.
const requiredDetectedPercent = 90;
const requiredLead = Duration(seconds: 15);

Source? _sourceOf(LogEntry e) => switch (e.kind) {
  'step' => Source.step,
  'pedestrian' when e.data['status'] == 'walking' => Source.pedestrian,
  'motion' when ((e.data['std'] as num?) ?? 0) >= motionThreshold =>
    Source.motion,
  'activity'
      when _walkingKinds.contains(e.data['kind']) &&
          ((e.data['confidence'] as num?) ?? 0) >= minConfidence =>
    Source.activity,
  _ => null,
};

class Walk {
  Walk(this.delays);

  /// A source with no signal during the walk has no entry.
  final Map<Source, Duration> delays;
}

class StillSegment {
  StillSegment(this.type, this.falseSignals);

  final String type;
  final Map<Source, int> falseSignals;
}

enum Verdict { keep, drop, notEnoughData }

class Analysis {
  Analysis(this.walks, this.still, this.longestGap);

  final List<Walk> walks;
  final List<StillSegment> still;
  final Duration longestGap;

  int detected(Source s) => walks.where((w) => w.delays.containsKey(s)).length;

  Duration? medianDelay(Source s) {
    final d = [for (final w in walks) ?w.delays[s]]..sort();
    return d.isEmpty ? null : d[d.length ~/ 2];
  }

  int falseSegments(Source s) =>
      still.where((x) => (x.falseSignals[s] ?? 0) > 0).length;

  List<Source> get keepers => _candidates.where(_clearlyBetter).toList();

  bool _clearlyBetter(Source s) {
    final median = medianDelay(s);
    if (median == null) return false;
    if (detected(s) * 100 < requiredDetectedPercent * walks.length) {
      return false;
    }
    if (falseSegments(s) > falseSegments(Source.activity)) return false;
    final baseline = medianDelay(Source.activity);
    return baseline == null || median + requiredLead <= baseline;
  }

  Verdict get verdict {
    if (walks.length < requiredWalks || still.length < requiredStill) {
      return Verdict.notEnoughData;
    }
    return keepers.isEmpty ? Verdict.drop : Verdict.keep;
  }

  String report() {
    final b = StringBuffer()
      ..writeln('${walks.length} walks, ${still.length} still segments');
    for (final s in Source.values) {
      final median = medianDelay(s);
      b.writeln(
        '${s.name}: seen on ${detected(s)} of ${walks.length} walks, '
        'median delay ${median == null ? '-' : '${median.inSeconds} s'}, '
        'false signals in ${falseSegments(s)} of ${still.length} still segments',
      );
    }
    b.writeln('Longest gap in the log: ${longestGap.inSeconds} s');
    b.writeln(switch (verdict) {
      Verdict.keep =>
        'Steps experiment: keep (${keepers.map((s) => s.name).join(', ')})',
      Verdict.drop => 'Steps experiment: drop',
      Verdict.notEnoughData =>
        'Steps experiment: not enough data (need $requiredWalks walks and '
            '$requiredStill still segments)',
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

  final walks = <Walk>[];
  final still = <StillSegment>[];
  for (var i = 0; i < log.length; i++) {
    if (log[i].kind != 'segment_start') continue;
    final start = log[i].time;
    final type = (log[i].data['type'] as String?) ?? 'unknown';

    var j = i + 1;
    while (j < log.length &&
        log[j].kind != 'segment_end' &&
        log[j].kind != 'segment_start') {
      j++;
    }
    if (j >= log.length || log[j].kind != 'segment_end') continue;
    final inside = log.sublist(i + 1, j);

    if (type == 'walk') {
      final delays = <Source, Duration>{};
      for (final e in inside) {
        final s = _sourceOf(e);
        if (s != null) delays.putIfAbsent(s, () => e.time.difference(start));
      }
      walks.add(Walk(delays));
    } else {
      final cutoff = log[j].time.subtract(endMargin);
      final counts = <Source, int>{};
      for (final e in inside) {
        final s = _sourceOf(e);
        if (s != null && e.time.isBefore(cutoff)) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
      }
      still.add(StillSegment(type, counts));
    }
  }
  return Analysis(walks, still, longestGap);
}

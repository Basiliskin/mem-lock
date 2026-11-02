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

/// Steps since the previous signal. Never the phone's running total. The first
/// signal only sets the starting point, and a restarted phone counts from 0.
int stepsSince(int? previous, int current) =>
    previous == null || current < previous ? 0 : current - previous;

/// Sensors may deliver several steps together.
class StepSignal {
  const StepSignal(this.time, this.steps);

  final DateTime time;
  final int steps;
}

/// Unbroken Walks reaching [limit] steps. A long walk counts once. A gap breaks
/// the walk unless the steps delivered after it could have filled that gap.
int unbrokenWalks(List<StepSignal> signals, int limit, Duration pause) {
  var found = 0;
  var run = 0;
  var counted = false;
  DateTime? previous;
  for (final s in signals) {
    if (s.steps <= 0) continue;
    if (previous != null) {
      final gap = s.time.difference(previous);
      if (gap > pause && gap.inMilliseconds / s.steps > pause.inMilliseconds) {
        run = 0;
        counted = false;
      }
    }
    run += s.steps;
    previous = s.time;
    if (run >= limit && !counted) {
      found++;
      counted = true;
    }
  }
  return found;
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

// Unbroken Walk checks. These are starting values, set before any real walks.
const unbrokenLimits = [12, 30, 40];
const strictestLimit = 40;
const maxPause = Duration(seconds: 3);
const pausesToCompare = [Duration(seconds: 2), maxPause, Duration(seconds: 5)];
const requiredElderlyWalks = 3;
const requiredDailyHours = 8;
const wakingHoursPerDay = 16;
const maxFalseWalksPerDay = 1;
const _elderlyWalkTypes = {'slow_walk', 'walker_walk'};

Source? _sourceOf(LogEntry e) => switch (e.kind) {
  'step' when e.data['steps'] != 0 => Source.step,
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
  Walk(this.delays, {this.steps = const []});

  /// A source with no signal during the walk has no entry.
  final Map<Source, Duration> delays;
  final List<StepSignal> steps;

  bool reaches(int limit, Duration pause) =>
      unbrokenWalks(steps, limit, pause) > 0;
}

/// A long segment of ordinary life, without really leaving the place.
class DailySegment {
  DailySegment(this.length, this.steps);

  final Duration length;
  final List<StepSignal> steps;
}

class StillSegment {
  StillSegment(this.type, this.falseSignals);

  final String type;
  final Map<Source, int> falseSignals;
}

enum Verdict { keep, drop, notEnoughData }

class Analysis {
  Analysis(
    this.walks,
    this.still,
    this.longestGap, {
    this.elderlyWalks = const [],
    this.daily = const [],
  });

  final List<Walk> walks;
  final List<StillSegment> still;
  final Duration longestGap;
  final List<Walk> elderlyWalks;
  final List<DailySegment> daily;

  int _reaching(List<Walk> from, Duration pause) =>
      from.where((w) => w.reaches(strictestLimit, pause)).length;

  bool _mostReach(List<Walk> from) =>
      _reaching(from, maxPause) * 100 >= requiredDetectedPercent * from.length;

  double get dailyHours =>
      daily.fold<int>(0, (t, d) => t + d.length.inSeconds) / 3600;

  int falseWalks(int limit) =>
      daily.fold(0, (t, d) => t + unbrokenWalks(d.steps, limit, maxPause));

  double get falseWalksPerDay => dailyHours == 0
      ? 0
      : falseWalks(strictestLimit) * wakingHoursPerDay / dailyHours;

  Verdict get unbrokenVerdict {
    if (walks.length < requiredWalks ||
        elderlyWalks.length < requiredElderlyWalks ||
        dailyHours < requiredDailyHours) {
      return Verdict.notEnoughData;
    }
    return _mostReach(walks) &&
            _mostReach(elderlyWalks) &&
            falseWalksPerDay <= maxFalseWalksPerDay
        ? Verdict.keep
        : Verdict.drop;
  }

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
    b.writeln('Longest gap during an activity: ${longestGap.inSeconds} s');
    b.writeln(switch (verdict) {
      Verdict.keep =>
        'Steps experiment: keep (${keepers.map((s) => s.name).join(', ')})',
      Verdict.drop => 'Steps experiment: drop',
      Verdict.notEnoughData =>
        'Steps experiment: not enough data (need $requiredWalks walks and '
            '$requiredStill still segments)',
    });
    b.writeln('Unbroken Walk, $strictestLimit steps:');
    for (final pause in pausesToCompare) {
      b.writeln(
        '  pause up to ${pause.inSeconds} s: '
        '${_reaching(walks, pause)} of ${walks.length} normal walks, '
        '${_reaching(elderlyWalks, pause)} of ${elderlyWalks.length} '
        'elderly walks',
      );
    }
    b.writeln('Daily life: ${dailyHours.toStringAsFixed(1)} hours');
    for (final limit in unbrokenLimits) {
      b.writeln('  $limit steps: ${falseWalks(limit)} false walks');
    }
    b.writeln(
      '  ${falseWalksPerDay.toStringAsFixed(1)} a day at $strictestLimit steps',
    );
    b.writeln(switch (unbrokenVerdict) {
      Verdict.keep => 'Unbroken Walk: pass',
      Verdict.drop => 'Unbroken Walk: fail',
      Verdict.notEnoughData =>
        'Unbroken Walk: not enough data (need $requiredWalks normal walks, '
            '$requiredElderlyWalks elderly walks and '
            '$requiredDailyHours hours of daily life)',
    });
    return b.toString();
  }
}

Analysis analyze(List<LogEntry> input) {
  final log = [...input]..sort((a, b) => a.time.compareTo(b.time));

  // Only inside activities, because logging is off between them.
  var longestGap = Duration.zero;
  final walks = <Walk>[];
  final still = <StillSegment>[];
  final elderlyWalks = <Walk>[];
  final daily = <DailySegment>[];
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
    for (var k = i + 1; k <= j; k++) {
      final gap = log[k].time.difference(log[k - 1].time);
      if (gap > longestGap) longestGap = gap;
    }

    if (type == 'daily') {
      final cutoff = log[j].time.subtract(endMargin);
      daily.add(
        DailySegment(
          log[j].time.difference(start),
          _stepSignals(inside.where((e) => e.time.isBefore(cutoff))),
        ),
      );
    } else if (type == 'walk' || _elderlyWalkTypes.contains(type)) {
      final delays = <Source, Duration>{};
      for (final e in inside) {
        final s = _sourceOf(e);
        if (s != null) delays.putIfAbsent(s, () => e.time.difference(start));
      }
      final walk = Walk(delays, steps: _stepSignals(inside));
      (type == 'walk' ? walks : elderlyWalks).add(walk);
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
  return Analysis(
    walks,
    still,
    longestGap,
    elderlyWalks: elderlyWalks,
    daily: daily,
  );
}

/// A log line without a number holds one step.
List<StepSignal> _stepSignals(Iterable<LogEntry> entries) => [
  for (final e in entries)
    if (e.kind == 'step')
      StepSignal(e.time, ((e.data['steps'] as num?) ?? 1).toInt()),
];

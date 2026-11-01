import 'package:flutter_test/flutter_test.dart';
import 'package:steps_probe/steps_log.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));

LogEntry open(int s, String type) =>
    LogEntry(at(s), 'segment_start', {'type': type});
LogEntry close(int s) => LogEntry(at(s), 'segment_end', {});
LogEntry step(int s) => LogEntry(at(s), 'step', {});
LogEntry walkStatus(int s) =>
    LogEntry(at(s), 'pedestrian', {'status': 'walking'});
LogEntry motion(int s, double std) => LogEntry(at(s), 'motion', {'std': std});
LogEntry act(int s, String kind, [int conf = 90]) =>
    LogEntry(at(s), 'activity', {'kind': kind, 'confidence': conf});

/// [walks] walks with a step after [stepAt] s and activity after [activityAt] s,
/// followed by [still] clean sits.
List<LogEntry> session({
  int walks = 10,
  int still = 4,
  int? stepAt = 3,
  int? activityAt = 40,
}) {
  final log = <LogEntry>[];
  var s = 0;
  for (var i = 0; i < walks; i++) {
    log.add(open(s, 'walk'));
    if (stepAt != null) log.add(step(s + stepAt));
    if (activityAt != null) log.add(act(s + activityAt, 'WALKING'));
    log.add(close(s + 120));
    s += 200;
  }
  for (var i = 0; i < still; i++) {
    log.addAll([open(s, 'sit'), close(s + 120)]);
    s += 200;
  }
  return log;
}

void main() {
  test('entries survive a log line, and a damaged line is skipped', () {
    final back = LogEntry.parse(motion(1, 2.5).toLine());
    expect(back.time, at(1));
    expect(back.data['std'], 2.5);
    expect(parseLog('${step(0).toLine()}\n{"time":"20'), hasLength(1));
  });

  test('motionStd is 0 for a still phone and grows with shaking', () {
    expect(motionStd(const []), 0);
    expect(motionStd(const [9.8, 9.8, 9.8]), 0);
    expect(motionStd(const [8.0, 12.0]), closeTo(2, 0.001));
  });

  group('walk delays', () {
    test('each source is timed from the start of the walk', () {
      final a = analyze([
        open(100, 'walk'),
        step(105),
        walkStatus(110),
        motion(102, 3),
        act(140, 'WALKING'),
        close(200),
      ]);
      expect(a.walks.single.delays, {
        Source.step: const Duration(seconds: 5),
        Source.pedestrian: const Duration(seconds: 10),
        Source.motion: const Duration(seconds: 2),
        Source.activity: const Duration(seconds: 40),
      });
    });

    test('ignores weak signals, and signals outside the walk', () {
      final a = analyze([
        step(90),
        open(100, 'walk'),
        motion(102, 0.1),
        act(103, 'WALKING', 30),
        act(104, 'STILL'),
        close(200),
        step(210),
      ]);
      expect(a.walks.single.delays, isEmpty);
    });

    test('a segment that never ended is dropped', () {
      expect(analyze([open(0, 'walk'), step(3)]).walks, isEmpty);
    });
  });

  group('still segments', () {
    test('counts false signals but not the handling before the end tap', () {
      final a = analyze([
        open(0, 'vehicle'),
        step(10),
        step(20),
        motion(30, 3),
        step(95),
        close(100),
      ]);
      final s = a.still.single;
      expect(s.type, 'vehicle');
      expect(s.falseSignals[Source.step], 2);
      expect(s.falseSignals[Source.motion], 1);
    });
  });

  group('verdict', () {
    test('keeps a source clearly earlier than activity recognition', () {
      final a = analyze(session());
      expect(a.verdict, Verdict.keep);
      expect(a.keepers, contains(Source.step));
      expect(a.report(), contains('Steps experiment: keep'));
    });

    test('not enough data below 10 walks or 4 still segments', () {
      expect(analyze(session(walks: 9)).verdict, Verdict.notEnoughData);
      expect(analyze(session(still: 3)).verdict, Verdict.notEnoughData);
    });

    test('drops when steps are not clearly earlier', () {
      expect(analyze(session(stepAt: 30, activityAt: 40)).verdict, Verdict.drop);
    });

    test('drops when steps often never arrive', () {
      final log = session(walks: 8, still: 4, stepAt: 3);
      var s = 10000;
      for (var i = 0; i < 2; i++) {
        log.addAll([open(s, 'walk'), act(s + 40, 'WALKING'), close(s + 120)]);
        s += 200;
      }
      expect(analyze(log).verdict, Verdict.drop);
    });

    test('drops when steps give more false signals than activity', () {
      final log = session();
      log.addAll([open(90000, 'vehicle'), step(90010), close(90100)]);
      expect(analyze(log).keepers, isNot(contains(Source.step)));
    });

    test('a source can win when activity recognition never fires', () {
      expect(analyze(session(activityAt: null)).verdict, Verdict.keep);
    });

    test('drops when nothing is detected at all', () {
      expect(
        analyze(session(stepAt: null, activityAt: null)).verdict,
        Verdict.drop,
      );
    });
  });

  test('the report holds no step count', () {
    expect(analyze(session()).report(), isNot(contains('count')));
  });
}

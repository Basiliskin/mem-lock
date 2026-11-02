import 'dart:convert';

import 'package:archive/archive.dart';
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
      expect(
        analyze(session(stepAt: 30, activityAt: 40)).verdict,
        Verdict.drop,
      );
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

  group('Unbroken Walk', () {
    const pause = Duration(seconds: 3);
    List<StepSignal> everySecond(int from, int steps) => [
      for (var i = 0; i < steps; i++) StepSignal(at(from + i), 1),
    ];

    test('a long walk reaching the limit counts once', () {
      expect(unbrokenWalks(everySecond(0, 100), 40, pause), 1);
    });

    test('short bursts do not add up', () {
      final bursts = [...everySecond(0, 30), ...everySecond(100, 30)];
      expect(unbrokenWalks(bursts, 40, pause), 0);
    });

    test('each walk after a real pause counts again', () {
      final two = [...everySecond(0, 40), ...everySecond(100, 40)];
      expect(unbrokenWalks(two, 40, pause), 2);
    });

    test('a delayed batch of steps does not look like a pause', () {
      final batched = [StepSignal(at(0), 1), StepSignal(at(30), 40)];
      expect(unbrokenWalks(batched, 40, pause), 1);
    });

    test('a pause just over the limit breaks the walk', () {
      final signals = [StepSignal(at(0), 39), StepSignal(at(4), 1)];
      expect(unbrokenWalks(signals, 40, pause), 0);
    });

    test('the first signal and a restarted phone add no steps', () {
      expect(stepsSince(null, 5000), 0);
      expect(stepsSince(5000, 5003), 3);
      expect(stepsSince(5000, 2), 0);
    });

    /// [hours] of daily life holding [falseWalks] 40-step walks.
    List<LogEntry> daily(int s, int hours, int falseWalks) => [
      open(s, 'daily'),
      for (var w = 0; w < falseWalks; w++)
        LogEntry(at(s + 10 + w * 100), 'step', {'steps': 40}),
      close(s + hours * 3600),
    ];

    List<LogEntry> elderly(int s, {int steps = 40}) => [
      open(s, 'slow_walk'),
      LogEntry(at(s + 30), 'step', {'steps': steps}),
      close(s + 120),
    ];

    /// session() walks hold one step each, so give them real walks here.
    List<LogEntry> normalWalks() => [
      for (var i = 0; i < requiredWalks; i++) ...[
        open(i * 200, 'walk'),
        LogEntry(at(i * 200 + 30), 'step', {'steps': 40}),
        close(i * 200 + 120),
      ],
    ];

    List<LogEntry> full({int falseWalks = 0, int elderlySteps = 40}) => [
      ...normalWalks(),
      ...elderly(10000, steps: elderlySteps),
      ...elderly(10200, steps: elderlySteps),
      ...elderly(10400, steps: elderlySteps),
      ...daily(20000, 8, falseWalks),
    ];

    test('passes with walks reached and few false walks', () {
      final a = analyze(full());
      expect(a.unbrokenVerdict, Verdict.keep);
      expect(a.report(), contains('Unbroken Walk: pass'));
    });

    test('not enough data without enough of each part', () {
      expect(analyze(normalWalks()).unbrokenVerdict, Verdict.notEnoughData);
      final short = [
        ...normalWalks(),
        ...elderly(10000),
        ...elderly(10200),
        ...elderly(10400),
        ...daily(20000, 7, 0),
      ];
      expect(analyze(short).unbrokenVerdict, Verdict.notEnoughData);
    });

    test('fails when an elderly walker\'s steps are missed', () {
      expect(analyze(full(elderlySteps: 10)).unbrokenVerdict, Verdict.drop);
    });

    test('one false walk in 8 hours is 2 a day, so it fails', () {
      final a = analyze(full(falseWalks: 1));
      expect(a.falseWalksPerDay, 2);
      expect(a.unbrokenVerdict, Verdict.drop);
    });

    test('new segment types are not still segments or normal walks', () {
      final a = analyze(full());
      expect(a.still, isEmpty);
      expect(a.walks, hasLength(requiredWalks));
      expect(a.elderlyWalks, hasLength(3));
    });

    test('handling just before the end tap is not a false walk', () {
      final log = [
        open(0, 'daily'),
        LogEntry(at(95), 'step', {'steps': 40}),
        close(100),
      ];
      expect(analyze(log).falseWalks(40), 0);
    });
  });

  test('the zip holds every log, unchanged', () {
    final zip = ZipDecoder().decodeBytes(
      zipLogs({'a.jsonl': utf8.encode('one'), 'b.jsonl': utf8.encode('two')}),
    );
    expect(zip.files.map((f) => f.name), ['a.jsonl', 'b.jsonl']);
    expect(utf8.decode(zip.files.last.content), 'two');
  });

  test('the report holds no step count', () {
    expect(analyze(session()).report(), isNot(contains('count')));
  });
}

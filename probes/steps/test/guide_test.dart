import 'package:flutter_test/flutter_test.dart';
import 'package:steps_probe/guide.dart';
import 'package:steps_probe/steps_log.dart';

final t0 = DateTime.utc(2026, 11, 1, 10);
DateTime at(int s) => t0.add(Duration(seconds: s));

List<LogEntry> segment(int s, String type, int length, {int steps = 40}) => [
  LogEntry(at(s), 'segment_start', {'type': type}),
  LogEntry(at(s + 30), 'step', {'steps': steps}),
  LogEntry(at(s + length), 'segment_end', {}),
];

List<LogEntry> many(int from, String type, int n, int length) => [
  for (var i = 0; i < n; i++)
    ...segment(from + i * (length + 10), type, length),
];

String? next(List<LogEntry> log) => nextGoal(guideGoals(analyze(log)))?.title;

void main() {
  test('works through the goals in order', () {
    expect(next([]), 'Normal walks');
    final walks = many(0, 'walk', 10, 120);
    expect(next(walks), 'Sitting or riding');
    final still = [...walks, ...many(10000, 'sit', 4, 300)];
    expect(next(still), 'Elderly walks');
    final elderly = [...still, ...many(20000, 'slow_walk', 3, 120)];
    expect(next(elderly), 'Daily life');
    final done = [...elderly, ...segment(30000, 'daily', 8 * 3600, steps: 1)];
    expect(next(done), isNull);
  });

  test('progress is the sum across sessions, in any order', () {
    final goals = guideGoals(
      analyze([
        ...many(0, 'vehicle', 2, 300),
        ...many(5000, 'sit', 1, 300),
        ...many(9000, 'walker_walk', 1, 120),
      ]),
    );
    expect(goals[1].done, 3);
    expect(goals[2].done, 1);
  });

  test('a discarded activity does not count', () {
    final log = [
      LogEntry(at(0), 'segment_start', {'type': 'walk'}),
      LogEntry(at(10), 'step', {'steps': 5}),
      LogEntry(at(20), 'segment_cancel', {}),
      ...segment(100, 'walk', 120),
    ];
    expect(analyze(log).walks, hasLength(1));
  });

  test('warns only when finished walks gave no steps', () {
    expect(noStepsSeen(analyze([])), isFalse);
    expect(noStepsSeen(analyze(segment(0, 'walk', 120))), isFalse);
    expect(noStepsSeen(analyze(segment(0, 'walk', 120, steps: 0))), isTrue);
  });

  test('the time between activities is not a gap in the log', () {
    final a = analyze([
      ...segment(0, 'walk', 60),
      ...segment(5000, 'walk', 60),
    ]);
    expect(a.longestGap, const Duration(seconds: 30));
  });

  test('a signal holding no steps is not seen as a step', () {
    final a = analyze(segment(0, 'walk', 120, steps: 0));
    expect(a.detected(Source.step), 0);
  });
}

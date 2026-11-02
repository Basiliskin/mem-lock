import 'steps_log.dart';

/// One thing the tester can do. Stopping before [minimum] discards it.
class GuideActivity {
  const GuideActivity(this.type, this.title, this.howTo, this.minimum);

  final String type;
  final String title;
  final String howTo;
  final Duration minimum;
}

/// One line of the checklist.
class GuideGoal {
  const GuideGoal(
    this.title,
    this.done,
    this.needed,
    this.unit,
    this.activities,
  );

  final String title;
  final int done;
  final int needed;
  final String unit;
  final List<GuideActivity> activities;

  bool get complete => done >= needed;
}

const _walk = GuideActivity(
  'walk',
  'Normal walk',
  'Walk as usual, stopping at doors as you normally would.',
  Duration(minutes: 2),
);
const _sit = GuideActivity(
  'sit',
  'Sit still',
  'Sit or stand without walking.',
  Duration(minutes: 5),
);
const _vehicle = GuideActivity(
  'vehicle',
  'Ride in a vehicle',
  'Ride a bus, train or car without walking. A bumpy ride is best.',
  Duration(minutes: 5),
);
const _slow = GuideActivity(
  'slow_walk',
  'Slow walk',
  'Give the phone to an elderly person to carry, ideally a real Wearer. '
      'They walk as they normally do.',
  Duration(minutes: 2),
);
const _walker = GuideActivity(
  'walker_walk',
  'Walk with a walker',
  'Give the phone to an elderly person who uses a walker. '
      'They walk as they normally do.',
  Duration(minutes: 2),
);
const _daily = GuideActivity(
  'daily',
  'Daily life, staying here',
  'Carry the phone and go about your day: pace, go to the counter or the '
      'toilet. Tap Done before you really leave this place.',
  Duration.zero,
);

/// Progress so far, in the order the tester should work through it.
List<GuideGoal> guideGoals(Analysis a) => [
  GuideGoal('Normal walks', a.walks.length, requiredWalks, 'walks', const [
    _walk,
  ]),
  GuideGoal(
    'Sitting or riding',
    a.still.length,
    requiredStill,
    'segments',
    const [_sit, _vehicle],
  ),
  GuideGoal(
    'Elderly walks',
    a.elderlyWalks.length,
    requiredElderlyWalks,
    'walks',
    const [_slow, _walker],
  ),
  GuideGoal(
    'Daily life',
    a.dailyHours.floor(),
    requiredDailyHours,
    'hours',
    const [_daily],
  ),
];

/// What to do next, or null when everything has been gathered.
GuideGoal? nextGoal(List<GuideGoal> goals) {
  for (final g in goals) {
    if (!g.complete) return g;
  }
  return null;
}

/// True after a finished walk with no steps: the full set would be wasted.
bool noStepsSeen(Analysis a) =>
    a.walks.isNotEmpty &&
    a.walks.every((w) => w.steps.every((s) => s.steps <= 0));

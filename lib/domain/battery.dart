/// At or under this, the battery counts as low.
const lowBatteryPercent = 20;

/// Above this, a low-battery period is over. The gap keeps small changes around
/// the limit from counting as a new period.
const batteryRecoveredPercent = 25;

class BatteryReading {
  const BatteryReading(this.percent, {required this.charging});

  final int percent;
  final bool charging;

  bool get isLow => !charging && percent <= lowBatteryPercent;

  bool get periodOver => charging || percent > batteryRecoveredPercent;
}

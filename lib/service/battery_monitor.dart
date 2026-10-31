import '../ports/ports.dart';

/// Warns the Wearer once per low-battery period, even if the service restarts
/// during it.
class BatteryMonitor {
  BatteryMonitor({
    required BatterySource battery,
    required LowBatteryNotice notice,
    required LowBatteryStore store,
  }) : _battery = battery,
       _notice = notice,
       _store = store;

  final BatterySource _battery;
  final LowBatteryNotice _notice;
  final LowBatteryStore _store;

  Future<void> check() async {
    try {
      final reading = await _battery.read();
      if (reading.periodOver) {
        if (await _store.warned()) await _store.setWarned(false);
      } else if (reading.isLow && !await _store.warned()) {
        await _notice.show();
        await _store.setWarned(true);
      }
    } on Object {
      // Tried again at the next check.
    }
  }
}

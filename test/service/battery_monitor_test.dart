import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/domain/battery.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/service/battery_monitor.dart';

class FakeBattery implements BatterySource {
  BatteryReading reading = const BatteryReading(80, charging: false);
  bool fails = false;
  @override
  Future<BatteryReading> read() async {
    if (fails) throw StateError('plugin');
    return reading;
  }
}

class FakeNotice implements LowBatteryNotice {
  int shown = 0;
  bool fails = false;
  @override
  Future<void> show() async {
    if (fails) throw StateError('no');
    shown++;
  }
}

class FakeStore implements LowBatteryStore {
  bool value = false;
  @override
  Future<bool> warned() async => value;
  @override
  Future<void> setWarned(bool warned) async => value = warned;
}

void main() {
  late FakeBattery battery;
  late FakeNotice notice;
  late FakeStore store;
  late BatteryMonitor monitor;

  BatteryMonitor make() =>
      BatteryMonitor(battery: battery, notice: notice, store: store);
  void level(int l, {bool charging = false}) =>
      battery.reading = BatteryReading(l, charging: charging);

  setUp(() {
    battery = FakeBattery();
    notice = FakeNotice();
    store = FakeStore();
    monitor = make();
  });

  test('no warning while the battery is fine', () async {
    await monitor.check();
    expect(notice.shown, 0);
  });

  test('AC-9.2: warns once per low period', () async {
    level(20);
    await monitor.check();
    level(12);
    await monitor.check();
    expect(notice.shown, 1);
  });

  test('a service restart in the same period does not warn again', () async {
    level(15);
    await monitor.check();
    await make().check();
    expect(notice.shown, 1);
  });

  test('wobbling around the limit is the same period', () async {
    level(20);
    await monitor.check();
    level(23);
    await monitor.check();
    level(20);
    await monitor.check();
    expect(notice.shown, 1);
  });

  test('a new period warns again after charging', () async {
    level(15);
    await monitor.check();
    level(15, charging: true);
    await monitor.check();
    level(15);
    await monitor.check();
    expect(notice.shown, 2);
  });

  test('a failed warning is tried again', () async {
    level(15);
    notice.fails = true;
    await monitor.check();
    notice.fails = false;
    await monitor.check();
    expect(notice.shown, 1);
  });

  test('a failed reading changes nothing', () async {
    level(15);
    await monitor.check();
    battery.fails = true;
    await monitor.check();
    battery.fails = false;
    await monitor.check();
    expect(notice.shown, 1);
  });
}

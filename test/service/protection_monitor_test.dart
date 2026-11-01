import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/ports/ports.dart';
import 'package:leavecheck/service/protection_monitor.dart';

class FakeHealth implements HealthCheck {
  ProtectionProblem? problem;
  bool fails = false;
  @override
  Future<ProtectionProblem?> check() async {
    if (fails) throw StateError('plugin');
    return problem;
  }

  @override
  Future<void> fix(ProtectionProblem problem) async {}
}

class FakeNotice implements ProtectionNotice {
  final shown = <bool>[];
  bool fails = false;
  @override
  Future<void> show({required bool protecting}) async {
    if (fails) throw StateError('notification');
    shown.add(protecting);
  }
}

void main() {
  late FakeHealth health;
  late FakeNotice notice;
  late int recoveries;
  late ProtectionMonitor monitor;

  setUp(() {
    health = FakeHealth();
    notice = FakeNotice();
    recoveries = 0;
    monitor = ProtectionMonitor(
      health: health,
      notice: notice,
      onRecovered: () async => recoveries++,
    );
  });

  test('all well from the start changes nothing', () async {
    await monitor.check();
    await monitor.check();
    expect(notice.shown, isEmpty);
    expect(recoveries, 0);
  });

  test('AC-8.2: a problem shows the warning once', () async {
    await monitor.check();
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    await monitor.check();
    expect(notice.shown, [false]);
  });

  test('a problem already there at start is warned of', () async {
    health.problem = ProtectionProblem.notifications;
    await monitor.check();
    expect(notice.shown, [false]);
  });

  test('AC-8.3: fixing clears the warning and restarts location', () async {
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    health.problem = null;
    await monitor.check();
    expect(notice.shown, [false, true]);
    expect(recoveries, 1);
  });

  test('changing from one problem to another warns no further', () async {
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    health.problem = ProtectionProblem.locationPermission;
    await monitor.check();
    expect(notice.shown, [false]);
    expect(recoveries, 0);
  });

  test('a failed check changes nothing and later checks work', () async {
    health.fails = true;
    await monitor.check();
    expect(notice.shown, isEmpty);
    health.fails = false;
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    expect(notice.shown, [false]);
  });

  test('a failed warning is tried again at the next check', () async {
    health.problem = ProtectionProblem.locationOff;
    notice.fails = true;
    await monitor.check();
    notice.fails = false;
    await monitor.check();
    expect(notice.shown, [false]);
  });

  test('recovery still restarts location if the notice fails', () async {
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    health.problem = null;
    notice.fails = true;
    await monitor.check();
    expect(recoveries, 1);
  });

  test('AC-13.3: a language change repeats what the notice says', () async {
    health.problem = ProtectionProblem.locationOff;
    await monitor.check();
    notice.shown.clear();

    await monitor.refreshNotice();

    expect(notice.shown, [false]);
  });
}

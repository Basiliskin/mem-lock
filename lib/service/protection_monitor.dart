import '../ports/ports.dart';

/// Keeps the phone's persistent notification truthful while the service runs,
/// including when the app is closed.
class ProtectionMonitor {
  ProtectionMonitor({
    required HealthCheck health,
    required ProtectionNotice notice,
    required Future<void> Function() onRecovered,
  }) : _health = health,
       _notice = notice,
       _onRecovered = onRecovered;

  final HealthCheck _health;
  final ProtectionNotice _notice;
  final Future<void> Function() _onRecovered;

  /// What the notification last said. It starts out saying "protecting".
  bool _protecting = true;
  bool _hadProblem = false;

  Future<void> check() async {
    final bool ok;
    try {
      ok = await _health.check() == null;
    } on Object {
      return;
    }
    if (ok && _hadProblem) {
      _hadProblem = false;
      // Location may have ended its readings when it was turned off.
      await _quietly(_onRecovered);
    }
    if (!ok) _hadProblem = true;
    if (ok == _protecting) return;
    await _quietly(() async {
      await _notice.show(protecting: ok);
      _protecting = ok;
    });
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Tried again at the next check.
    }
  }
}

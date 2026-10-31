import '../domain/detector.dart';

abstract interface class LocationSource {
  Stream<LocationFix> get fixes;
  Future<void> setMode(LocationMode mode);
}

abstract interface class StateStore {
  Future<String?> read();
  Future<void> write(String value);
}

abstract interface class ReminderPlayer {
  Future<void> start(StartReminder reminder);
  Future<void> stop();
}

abstract interface class BackgroundHost {
  Future<bool> isRunning();

  /// Returns whether watching is now running.
  Future<bool> start();
}

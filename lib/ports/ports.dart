import '../domain/detector.dart';
import '../domain/geo.dart';
import '../domain/last_place_record.dart';
import '../domain/quiet_place_record.dart';
import '../domain/reminder_options.dart';

abstract interface class LocationSource {
  Stream<LocationFix> get fixes;
  Future<void> setMode(LocationMode mode);
}

/// A single reading taken now, for the screens.
abstract interface class CurrentFixSource {
  /// Returns null when no reading could be taken in time.
  Future<LocationFix?> currentFix();
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

/// What the phone does to present a Reminder.
abstract interface class ReminderOutput {
  /// [alert] false leaves the notification on screen quietly.
  Future<void> show({required bool alert});

  /// A null [customPath] plays the default sound.
  Future<void> play(String? customPath, SilentChoice silent);
  Future<void> stopSound();
  Future<void> cancel();
}

abstract interface class ReminderOptionsStore {
  Future<ReminderOptions> read();
}

abstract interface class LastPlaceStore {
  Future<LastPlaceRecord?> read();
  Future<void> save(LastPlaceRecord value);
}

abstract interface class QuietPlaceStore {
  Future<List<QuietPlaceRecord>> read();
  Future<void> write(List<QuietPlaceRecord> places);
}

/// Lets the screens tell the running service something changed.
abstract interface class WatcherLink {
  void quietPlacesChanged();
}

abstract interface class MapLauncher {
  /// Returns false when no map app could open it.
  Future<bool> open(GeoPoint point);
}

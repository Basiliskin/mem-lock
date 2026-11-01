import '../domain/battery.dart';
import '../domain/detector.dart';
import '../domain/geo.dart';
import '../domain/language.dart';
import '../domain/last_place_record.dart';
import '../domain/quiet_place_record.dart';
import '../domain/reminder_options.dart';

abstract interface class LocationSource {
  Stream<LocationFix> get fixes;
  Future<void> setMode(LocationMode mode);
}

/// Whether location readings could not be started. Shared with the screens,
/// which run apart from the service.
abstract interface class LocationStatusStore {
  Future<void> write({required bool failing});
}

abstract interface class ActivitySource {
  Stream<ActivityChanged> get changes;
}

/// Whether this phone can report activity at all.
abstract interface class ActivityAvailability {
  Future<bool> isAvailable();
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
  Future<void> show({required bool alert, required ReminderOptions options});

  /// Plays [voicePath], or [tone] when it is null.
  Future<void> play(String? voicePath, ReminderTone tone, SilentChoice silent);
  Future<void> stopSound();
  Future<void> cancel();
}

abstract interface class ReminderOptionsStore {
  Future<ReminderOptions> read();
  Future<void> write(ReminderOptions value);
}

/// Lets the Helper hear and feel a Reminder without a real one starting.
abstract interface class ReminderTester {
  Future<void> test(ReminderOptions options);
  Future<void> stop();
}

abstract interface class VoiceRecorder {
  /// Returns false when the microphone permission is refused.
  Future<bool> start();

  /// Returns the new recording's path, or null when it didn't work.
  Future<String?> stop();
}

abstract interface class LastPlaceStore {
  /// Newest first.
  Future<List<LastPlaceRecord>> read();

  /// Adds [value] as the newest, deleting any beyond the kept limit.
  Future<void> save(LastPlaceRecord value);
}

abstract interface class QuietPlaceStore {
  Future<List<QuietPlaceRecord>> read();
  Future<void> write(List<QuietPlaceRecord> places);
}

/// Lets the screens tell the running service something changed.
abstract interface class WatcherLink {
  void quietPlacesChanged();
  void detectionSettingsChanged();
  void languageChanged();
}

abstract interface class DetectionSettingsStore {
  Future<DetectionSettings> read();
  Future<void> write(DetectionSettings value);
}

/// The Helper's language choice; null follows the phone.
abstract interface class LanguageStore {
  Future<AppLanguage?> read();
  Future<void> write(AppLanguage? value);
}

abstract interface class BatterySource {
  Future<BatteryReading> read();
}

abstract interface class LowBatteryNotice {
  Future<void> show();
}

/// Whether the Wearer was already warned in this low-battery period.
abstract interface class LowBatteryStore {
  Future<bool> warned();
  Future<void> setWarned(bool warned);
}

enum SetupPermission { location, notifications, activity, battery }

enum PermissionState { granted, denied, permanentlyDenied }

abstract interface class PermissionGate {
  Future<PermissionState> check(SetupPermission permission);
  Future<PermissionState> request(SetupPermission permission);
  Future<void> openSettings();
}

abstract interface class SetupStore {
  Future<bool> isDone();
  Future<void> markDone();
}

/// Something stopping the app from protecting the Wearer.
enum ProtectionProblem {
  locationOff,
  locationNotStarting,
  locationPermission,
  notifications,
  activityPermission,
}

abstract interface class HealthCheck {
  /// Returns null when all is well.
  Future<ProtectionProblem?> check();

  /// Takes the Helper to the place where it can be fixed.
  Future<void> fix(ProtectionProblem problem);
}

/// The phone's persistent notification.
abstract interface class ProtectionNotice {
  Future<void> show({required bool protecting});
}

abstract interface class MapLauncher {
  /// Returns false when no map app could open it.
  Future<bool> open(GeoPoint point);
}

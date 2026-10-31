import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:google_api_availability/google_api_availability.dart';

import '../domain/detector.dart';
import '../ports/ports.dart';

ActivityChanged toActivityChanged(ActivityEvent event) =>
    ActivityChanged(event.timeStamp, switch (event.type) {
      ActivityType.IN_VEHICLE => ActivityKind.inVehicle,
      ActivityType.WALKING ||
      ActivityType.ON_FOOT ||
      ActivityType.RUNNING => ActivityKind.walking,
      ActivityType.STILL => ActivityKind.still,
      ActivityType.ON_BICYCLE ||
      ActivityType.TILTING ||
      ActivityType.UNKNOWN => ActivityKind.unknown,
    }, event.confidence);

class PluginActivity implements ActivitySource {
  /// The watching service keeps this running, so the plugin needs no service.
  @override
  Stream<ActivityChanged> get changes => ActivityRecognition()
      .activityStream(runForegroundService: false)
      .map(toActivityChanged);
}

class PlayServicesCheck implements ActivityAvailability {
  @override
  Future<bool> isAvailable() async =>
      await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability() ==
      GooglePlayServicesAvailability.success;
}

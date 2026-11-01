import 'dart:convert';

/// The values the Helper can change, always within the limits below when read
/// from storage. The Ride time limit is deliberately not one of them.
class DetectionSettings {
  const DetectionSettings({
    required this.stayTime,
    required this.stayMeters,
    this.vehicleKmh = recommendedVehicleKmh,
    this.walkingAfterRide = recommendedWalkingAfterRide,
  });

  /// Ride values are placeholders, set without real rides. Retune them from
  /// the S1 logs before trusting them. 14.4 km/h is 4 m/s.
  static const recommendedVehicleKmh = 14.4;

  /// Leaves room to stay within FT-2's 60 seconds.
  static const recommendedWalkingAfterRide = Duration(seconds: 30);

  static const normal = DetectionSettings(
    stayTime: Duration(minutes: 5),
    stayMeters: 75,
  );

  static const minStayTime = Duration(minutes: 1);
  static const maxStayTime = Duration(minutes: 30);
  static const minStayMeters = 30.0;
  static const maxStayMeters = 300.0;
  static const minVehicleKmh = 7.0;
  static const maxVehicleKmh = 30.0;
  static const minWalkingAfterRide = Duration(seconds: 10);
  static const maxWalkingAfterRide = Duration(seconds: 120);

  final Duration stayTime;
  final double stayMeters;

  /// Faster than this between readings means still in the vehicle, whatever
  /// the activity signal says.
  final double vehicleKmh;

  /// How long walking must last to confirm the Wearer got off.
  final Duration walkingAfterRide;

  double get vehicleMetersPerSecond => vehicleKmh / 3.6;

  /// Coming back needs a reading well inside the area, so that jitter near the
  /// edge while walking away doesn't count as a return.
  double get returnMeters => stayMeters / 2;

  bool get withinLimits =>
      stayTime >= minStayTime &&
      stayTime <= maxStayTime &&
      stayMeters >= minStayMeters &&
      stayMeters <= maxStayMeters &&
      vehicleKmh >= minVehicleKmh &&
      vehicleKmh <= maxVehicleKmh &&
      walkingAfterRide >= minWalkingAfterRide &&
      walkingAfterRide <= maxWalkingAfterRide;

  /// The choice whose Stay values these are, or null for advanced Stay values.
  StayChoice? get choice {
    for (final c in StayChoice.values) {
      if (c.settings.stayTime == stayTime &&
          c.settings.stayMeters == stayMeters) {
        return c;
      }
    }
    return null;
  }

  /// A choice replaces only the Stay values (AC-12.5).
  DetectionSettings withChoice(StayChoice choice) => DetectionSettings(
    stayTime: choice.settings.stayTime,
    stayMeters: choice.settings.stayMeters,
    vehicleKmh: vehicleKmh,
    walkingAfterRide: walkingAfterRide,
  );

  Map<String, dynamic> toMap() => {
    'staySeconds': stayTime.inSeconds,
    'stayMeters': stayMeters,
    'vehicleKmh': vehicleKmh,
    'walkingSeconds': walkingAfterRide.inSeconds,
  };

  /// Ride values may be missing from what older versions saved. Values out of
  /// limits give [normal]. Throws [TypeError] when the Stay values are missing
  /// or of the wrong type.
  factory DetectionSettings.fromMap(Map<String, dynamic> m) {
    final walking = m['walkingSeconds'] as int?;
    final read = DetectionSettings(
      stayTime: Duration(seconds: m['staySeconds'] as int),
      stayMeters: (m['stayMeters'] as num).toDouble(),
      vehicleKmh:
          (m['vehicleKmh'] as num?)?.toDouble() ?? recommendedVehicleKmh,
      walkingAfterRide: walking == null
          ? recommendedWalkingAfterRide
          : Duration(seconds: walking),
    );
    return read.withinLimits ? read : normal;
  }
}

String encodeDetectionSettings(DetectionSettings s) => jsonEncode(s.toMap());

/// Unreadable text gives Normal.
DetectionSettings parseDetectionSettings(String text) {
  try {
    return DetectionSettings.fromMap(jsonDecode(text) as Map<String, dynamic>);
  } on FormatException {
    return DetectionSettings.normal;
  } on TypeError {
    return DetectionSettings.normal;
  }
}

/// The Helper's simple choice of how often Reminders happen. Values are to be
/// tuned from the field tests.
enum StayChoice {
  moreOften(DetectionSettings(stayTime: Duration(minutes: 3), stayMeters: 75)),
  normal(DetectionSettings.normal),
  lessOften(
    DetectionSettings(stayTime: Duration(minutes: 10), stayMeters: 100),
  );

  const StayChoice(this.settings);

  final DetectionSettings settings;
}

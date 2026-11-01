import '../domain/detector.dart';
import '../ports/ports.dart';

/// Places are marked only from a fresh, trustworthy reading, because the Helper
/// is standing there now and a wrong place would give the wrong Reminders.
Future<LocationFix?> usableFix(CurrentFixSource location) async {
  try {
    final fix = await location.currentFix();
    return fix != null && fix.accuracyMeters <= maxAccuracyMeters ? fix : null;
  } on Object {
    return null;
  }
}

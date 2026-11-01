import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/adapters/prefs_detection_settings.dart';
import 'package:geo_alert/domain/detector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync prefs;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  test('AC-10.2: nothing saved gives Normal', () async {
    final s = await PrefsDetectionSettings().read();
    expect(s.choice, StayChoice.normal);
  });

  for (final c in StayChoice.values) {
    test('an old ${c.name} choice is read as its preset', () async {
      await prefs.setString('stay_choice', c.name);
      final s = await PrefsDetectionSettings().read();
      expect(s.choice, c);
      expect(s.vehicleKmh, DetectionSettings.normal.vehicleKmh);
    });
  }

  test('an unknown old choice gives Normal', () async {
    await prefs.setString('stay_choice', 'sometimes');
    final s = await PrefsDetectionSettings().read();
    expect(s.choice, StayChoice.normal);
  });

  test('saved settings win over the old choice', () async {
    await prefs.setString('stay_choice', StayChoice.lessOften.name);
    final store = PrefsDetectionSettings();
    await store.write(
      const DetectionSettings(
        stayTime: Duration(minutes: 20),
        stayMeters: 200,
        vehicleKmh: 10,
        walkingAfterRide: Duration(seconds: 45),
      ),
    );
    final s = await store.read();
    expect(s.stayTime, const Duration(minutes: 20));
    expect(s.stayMeters, 200);
    expect(s.vehicleKmh, 10);
    expect(s.walkingAfterRide, const Duration(seconds: 45));
  });

  test('unreadable settings give Normal, not the old choice', () async {
    await prefs.setString('stay_choice', StayChoice.lessOften.name);
    await prefs.setString('detection_settings', 'not json');
    final s = await PrefsDetectionSettings().read();
    expect(s.choice, StayChoice.normal);
  });
}

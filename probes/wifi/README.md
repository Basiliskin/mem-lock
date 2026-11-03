# Wi-Fi Probe

A throwaway app that tests whether Wi-Fi alone can tell where someone is inside a building: mark points such as the front door, then see whether the phone recognises them again. Nothing in `lib/` of the main app may import it.

It uses the networks the phone can see nearby, including neighbours', and needs no connection to any of them. Wi-Fi must be on, or **Wi-Fi scanning** must be allowed in the location settings.

Each point is a fingerprint of the 5 strongest access points heard there, averaged over 3 scans. Its radar chart shows the recorded signals against what the phone hears now. Further out means a stronger signal, and the two shapes match when you're back at the point.

## Privacy

Logs hold hidden access-point ids, never network names or addresses. Each id is a salted hash, so it can't be looked up in public Wi-Fi maps to find the building, but the same access point gets the same id in every log from this phone. Names appear on screen only. Point names you type are logged, so avoid addresses.

## Run a session

1. Install on a real phone with `flutter run --release`, then grant the location and nearby-devices permissions.
2. Optional, but it gives about 4 times as many scans: turn off **Wi-Fi scan throttling** in Developer options.
3. Keep the app open: it keeps the screen on, and Android doesn't scan for apps in the background often enough.
4. **Add points:** stand at a spot, tap **Add point here**, name it, and stand still until it vibrates twice. Add one point in each room and one at the exit, just inside the front door.
5. **Test them:** walk around, and each time you reach a point, tap **I'm here now** on its card and stand still until it vibrates twice, which is the next scan. Moving on sooner gives no result for that tap. Do each point at least 5 times on different walks, and walk out of the flat a few times, tapping the exit point as you pass it. A short vibration means the app thinks you're near a point.
6. Tap the share button to send the report and a zip of the logs.

## Read the results

```bash
unzip wifi-probe-logs.zip -d data
dart run tool/report.dart data/*.jsonl
```

The report shows how alike the points are to each other, and for each **I'm here now** tap, which point the nearest scan looked like. Points less than about 10 dB apart can't be told apart reliably. No pass rule is set yet; decide it from the first results.

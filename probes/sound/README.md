# Sound Probe (S2)

A throwaway app that checks whether a recorded voice and a tone play on a locked phone using the alarm sound channel. It feeds the early FT-5 check and the silent mode decision, and nothing in `lib/` of the main app may import it.

## Run a trial

1. Install with `flutter run --release`, tap **Set up** and grant the permissions. The location permission keeps the app running the same way the real app will.
2. Enter the phone model and tap **Record voice** to record a short message.
3. Set the phone to normal, silent or Do Not Disturb yourself, and choose the same condition and sound in the app.
4. Tap **Arm**, lock the phone within 30 seconds, and wait with the phone in a pocket.
5. After it plays, unlock and tick what you heard and felt, then tap **Save result**.

## What to cover

On at least two phone brands:

| Condition | Voice | Tone |
|---|---|---|
| Normal | 5 tries, needed for the verdict | 1 try |
| Silent | 2 tries | 2 tries |
| Do Not Disturb | 2 tries | 2 tries |

Also note whether the phone's alarm volume was turned up. The sound follows the alarm volume, not the ringer volume, so a low alarm setting could be mistaken for a failure. Do Not Disturb results may vary with the phone's "allow alarms" setting, so note that too.

## Read the results

```bash
adb pull /sdcard/Android/data/com.geoalert.probe.sound_probe/files/ logs/
dart run tool/report.dart logs/files/*.jsonl
```

To combine phones, pass each phone's log to the same command.

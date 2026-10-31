import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'sound_results.dart';

const _delay = Duration(seconds: 30);

void main() => runApp(const MaterialApp(home: ProbePage()));

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  final _phone = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _notes = FlutterLocalNotificationsPlugin();

  Condition _condition = Condition.normal;
  SoundKind _kind = SoundKind.voice;
  String _status = 'Grant permissions to begin';
  bool _ready = false;
  bool _recording = false;
  bool _hasVoice = false;
  bool _awaitingResult = false;
  bool _armed = false;
  bool _heard = false;
  bool _felt = false;
  String? _voicePath;
  String? _tonePath;
  String? _logPath;
  int _trials = 0;
  StreamSubscription<Position>? _keepAlive;

  /// Same service type the real app will use, so playback happens under the
  /// same conditions as a real Reminder.
  void _startService() {
    _keepAlive = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.low,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sound probe',
          notificationText: 'Waiting to play a test sound',
          enableWakeLock: true,
        ),
      ),
    ).listen((_) {}, onError: (_) {});
  }

  Future<void> _setup() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.microphone,
      Permission.notification,
    ].request();
    if (results.values.any((s) => !s.isGranted)) {
      setState(() => _status = 'A permission is missing');
      return;
    }

    final docs = await getApplicationDocumentsDirectory();
    final ext = await getExternalStorageDirectory();
    final tone = File('${docs.path}/tone.wav');
    await tone.writeAsBytes(sineWav());
    _tonePath = tone.path;
    _voicePath = '${docs.path}/voice.m4a';
    _hasVoice = File(_voicePath!).existsSync();
    _logPath = '${ext!.path}/sound-trials.jsonl';

    await _notes.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransient,
          stayAwake: true,
        ),
      ),
    );
    _startService();
    setState(() {
      _ready = true;
      _status = 'Ready';
    });
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _recorder.stop();
      setState(() {
        _recording = false;
        _hasVoice = true;
        _status = 'Voice recorded';
      });
    } else {
      await _recorder.start(const RecordConfig(), path: _voicePath!);
      setState(() {
        _recording = true;
        _status = 'Recording. Speak, then tap to stop';
      });
    }
  }

  void _arm() {
    setState(() {
      _armed = true;
      _status = 'Lock the phone now. Plays in ${_delay.inSeconds} s';
    });
    Timer(_delay, _play);
  }

  Future<void> _play() async {
    await _notes.show(
      id: 1,
      title: 'Sound probe',
      body: 'Do you have your bag?',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'probe_reminder',
          'Test reminders',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
    var error = '';
    try {
      final path = _kind == SoundKind.voice ? _voicePath! : _tonePath!;
      await _player.play(DeviceFileSource(path));
    } on Object catch (e) {
      error = ' Playback error: $e';
    }
    if (!mounted) return;
    setState(() {
      _armed = false;
      _awaitingResult = true;
      _heard = false;
      _felt = false;
      _status = 'Played. Record what happened.$error';
    });
  }

  Future<void> _saveResult() async {
    final phone = _phone.text.trim();
    final trial = Trial(phone, _condition, _kind, heard: _heard, felt: _felt);
    await File(
      _logPath!,
    ).writeAsString('${trial.toLine()}\n', mode: FileMode.append, flush: true);
    setState(() {
      _trials++;
      _awaitingResult = false;
      _status = 'Saved. $_trials saved this session';
    });
  }

  @override
  void dispose() {
    _keepAlive?.cancel();
    _recorder.dispose();
    _player.dispose();
    _phone.dispose();
    super.dispose();
  }

  Widget _big(String label, VoidCallback? onTap) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    ),
  );

  String? get _blocker {
    if (_phone.text.trim().isEmpty) return 'Enter the phone model first';
    if (_kind == SoundKind.voice && !_hasVoice) return 'Record a voice first';
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sound probe')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_status, style: const TextStyle(fontSize: 18)),
        if (_logPath != null) SelectableText(_logPath!),
        if (!_ready) _big('Set up', _setup),
        if (_ready && _awaitingResult) ...[
          CheckboxListTile(
            title: const Text('I heard it'),
            value: _heard,
            onChanged: (v) => setState(() => _heard = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('I felt vibration'),
            value: _felt,
            onChanged: (v) => setState(() => _felt = v ?? false),
          ),
          _big('Save result', _saveResult),
        ],
        if (_ready && !_awaitingResult && !_armed) ...[
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone model'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _big(_recording ? 'Stop recording' : 'Record voice', _toggleRecord),
          const SizedBox(height: 12),
          const Text('Set this on the phone yourself, then choose it:'),
          SegmentedButton<Condition>(
            segments: const [
              ButtonSegment(value: Condition.normal, label: Text('Normal')),
              ButtonSegment(value: Condition.silent, label: Text('Silent')),
              ButtonSegment(value: Condition.dnd, label: Text('DND')),
            ],
            selected: {_condition},
            onSelectionChanged: (s) => setState(() => _condition = s.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<SoundKind>(
            segments: const [
              ButtonSegment(value: SoundKind.voice, label: Text('Voice')),
              ButtonSegment(value: SoundKind.tone, label: Text('Tone')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          if (_blocker != null) Text(_blocker!),
          _big(
            'Arm: play in ${_delay.inSeconds} s',
            _blocker == null ? _arm : null,
          ),
        ],
      ],
    ),
  );
}

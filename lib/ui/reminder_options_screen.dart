import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/reminder_options.dart';
import '../l10n/strings.dart';
import '../ports/ports.dart';

/// Kept shorter than the gap between tries, so a voice never overlaps itself.
const maxRecording = Duration(seconds: 20);

class ReminderOptionsScreen extends StatefulWidget {
  const ReminderOptionsScreen({
    super.key,
    required this.store,
    required this.tester,
    required this.recorder,
  });

  final ReminderOptionsStore store;
  final ReminderTester tester;
  final VoiceRecorder recorder;

  @override
  State<ReminderOptionsScreen> createState() => _ReminderOptionsScreenState();
}

class _ReminderOptionsScreenState extends State<ReminderOptionsScreen> {
  ReminderOptions? _options;
  Future<void> _saving = Future.value();
  Timer? _recordLimit;
  bool _recording = false;
  bool _testing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recordLimit?.cancel();
    if (_recording) unawaited(_quietly(widget.recorder.stop));
    unawaited(_quietly(widget.tester.stop));
    super.dispose();
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // The screen is closing, or the sound had already ended.
    }
  }

  Future<void> _load() async {
    ReminderOptions options;
    try {
      options = await widget.store.read();
    } on Object {
      options = const ReminderOptions();
    }
    if (mounted) setState(() => _options = options);
  }

  /// Saves in order, so that quick changes can't overwrite each other.
  void _update(ReminderOptions options) {
    setState(() {
      _options = options;
      _message = null;
    });
    _saving = _saving.then((_) async {
      try {
        await widget.store.write(options);
      } on Object {
        _say(Strings.saveFailed);
      }
    });
  }

  void _say(String? message) {
    if (mounted) setState(() => _message = message);
  }

  Future<void> _startRecording() async {
    await _stopTest();
    try {
      if (!await widget.recorder.start()) {
        _say(Strings.micRefused);
        return;
      }
    } on Object {
      _say(Strings.recordFailed);
      return;
    }
    if (!mounted) return;
    _recordLimit = Timer(maxRecording, _stopRecording);
    setState(() {
      _recording = true;
      _message = null;
    });
  }

  Future<void> _stopRecording() async {
    _recordLimit?.cancel();
    setState(() => _recording = false);
    String? path;
    try {
      path = await widget.recorder.stop();
    } on Object {
      path = null;
    }
    if (!mounted) return;
    if (path == null) {
      _say(Strings.recordFailed);
    } else {
      _update(_options!.copyWith(voicePath: () => path));
    }
  }

  Future<void> _startTest() async {
    await _saving;
    if (mounted) setState(() => _testing = true);
    try {
      await widget.tester.test(_options!);
    } on Object {
      _say(Strings.testFailed);
    }
  }

  Future<void> _stopTest() async {
    if (!_testing) return;
    setState(() => _testing = false);
    await _quietly(widget.tester.stop);
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _choice(String text, bool chosen, VoidCallback onTap) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: chosen,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      leading: Icon(
        chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(text, style: const TextStyle(fontSize: 20)),
      onTap: onTap,
    ),
  );

  Widget _textField(String label, String? value, int limit, bool isTitle) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
          initialValue: value,
          maxLength: limit,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (text) => _update(
            isTitle
                ? _options!.copyWith(title: () => text)
                : _options!.copyWith(body: () => text),
          ),
        ),
      );

  Widget _note(String text) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF3C4),
      child: Text(text, style: const TextStyle(fontSize: 20)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final o = _options;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.reminderOptions)),
      body: o == null ? const SizedBox.shrink() : _body(o),
    );
  }

  Widget _body(ReminderOptions o) {
    final message = _message;
    final tones = {
      ReminderTone.rising: Strings.toneRising,
      ReminderTone.bell: Strings.toneBell,
      ReminderTone.pulse: Strings.tonePulse,
    };
    final vibrations = {
      VibrationChoice.off: Strings.vibrationOff,
      VibrationChoice.normal: Strings.vibrationNormal,
      VibrationChoice.strong: Strings.vibrationStrong,
    };
    final silents = {
      SilentChoice.aloud: Strings.silentAloud,
      SilentChoice.vibrate: Strings.silentVibrate,
    };
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: FilledButton(
              onPressed: _testing ? _stopTest : _startTest,
              child: Text(
                _testing ? Strings.stopTest : Strings.testReminder,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          if (message != null) _note(message),
          _heading(Strings.soundHeading),
          for (final e in tones.entries)
            _choice(
              e.value,
              o.voicePath == null && o.tone == e.key,
              () => _update(o.copyWith(tone: e.key, voicePath: () => null)),
            ),
          if (o.voicePath != null) _note(Strings.voiceInUse),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: OutlinedButton(
              onPressed: _recording ? _stopRecording : _startRecording,
              child: Text(
                _recording ? Strings.stopRecording : Strings.recordVoice,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          _heading(Strings.vibrationHeading),
          for (final e in vibrations.entries)
            _choice(
              e.value,
              o.vibration == e.key,
              () => _update(o.copyWith(vibration: e.key)),
            ),
          _heading(Strings.silentHeading),
          for (final e in silents.entries)
            _choice(
              e.value,
              o.silent == e.key,
              () => _update(o.copyWith(silent: e.key)),
            ),
          if (o.silent == SilentChoice.vibrate &&
              o.vibration == VibrationChoice.off)
            _note(Strings.nothingOnSilent),
          _heading(Strings.textHeading),
          _textField(Strings.reminderTitleLabel, o.title, 40, true),
          _textField(Strings.reminderBodyLabel, o.body, 120, false),
        ],
      ),
    );
  }
}

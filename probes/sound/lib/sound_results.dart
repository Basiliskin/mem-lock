import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// The phone's sound state during a trial, set by the tester.
enum Condition { normal, silent, dnd }

enum SoundKind { voice, tone }

enum Verdict { pass, fail, notEnoughData }

const requiredPhones = 2;
const requiredTries = 5;

/// One locked-phone playback, with what the tester noticed.
class Trial {
  Trial(
    this.phone,
    this.condition,
    this.kind, {
    required this.heard,
    required this.felt,
  });

  factory Trial.parse(String line) {
    final m = jsonDecode(line) as Map<String, dynamic>;
    return Trial(
      m['phone'] as String,
      Condition.values.byName(m['condition'] as String),
      SoundKind.values.byName(m['kind'] as String),
      heard: m['heard'] as bool,
      felt: m['felt'] as bool,
    );
  }

  final String phone;
  final Condition condition;
  final SoundKind kind;
  final bool heard;
  final bool felt;

  String toLine() => jsonEncode({
    'phone': phone,
    'condition': condition.name,
    'kind': kind.name,
    'heard': heard,
    'felt': felt,
  });
}

List<Trial> parseTrials(String text) {
  final trials = <Trial>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    try {
      trials.add(Trial.parse(line));
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    } on ArgumentError {
      continue;
    }
  }
  return trials;
}

/// Recorded voice with normal sound, per FT-5: every try on every phone must
/// play. One miss fails it, because the requirement allows none.
Verdict voiceVerdict(List<Trial> trials) {
  final voice = trials.where(
    (t) => t.kind == SoundKind.voice && t.condition == Condition.normal,
  );
  if (voice.any((t) => !t.heard)) return Verdict.fail;
  final counts = <String, int>{};
  for (final t in voice) {
    counts[t.phone] = (counts[t.phone] ?? 0) + 1;
  }
  final ready = counts.values.where((n) => n >= requiredTries).length;
  return ready >= requiredPhones && ready == counts.length
      ? Verdict.pass
      : Verdict.notEnoughData;
}

String report(List<Trial> trials) {
  final b = StringBuffer();
  final groups = <String, List<Trial>>{};
  for (final t in trials) {
    final key = '${t.phone} | ${t.condition.name} | ${t.kind.name}';
    (groups[key] ??= []).add(t);
  }
  for (final e in groups.entries) {
    final n = e.value.length;
    final heard = e.value.where((t) => t.heard).length;
    final felt = e.value.where((t) => t.felt).length;
    b.writeln('${e.key} | heard $heard of $n | felt $felt of $n');
  }
  b.writeln('Early FT-5: ${voiceVerdict(trials).name}');
  return b.toString();
}

/// A plain 16-bit mono tone, so the probe needs no bundled audio file.
Uint8List sineWav({
  double seconds = 4,
  int sampleRate = 22050,
  double hz = 880,
}) {
  final samples = (seconds * sampleRate).round();
  final bytes = ByteData(44 + samples * 2);
  void tag(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + samples * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final v = sin(2 * pi * hz * i / sampleRate) * 24000;
    bytes.setInt16(44 + i * 2, v.round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

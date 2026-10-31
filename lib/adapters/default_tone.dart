import 'dart:math';
import 'dart:typed_data';

/// The default Reminder sound as a WAV: two rising beeps, generated here so
/// that it can't go missing like a file could.
Uint8List defaultToneWav({int sampleRate = 22050}) {
  const beeps = [(880.0, 0.4), (0.0, 0.1), (1175.0, 0.4), (0.0, 0.6)];
  const rounds = 3;
  final samples = <int>[];
  for (var r = 0; r < rounds; r++) {
    for (final (hz, seconds) in beeps) {
      final n = (seconds * sampleRate).round();
      for (var i = 0; i < n; i++) {
        samples.add((sin(2 * pi * hz * i / sampleRate) * 26000).round());
      }
    }
  }
  final bytes = ByteData(44 + samples.length * 2);
  void tag(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + samples.length * 2, Endian.little);
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
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (final (i, v) in samples.indexed) {
    bytes.setInt16(44 + i * 2, v, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

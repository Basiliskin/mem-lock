import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../ports/ports.dart';

/// Each recording gets a new file, so a failed one can't damage the voice in
/// use. Older files are removed once a new one has succeeded.
class PhoneVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();
  String? _path;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getApplicationSupportDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _path = path;
    return true;
  }

  @override
  Future<String?> stop() async {
    await _recorder.stop();
    final path = _path;
    _path = null;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) return null;
    await for (final other in file.parent.list()) {
      final isVoice = other.path.split('/').last.startsWith('voice_');
      if (isVoice && other.path != path) await other.delete();
    }
    return path;
  }
}

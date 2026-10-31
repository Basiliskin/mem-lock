import 'dart:io';

import 'package:ride_probe/ride_log.dart';

/// Usage: `dart run tool/report.dart <log file>...`
void main(List<String> files) {
  if (files.isEmpty) {
    stderr.writeln('Usage: dart run tool/report.dart <log file>...');
    exit(64);
  }
  final text = files.map((f) => File(f).readAsStringSync()).join('\n');
  stdout.write(analyze(parseLog(text)).report());
}

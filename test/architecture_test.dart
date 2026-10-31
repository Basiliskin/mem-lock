import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> importsOf(String source) =>
    _import.allMatches(source).map((m) => m.group(1)!).toList();

/// Domain code may use Dart itself and other domain files, nothing else.
bool allowedInDomain(String uri) {
  if (uri.startsWith('dart:')) return uri != 'dart:io' && uri != 'dart:ui';
  if (uri.startsWith('package:')) {
    return uri.startsWith('package:geo_alert/domain/');
  }
  return !uri.split('/').contains('..');
}

Iterable<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  group('allowedInDomain', () {
    test('accepts pure Dart and domain files', () {
      expect(allowedInDomain('dart:math'), isTrue);
      expect(allowedInDomain('stay.dart'), isTrue);
      expect(allowedInDomain('package:geo_alert/domain/stay.dart'), isTrue);
    });

    test('rejects plugins, Flutter, platform access and other layers', () {
      expect(allowedInDomain('package:flutter/material.dart'), isFalse);
      expect(allowedInDomain('package:geolocator/geolocator.dart'), isFalse);
      expect(allowedInDomain('package:geo_alert/adapters/x.dart'), isFalse);
      expect(allowedInDomain('../adapters/x.dart'), isFalse);
      expect(allowedInDomain('dart:io'), isFalse);
    });
  });

  test('importsOf finds imports and exports', () {
    expect(
      importsOf(
        "import 'dart:math';\nexport \"a.dart\";\n// import 'no.dart';",
      ),
      ['dart:math', 'a.dart'],
    );
  });

  test('lib/domain imports only pure Dart and domain files', () {
    final bad = [
      for (final f in dartFiles('lib/domain'))
        for (final uri in importsOf(f.readAsStringSync()))
          if (!allowedInDomain(uri)) '${f.path}: $uri',
    ];
    expect(bad, isEmpty);
  });

  test('lib never imports the throwaway probes', () {
    final bad = [
      for (final f in dartFiles('lib'))
        for (final uri in importsOf(f.readAsStringSync()))
          if (uri.contains('probes/')) '${f.path}: $uri',
    ];
    expect(bad, isEmpty);
  });
}

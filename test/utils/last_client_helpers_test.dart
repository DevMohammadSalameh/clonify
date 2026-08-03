import 'dart:convert';
import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_last_client_');
    Directory.current = tempDir;
    Directory('./clonify').createSync(recursive: true);
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('last client helpers', () {
    test('save and get last client id', () async {
      await saveLastClientId('client_a');
      expect(await getLastClientId(), 'client_a');
    });

    test('getLastClientId returns null when missing', () async {
      expect(await getLastClientId(), isNull);
    });

    test('getLastConfig returns null when missing', () async {
      expect(await getLastConfig(), isNull);
    });

    test('getLastConfig reads valid json', () async {
      File('./clonify/last_config.json').writeAsStringSync(
        jsonEncode({'clientId': 'client_b', 'version': '1.0.0+1'}),
      );
      final config = await getLastConfig();
      expect(config?['clientId'], 'client_b');
      expect(config?['version'], '1.0.0+1');
    });

    test('getLastConfig throws on invalid json', () async {
      File('./clonify/last_config.json').writeAsStringSync('{bad json');
      expect(getLastConfig(), throwsA(isA<FormatException>()));
    });
  });
}

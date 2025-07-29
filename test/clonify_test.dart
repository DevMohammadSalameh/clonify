import 'dart:io';

import 'package:test/test.dart';
import 'package:clonify/src/clonify_core.dart';

void main() {
  group('validatedClonifySettings', () {
    final settingsPath = './clonify/clonify_settings.yaml';
    final clonifyDir = Directory('./clonify');

    setUp(() {
      if (!clonifyDir.existsSync()) clonifyDir.createSync();
    });

    tearDown(() {
      final file = File(settingsPath);
      if (file.existsSync()) file.deleteSync();
      if (clonifyDir.existsSync()) clonifyDir.deleteSync(recursive: true);
    });

    test('returns false if file does not exist', () {
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns false if file is empty', () {
      File(settingsPath).writeAsStringSync('');
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns false if YAML is invalid', () {
      File(settingsPath).writeAsStringSync('not: yaml: [');
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns false if required fields are missing', () {
      File(settingsPath).writeAsStringSync('company_name: "Test"\n');
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns false if field types are wrong', () {
      File(settingsPath).writeAsStringSync('''
firebase: "not a map"
fastlane: "not a map"
company_name: 123
default_color: 456
''');
      expect(validatedClonifySettings(), isFalse);
    });

    test(
      'returns false if firebase/fastlane subfields are missing or wrong type',
      () {
        File(settingsPath).writeAsStringSync('''
firebase:
  enabled: "yes"
  settings_file: 123
fastlane:
  enabled: null
  settings_file: false
company_name: "Test"
default_color: "#FFFFFF"
''');
        expect(validatedClonifySettings(), isFalse);
      },
    );

    test('returns false if company_name is empty', () {
      File(settingsPath).writeAsStringSync('''
firebase:
  enabled: false
  settings_file: ""
fastlane:
  enabled: false
  settings_file: ""
company_name: ""
default_color: "#FFFFFF"
''');
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns false if default_color is not valid hex', () {
      File(settingsPath).writeAsStringSync('''
firebase:
  enabled: false
  settings_file: ""
fastlane:
  enabled: false
  settings_file: ""
company_name: "Test"
default_color: "red"
''');
      expect(validatedClonifySettings(), isFalse);
    });

    test('returns true for valid settings', () {
      File(settingsPath).writeAsStringSync('''
firebase:
  enabled: true
  settings_file: "firebase.json"
fastlane:
  enabled: false
  settings_file: "fastlane.json"
company_name: "TestCompany"
default_color: "#ABCDEF"
''');
      expect(validatedClonifySettings(), isTrue);
    });
  });

  group('initClonify', () {
    final clonifyDir = Directory('./clonify');
    final settingsFile = File('./clonify/clonify_settings.yaml');

    tearDown(() {
      if (settingsFile.existsSync()) settingsFile.deleteSync();
      if (clonifyDir.existsSync()) clonifyDir.deleteSync(recursive: true);
    });

    test('creates clonify directory and settings file if not exist', () async {
      await initClonify();
      expect(clonifyDir.existsSync(), isTrue);
      expect(settingsFile.existsSync(), isTrue);
      final content = settingsFile.readAsStringSync();
      expect(content, contains('firebase:'));
      expect(content, contains('fastlane:'));
      expect(content, contains('company_name:'));
      expect(content, contains('default_color:'));
    });

    test('does not overwrite existing settings file', () async {
      clonifyDir.createSync();
      settingsFile.writeAsStringSync('company_name: "Existing"\n');
      await initClonify();
      expect(settingsFile.readAsStringSync(), contains('Existing'));
    });
  });
}

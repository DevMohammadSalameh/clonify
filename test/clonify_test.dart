import 'dart:io';

import 'package:args/args.dart';
import 'package:clonify/enums.dart';
import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/utils/tui_helpers.dart';
import 'package:test/test.dart';

import 'silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_root_test_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

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

  group('BuildCommandModel', () {
    ArgParser buildParser() {
      final parser = ArgParser();
      parser.addOption(ClonifyCommandOptions.clientId.name);
      parser.addFlag(ClonifyCommandFlags.skipAll.name, defaultsTo: false);
      parser.addFlag(ClonifyCommandFlags.buildAab.name, defaultsTo: true);
      parser.addFlag(ClonifyCommandFlags.buildApk.name, defaultsTo: false);
      parser.addFlag(ClonifyCommandFlags.buildIpa.name, defaultsTo: true);
      parser.addFlag(
        ClonifyCommandFlags.skipBuildCheck.name,
        defaultsTo: false,
      );
      return parser;
    }

    test('parses clientId and default flags', () {
      final results = buildParser().parse(['--clientId', 'testClientId']);
      final model = BuildCommandModel.fromArgs(results);

      expect(model.clientId, 'testClientId');
      expect(model.buildAab, isTrue);
      expect(model.buildApk, isFalse);
      expect(model.buildIpa, isTrue);
      expect(model.skipBuildCheck, isFalse);
      expect(model.skipAll, isFalse);
    });

    test('parses overridden flags', () {
      final results = buildParser().parse([
        '--clientId',
        'testClientId',
        '--buildApk',
        '--no-buildAab',
        '--no-buildIpa',
        '--skipBuildCheck',
        '--skipAll',
      ]);
      final model = BuildCommandModel.fromArgs(results);

      expect(model.clientId, 'testClientId');
      expect(model.buildAab, isFalse);
      expect(model.buildApk, isTrue);
      expect(model.buildIpa, isFalse);
      expect(model.skipBuildCheck, isTrue);
      expect(model.skipAll, isTrue);
    });

    test('buildAab defaults to true when not specified', () {
      final model = BuildCommandModel.fromArgs(
        buildParser().parse(['--clientId', 'x']),
      );
      expect(model.buildAab, isTrue);
    });

    test('buildApk defaults to false when not specified', () {
      final model = BuildCommandModel.fromArgs(
        buildParser().parse(['--clientId', 'x']),
      );
      expect(model.buildApk, isFalse);
    });

    test('buildIpa defaults to true when not specified', () {
      final model = BuildCommandModel.fromArgs(
        buildParser().parse(['--clientId', 'x']),
      );
      expect(model.buildIpa, isTrue);
    });

    test('skipBuildCheck defaults to false when not specified', () {
      final model = BuildCommandModel.fromArgs(
        buildParser().parse(['--clientId', 'x']),
      );
      expect(model.skipBuildCheck, isFalse);
    });

    test('skipAll defaults to false when not specified', () {
      final model = BuildCommandModel.fromArgs(
        buildParser().parse(['--clientId', 'x']),
      );
      expect(model.skipAll, isFalse);
    });
  });

  group('initClonify', () {
    final clonifyDir = Directory('./clonify');
    final settingsFile = File('./clonify/clonify_settings.yaml');

    setUp(() {
      initializeTUI(noTui: true);
    });

    tearDown(() {
      if (settingsFile.existsSync()) settingsFile.deleteSync();
      if (clonifyDir.existsSync()) clonifyDir.deleteSync(recursive: true);
    });

    test('does not overwrite existing settings file', () async {
      clonifyDir.createSync();
      settingsFile.writeAsStringSync('company_name: "Existing"\n');
      await initClonify();
      expect(settingsFile.readAsStringSync(), contains('Existing'));
    });
  });

  group('getClonifySettings', () {
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

    test('returns ClonifySettings for valid settings file', () {
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

      final settings = getClonifySettings();
      expect(settings.companyName, equals('TestCompany'));
      expect(settings.defaultColor, equals('#ABCDEF'));
      expect(settings.firebaseEnabled, isTrue);
      expect(settings.firebaseSettingsFilePath, contains('firebase.json'));
      expect(settings.fastlaneEnabled, isFalse);
      expect(settings.fastlaneSettingsFilePath, contains('fastlane.json'));
    });

    test('throws if settings file does not exist', () {
      if (File(settingsPath).existsSync()) {
        File(settingsPath).deleteSync();
      }
      expect(() => getClonifySettings(), throwsException);
    });
  });
}

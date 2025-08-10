import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:test/test.dart';
import 'package:args/command_runner.dart';
import 'package:args/args.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/commands/clonify_command_runner.dart';
import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/utils/build_manager.dart';

// Mock functions for testing
String? mockLastClientId;
String? mockPromptAnswer;
bool buildAppsCalled = false;
BuildCommandModel? capturedBuildModel;

Future<String?> getLastClientId() async => mockLastClientId;

String prompt(String message) => mockPromptAnswer!;

Future<void> buildApps(BuildCommandModel buildModel) async {
  buildAppsCalled = true;
  capturedBuildModel = buildModel;
}

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

  group('BuildCommand', () {
    late CommandRunner runner;
    late BuildCommand buildCommand;

    setUp(() {
      runner = ClonifyCommandRunner();
      buildCommand = BuildCommand();
      runner.addCommand(buildCommand);
      buildAppsCalled = false;
      capturedBuildModel = null;
      mockLastClientId = null;
      mockPromptAnswer = null;
    });

    test('calls buildApps with clientId when provided', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.clientId, 'testClientId');
      expect(capturedBuildModel?.buildAab, isTrue);
      expect(capturedBuildModel?.buildApk, isFalse);
      expect(capturedBuildModel?.buildIpa, isTrue);
      expect(capturedBuildModel?.skipBuildCheck, isFalse);
      expect(capturedBuildModel?.skipAll, isFalse);
    });

    test(
      'calls buildApps with lastClientId if available and confirmed',
      () async {
        mockLastClientId = 'lastUsedClientId';
        mockPromptAnswer = 'y';
        await runner.run([]);
        expect(buildAppsCalled, isTrue);
        expect(capturedBuildModel?.clientId, 'lastUsedClientId');
      },
    );

    test(
      'does not call buildApps if lastClientId is available but not confirmed',
      () async {
        mockLastClientId = 'lastUsedClientId';
        mockPromptAnswer = 'n';
        await runner.run([]);
        expect(buildAppsCalled, isFalse);
      },
    );

    test(
      'does not call buildApps if no clientId and no lastClientId',
      () async {
        mockLastClientId = null;
        await runner.run([]);
        expect(buildAppsCalled, isFalse);
      },
    );

    test('calls buildApps with correct flags when provided', () async {
      await runner.run([
        '--client-id',
        'testClientId',
        '--build-apk',
        '--no-build-aab',
        '--no-build-ipa',
        '--skip-build-check',
        '--skip-all',
      ]);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.clientId, 'testClientId');
      expect(capturedBuildModel?.buildAab, isFalse);
      expect(capturedBuildModel?.buildApk, isTrue);
      expect(capturedBuildModel?.buildIpa, isFalse);
      expect(capturedBuildModel?.skipBuildCheck, isTrue);
      expect(capturedBuildModel?.skipAll, true);
    });

    test('buildAab defaults to true when not specified', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.buildAab, isTrue);
    });

    test('buildApk defaults to false when not specified', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.buildApk, isFalse);
    });

    test('buildIpa defaults to true when not specified', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.buildIpa, isTrue);
    });

    test('skipBuildCheck defaults to false when not specified', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.skipBuildCheck, isFalse);
    });

    test('skipAll defaults to false when not specified', () async {
      await runner.run(['--client-id', 'testClientId']);
      expect(buildAppsCalled, isTrue);
      expect(capturedBuildModel?.skipAll, isFalse);
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

      expect(clonifySettings.companyName, equals("TestCompany"));
      expect(clonifySettings.defaultColor, equals("#ABCDEF"));
      expect(clonifySettings.firebaseEnabled, isTrue);
      expect(
        clonifySettings.firebaseSettingsFilePath,
        contains("firebase.json"),
      );
      expect(clonifySettings.fastlaneEnabled, isFalse);
      expect(
        clonifySettings.fastlaneSettingsFilePath,
        contains("fastlane.json"),
      );
    });

    test('throws if settings file does not exist', () {
      expect(() => clonifySettings, throwsException);
    });
  });
}

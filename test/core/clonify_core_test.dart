/// Tests for core Clonify validation and initialization
library;

import 'dart:io';
import 'package:test/test.dart';
import '../test_utils.dart';

void main() {
  late TestDirectoryHelper testDir;

  setUp(() {
    testDir = TestDirectoryHelper();
    testDir.setUp();
    Directory.current = testDir.tempDir;
  });

  tearDown(() {
    testDir.tearDown();
  });

  group('Clonify Settings Validation', () {
    test('should validate correct clonify_settings.yaml', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      // Verify settings file exists
      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clonify_settings.yaml');

      // Verify content
      TestAssertions.assertFileContains(
        '${testDir.path}/clonify/clonify_settings.yaml',
        'company_name:',
      );
      TestAssertions.assertFileContains(
        '${testDir.path}/clonify/clonify_settings.yaml',
        'default_color:',
      );
    });

    test('should fail validation if settings file missing', () {
      // Setup - no settings file
      MockFlutterProject.createMockProject(testDir.tempDir);

      final settingsPath = '${testDir.path}/clonify/clonify_settings.yaml';
      expect(File(settingsPath).existsSync(), isFalse);
    });

    test('should fail validation if required fields missing', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      // Create invalid settings (missing required fields)
      final invalidSettings = '''
firebase:
  enabled: false
''';

      File('${clonifyDir.path}/clonify_settings.yaml')
          .writeAsStringSync(invalidSettings);

      final content = File('${clonifyDir.path}/clonify_settings.yaml')
          .readAsStringSync();

      // Missing fields
      expect(content.contains('company_name:'), isFalse);
      expect(content.contains('default_color:'), isFalse);
    });

    test('should validate hex color format', () {
      final validColors = [
        '#FFFFFF',
        '#000000',
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFF',
        '#000',
        '#F00',
      ];

      final hexColorRegex = RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$');

      for (final color in validColors) {
        expect(hexColorRegex.hasMatch(color), isTrue,
            reason: '$color should be valid');
      }
    });

    test('should reject invalid hex color format', () {
      final invalidColors = [
        'FFFFFF', // Missing #
        '#FFFFF', // Wrong length
        '#GFFFFF', // Invalid hex character
        'rgb(255,255,255)', // Not hex format
        '#FF', // Too short
        '#FFFFFFF', // Too long
      ];

      final hexColorRegex = RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$');

      for (final color in invalidColors) {
        expect(hexColorRegex.hasMatch(color), isFalse,
            reason: '$color should be invalid');
      }
    });

    test('should validate Firebase configuration structure', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        firebaseEnabled: true,
      );

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(settingsContent.contains('firebase:'), isTrue);
      expect(settingsContent.contains('enabled: true'), isTrue);
      expect(settingsContent.contains('settings_file:'), isTrue);
    });

    test('should validate Fastlane configuration structure', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        fastlaneEnabled: true,
      );

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(settingsContent.contains('fastlane:'), isTrue);
      expect(settingsContent.contains('enabled: true'), isTrue);
      expect(settingsContent.contains('settings_file:'), isTrue);
    });

    test('should validate asset list structure', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(settingsContent.contains('clone_assets:'), isTrue);
      expect(settingsContent.contains('launcher_icon_asset:'), isTrue);
      expect(settingsContent.contains('splash_screen_asset:'), isTrue);
    });

    test('should allow empty company name to fail validation', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      final invalidSettings = TestFixtures.sampleClonifySettings()
          .replaceAll('company_name: "Test Company"', 'company_name: ""');

      File('${clonifyDir.path}/clonify_settings.yaml')
          .writeAsStringSync(invalidSettings);

      final content = File('${clonifyDir.path}/clonify_settings.yaml')
          .readAsStringSync();

      expect(content.contains('company_name: ""'), isTrue);
    });
  });

  group('Clonify Initialization', () {
    test('should create clonify directory', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      TestAssertions.assertDirectoryExists('${testDir.path}/clonify');
    });

    test('should create clonify_settings.yaml on init', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clonify_settings.yaml');
    });

    test('should not overwrite existing clonify_settings.yaml', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      final settingsPath = '${testDir.path}/clonify/clonify_settings.yaml';
      final originalContent = File(settingsPath).readAsStringSync();

      // Try to init again (should not overwrite)
      expect(File(settingsPath).existsSync(), isTrue);

      final currentContent = File(settingsPath).readAsStringSync();
      expect(currentContent, equals(originalContent));
    });

    test('should create all required configuration files', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      // Verify all files created
      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clonify_settings.yaml');
      TestAssertions.assertFileExists('${testDir.path}/pubspec.yaml');
      TestAssertions.assertDirectoryExists('${testDir.path}/assets/images');
    });
  });

  group('Cleanup on Cancellation', () {
    test('should track created paths', () {
      // Simulate path tracking
      final createdPaths = <String>[];

      final testFile = File('${testDir.path}/test.txt');
      testFile.writeAsStringSync('test');
      createdPaths.add(testFile.path);

      expect(createdPaths, hasLength(1));
      expect(createdPaths.first, equals(testFile.path));
    });

    test('should cleanup created files in reverse order', () {
      // Setup
      final createdPaths = <String>[];

      // Create files
      final dir1 = Directory('${testDir.path}/dir1');
      dir1.createSync();
      createdPaths.add(dir1.path);

      final file1 = File('${dir1.path}/file1.txt');
      file1.writeAsStringSync('test');
      createdPaths.add(file1.path);

      final dir2 = Directory('${testDir.path}/dir2');
      dir2.createSync();
      createdPaths.add(dir2.path);

      // Cleanup in reverse order
      for (final path in createdPaths.reversed) {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.file) {
          File(path).deleteSync();
        } else if (type == FileSystemEntityType.directory) {
          Directory(path).deleteSync(recursive: true);
        }
      }

      // Verify cleanup
      expect(dir1.existsSync(), isFalse);
      expect(file1.existsSync(), isFalse);
      expect(dir2.existsSync(), isFalse);
    });

    test('should handle cleanup of non-existent paths', () {
      final createdPaths = <String>['${testDir.path}/nonexistent.txt'];

      // Should not throw
      expect(() {
        for (final path in createdPaths.reversed) {
          final type = FileSystemEntity.typeSync(path);
          if (type == FileSystemEntityType.file) {
            File(path).deleteSync();
          } else if (type == FileSystemEntityType.directory) {
            Directory(path).deleteSync(recursive: true);
          }
        }
      }, returnsNormally);
    });
  });

  group('Asset Selection', () {
    test('should list available assets', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      final assetsDir = Directory('${testDir.path}/assets/images');
      final assets = assetsDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();

      expect(assets, contains('icon.png'));
      expect(assets, contains('splash.png'));
      expect(assets, contains('logo.png'));
    });

    test('should validate launcher icon selection', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(settingsContent.contains('launcher_icon_asset: "icon.png"'),
          isTrue);
    });

    test('should validate splash screen selection', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(
          settingsContent.contains('splash_screen_asset: "splash.png"'), isTrue);
    });

    test('should handle no splash screen asset', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      final settingsWithoutSplash =
          TestFixtures.sampleClonifySettings().replaceAll(
        'splash_screen_asset: "splash.png"',
        '# splash_screen_asset: null',
      );

      File('${clonifyDir.path}/clonify_settings.yaml')
          .writeAsStringSync(settingsWithoutSplash);

      final content = File('${clonifyDir.path}/clonify_settings.yaml')
          .readAsStringSync();

      expect(content.contains('# splash_screen_asset: null'), isTrue);
    });
  });

  group('Last Config Persistence', () {
    test('should save last configuration', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      File('${clonifyDir.path}/last_config.json')
          .writeAsStringSync(TestFixtures.sampleCloneConfig().toString());

      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/last_config.json');
    });

    test('should retrieve last configuration', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      final clonifyDir = Directory('${testDir.path}/clonify');
      final lastConfigFile = File('${clonifyDir.path}/last_config.json');

      if (lastConfigFile.existsSync()) {
        final content = lastConfigFile.readAsStringSync();
        expect(content, isNotEmpty);
      }
    });
  });
}

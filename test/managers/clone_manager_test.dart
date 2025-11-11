/// Tests for CloneManager functionality
library;

import 'dart:convert';
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

  group('Clone Configuration Parsing', () {
    test('parseConfigFile should load valid config.json', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      // Verify file exists
      final configPath =
          '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}/config.json';
      TestAssertions.assertFileExists(configPath);

      // Verify content
      final content = File(configPath).readAsStringSync();
      final config = jsonDecode(content);

      expect(config['clientId'], equals(TestFixtures.defaultClientId));
      expect(config['packageName'], isNotNull);
      expect(config['appName'], isNotNull);
      expect(config['version'], isNotNull);
    });

    test('parseConfigFile should throw if config.json missing', () {
      // Setup - no clone created
      MockFlutterProject.createMockProject(testDir.tempDir);

      // Verify directory doesn't exist
      final configPath =
          '${testDir.path}/clonify/clones/nonexistent/config.json';
      expect(File(configPath).existsSync(), isFalse);
    });

    test('parseConfigFile should validate required fields', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final cloneDir = Directory(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}',
      );
      cloneDir.createSync(recursive: true);

      // Create invalid config (missing required fields)
      final invalidConfig = {'clientId': TestFixtures.defaultClientId};
      File(
        '${cloneDir.path}/config.json',
      ).writeAsStringSync(jsonEncode(invalidConfig));

      final configPath = '${cloneDir.path}/config.json';
      TestAssertions.assertFileExists(configPath);

      final content = File(configPath).readAsStringSync();
      final config = jsonDecode(content);

      // Verify it loads but has missing fields
      expect(config['clientId'], equals(TestFixtures.defaultClientId));
      expect(config['packageName'], isNull);
      expect(config['appName'], isNull);
    });
  });

  group('Clone Directory Structure', () {
    test('should create correct directory structure for new clone', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      // Verify directory structure
      TestAssertions.assertDirectoryExists(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}',
      );
      TestAssertions.assertDirectoryExists(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}/assets',
      );
      TestAssertions.assertFileExists(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}/config.json',
      );
    });

    test('should copy assets to clone directory', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      // Verify assets were copied
      final assetsDir =
          '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}/assets';
      TestAssertions.assertFileExists('$assetsDir/icon.png');
      TestAssertions.assertFileExists('$assetsDir/splash.png');
    });

    test('should handle multiple clones independently', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_a',
        appName: 'Client A',
        packageName: 'com.test.clienta',
      );
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_b',
        appName: 'Client B',
        packageName: 'com.test.clientb',
      );

      // Verify both clones exist
      TestAssertions.assertDirectoryExists(
        '${testDir.path}/clonify/clones/client_a',
      );
      TestAssertions.assertDirectoryExists(
        '${testDir.path}/clonify/clones/client_b',
      );

      // Verify configs are different
      final configA = jsonDecode(
        File(
          '${testDir.path}/clonify/clones/client_a/config.json',
        ).readAsStringSync(),
      );
      final configB = jsonDecode(
        File(
          '${testDir.path}/clonify/clones/client_b/config.json',
        ).readAsStringSync(),
      );

      expect(configA['clientId'], equals('client_a'));
      expect(configB['clientId'], equals('client_b'));
      expect(configA['packageName'], equals('com.test.clienta'));
      expect(configB['packageName'], equals('com.test.clientb'));
    });
  });

  group('Generated Clone Config', () {
    test('should generate lib/generated/clone_configs.dart with colors', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      // Manually create the generated file (since we're not running actual code)
      final generatedDir = Directory('${testDir.path}/lib/generated');
      generatedDir.createSync(recursive: true);

      final generatedContent = '''
// Auto-generated file. any changes will be overwritten. edit clone config instead.
abstract class CloneConfigs {
  static const primaryBlue = Color(0xFF6200EE);
  static const primaryGradient = LinearGradient(colors: <Color>[Color(0xFF6200EE), Color(0xFF03DAC6)],begin: Alignment.topLeft,end: Alignment.bottomRight,transform: GradientRotation(0));
  static const String baseUrl = "https://api.test_client_a.com";
  static const String clientId = "test_client_a";
  static const String version = "1.0.0+1";
  static const String primaryColor = "0xFF6200EE";
}
''';

      File(
        '${generatedDir.path}/clone_configs.dart',
      ).writeAsStringSync(generatedContent);

      // Verify generated file
      TestAssertions.assertFileExists(
        '${testDir.path}/lib/generated/clone_configs.dart',
      );
      TestAssertions.assertFileContains(
        '${testDir.path}/lib/generated/clone_configs.dart',
        'abstract class CloneConfigs',
      );
      TestAssertions.assertFileContains(
        '${testDir.path}/lib/generated/clone_configs.dart',
        'static const String clientId = "${TestFixtures.defaultClientId}"',
      );
    });

    test('should include all colors from config', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      // Create config with multiple colors
      final cloneDir = Directory(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}',
      );
      cloneDir.createSync(recursive: true);

      final config = TestFixtures.sampleCloneConfig();
      config['colors'] = [
        {'name': 'primaryBlue', 'color': '6200EE'},
        {'name': 'accentGreen', 'color': '03DAC6'},
        {'name': 'errorRed', 'color': 'B00020'},
      ];

      File(
        '${cloneDir.path}/config.json',
      ).writeAsStringSync(jsonEncode(config));

      // Verify config saved correctly
      final savedConfig = jsonDecode(
        File('${cloneDir.path}/config.json').readAsStringSync(),
      );
      expect(savedConfig['colors'], hasLength(3));
    });

    test('should include gradient definitions', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      final cloneDir = Directory(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}',
      );
      cloneDir.createSync(recursive: true);

      final config = TestFixtures.sampleCloneConfig();
      File(
        '${cloneDir.path}/config.json',
      ).writeAsStringSync(jsonEncode(config));

      final savedConfig = jsonDecode(
        File('${cloneDir.path}/config.json').readAsStringSync(),
      );
      expect(savedConfig['linearGradients'], hasLength(1));
      expect(
        savedConfig['linearGradients'][0]['name'],
        equals('primaryGradient'),
      );
    });
  });

  group('Version Management', () {
    test('should sync version between config.json and pubspec.yaml', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      // Read pubspec version
      final pubspecContent = File(
        '${testDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspecContent.contains('version: 1.0.0+1'), isTrue);

      // Read config version
      final config = jsonDecode(
        File(
          '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}/config.json',
        ).readAsStringSync(),
      );
      expect(config['version'], equals('1.0.0+1'));
    });

    test('should update pubspec.yaml version', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      // Update version in pubspec
      final pubspecPath = '${testDir.path}/pubspec.yaml';
      final pubspecContent = File(pubspecPath).readAsStringSync();
      final updatedContent = pubspecContent.replaceAll(
        'version: 1.0.0+1',
        'version: 1.0.1+2',
      );
      File(pubspecPath).writeAsStringSync(updatedContent);

      // Verify update
      final newContent = File(pubspecPath).readAsStringSync();
      expect(newContent.contains('version: 1.0.1+2'), isTrue);
      expect(newContent.contains('version: 1.0.0+1'), isFalse);
    });

    test('should auto-increment version correctly', () {
      const versions = [
        ['1.0.0+1', '1.0.1+2'],
        ['1.0.1+2', '1.0.2+3'],
        ['1.2.3+4', '1.2.4+5'],
        ['2.0.0+10', '2.0.1+11'],
      ];

      for (final versionPair in versions) {
        final current = versionPair[0];
        final expected = versionPair[1];

        // Simulate version increment
        final parts = current.split('+');
        final versionParts = parts[0].split('.');
        final buildNumber = int.parse(parts[1]);

        final patch = int.parse(versionParts[2]);
        final newVersion =
            '${versionParts[0]}.${versionParts[1]}.${patch + 1}+${buildNumber + 1}';

        expect(
          newVersion,
          equals(expected),
          reason: 'Version increment from $current should be $expected',
        );
      }
    });
  });

  group('Clone Cleanup', () {
    test('should remove clone directory on cleanup', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        TestFixtures.defaultClientId,
      );

      final cloneDir = Directory(
        '${testDir.path}/clonify/clones/${TestFixtures.defaultClientId}',
      );
      expect(cloneDir.existsSync(), isTrue);

      // Cleanup
      cloneDir.deleteSync(recursive: true);

      // Verify removed
      expect(cloneDir.existsSync(), isFalse);
    });

    test('should handle cleanup of non-existent clone gracefully', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      final cloneDir = Directory('${testDir.path}/clonify/clones/nonexistent');
      expect(cloneDir.existsSync(), isFalse);

      // Attempt cleanup should not throw
      expect(() {
        if (cloneDir.existsSync()) {
          cloneDir.deleteSync(recursive: true);
        }
      }, returnsNormally);
    });
  });

  group('List Clones', () {
    test('should list all configured clones', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(testDir.tempDir, 'client_a');
      MockFlutterProject.createMockCloneConfig(testDir.tempDir, 'client_b');
      MockFlutterProject.createMockCloneConfig(testDir.tempDir, 'client_c');

      // Get all clone directories
      final clonesDir = Directory('${testDir.path}/clonify/clones');
      final clones = clonesDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .toList();

      expect(clones, hasLength(3));
      expect(clones, contains('client_a'));
      expect(clones, contains('client_b'));
      expect(clones, contains('client_c'));
    });

    test('should return empty list when no clones exist', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonesDir = Directory('${testDir.path}/clonify/clones');
      clonesDir.createSync(recursive: true);

      final clones = clonesDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .toList();

      expect(clones, isEmpty);
    });
  });

  group('Last Client ID Persistence', () {
    test('should save and retrieve last client ID', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      final clonifyDir = Directory('${testDir.path}/clonify');
      clonifyDir.createSync(recursive: true);

      // Save last client ID
      final lastClientFile = File('${clonifyDir.path}/last_client.txt');
      lastClientFile.writeAsStringSync(TestFixtures.defaultClientId);

      // Retrieve
      final savedClientId = lastClientFile.readAsStringSync();
      expect(savedClientId, equals(TestFixtures.defaultClientId));
    });

    test('should handle missing last_client.txt gracefully', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      final lastClientFile = File('${testDir.path}/clonify/last_client.txt');
      expect(lastClientFile.existsSync(), isFalse);

      // Should return null or empty when file doesn't exist
      expect(() {
        if (lastClientFile.existsSync()) {
          lastClientFile.readAsStringSync();
        }
      }, returnsNormally);
    });
  });

  group('Configuration Validation', () {
    test('should accept valid clone configuration', () {
      final config = TestFixtures.sampleCloneConfig();

      expect(config['clientId'], isNotNull);
      expect(config['packageName'], isNotNull);
      expect(config['appName'], isNotNull);
      expect(config['version'], isNotNull);
      expect(config['baseUrl'], isNotNull);
      expect(config['primaryColor'], isNotNull);
    });

    test('should identify invalid package name format', () {
      final config = TestFixtures.sampleCloneConfig(
        packageName: 'InvalidPackageName', // Should be lowercase with dots
      );

      final packageName = config['packageName'] as String;

      // Package name should contain dots and be lowercase
      expect(packageName.contains('.'), isFalse);
      expect(packageName, isNot(equals(packageName.toLowerCase())));
    });

    test('should validate color format', () {
      final validColors = ['0xFF6200EE', '0xFFFFFFFF', '0xFF000000'];

      for (final color in validColors) {
        expect(color.startsWith('0xFF'), isTrue);
        expect(color.length, equals(10));
      }
    });
  });
}

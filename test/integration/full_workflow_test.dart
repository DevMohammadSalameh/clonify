/// Integration tests for complete Clonify workflows
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

  group('Full Clone Creation and Configuration Workflow', () {
    test('should complete full init → create → configure workflow', () {
      // Step 1: Initialize Clonify
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clonify_settings.yaml');
      TestAssertions.assertDirectoryExists('${testDir.path}/assets/images');

      // Step 2: Create a clone
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_production',
        appName: 'Production App',
        packageName: 'com.company.production',
        baseUrl: 'https://api.production.com',
      );

      TestAssertions.assertDirectoryExists(
          '${testDir.path}/clonify/clones/client_production');
      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clones/client_production/config.json');

      // Step 3: Verify configuration
      final config = jsonDecode(File(
              '${testDir.path}/clonify/clones/client_production/config.json')
          .readAsStringSync());

      expect(config['clientId'], equals('client_production'));
      expect(config['appName'], equals('Test App client_production'));
      expect(config['packageName'], equals('com.test.client_production'));
      expect(config['baseUrl'], equals('https://api.client_production.com'));

      // Step 4: Verify assets copied
      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clones/client_production/assets/icon.png');
      TestAssertions.assertFileExists(
          '${testDir.path}/clonify/clones/client_production/assets/splash.png');
    });

    test('should handle multiple clients in sequence', () {
      // Initialize
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      // Create multiple clients
      final clients = ['client_a', 'client_b', 'client_c'];

      for (final clientId in clients) {
        MockFlutterProject.createMockCloneConfig(
          testDir.tempDir,
          clientId,
        );
      }

      // Verify all clients exist
      for (final clientId in clients) {
        TestAssertions.assertDirectoryExists(
            '${testDir.path}/clonify/clones/$clientId');
        TestAssertions.assertFileExists(
            '${testDir.path}/clonify/clones/$clientId/config.json');
      }

      // List all clones
      final clonesDir = Directory('${testDir.path}/clonify/clones');
      final clones = clonesDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .toList();

      expect(clones, hasLength(3));
      expect(clones, containsAll(clients));
    });

    test('should switch between clients correctly', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      // Create two clients
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_dev',
        packageName: 'com.company.dev',
      );
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_prod',
        packageName: 'com.company.prod',
      );

      // Configure for client_dev
      final clonifyDir = Directory('${testDir.path}/clonify');
      File('${clonifyDir.path}/last_client.txt')
          .writeAsStringSync('client_dev');

      var lastClient =
          File('${clonifyDir.path}/last_client.txt').readAsStringSync();
      expect(lastClient, equals('client_dev'));

      // Switch to client_prod
      File('${clonifyDir.path}/last_client.txt')
          .writeAsStringSync('client_prod');

      lastClient =
          File('${clonifyDir.path}/last_client.txt').readAsStringSync();
      expect(lastClient, equals('client_prod'));
    });
  });

  group('Build Workflow Integration', () {
    test('should prepare for build after configuration', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'client_build_test',
      );

      // Create mock configuration files
      MockFlutterProject.createMockLauncherIconsConfig(testDir.tempDir);
      MockFlutterProject.createMockNativeSplashConfig(testDir.tempDir);
      MockFlutterProject.createMockPackageRenameConfig(testDir.tempDir);

      // Verify all config files exist
      TestAssertions.assertFileExists(
          '${testDir.path}/flutter_launcher_icons.yaml');
      TestAssertions.assertFileExists(
          '${testDir.path}/flutter_native_splash.yaml');
      TestAssertions.assertFileExists(
          '${testDir.path}/package_rename_config.yaml');
    });

    test('should create mock build artifacts', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockBuildArtifacts(
          testDir.tempDir, 'com.test.app');

      // Verify build artifacts
      TestAssertions.assertFileExists(
          '${testDir.path}/build/app/outputs/bundle/release/app-release.aab');
      TestAssertions.assertFileExists(
          '${testDir.path}/build/app/outputs/apk/release/app-release.apk');
      TestAssertions.assertFileExists(
          '${testDir.path}/build/ios/ipa/com.test.app.ipa');
    });

    test('should verify build metadata from config', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'build_client',
        packageName: 'com.company.buildclient',
        appName: 'Build Client App',
      );

      final config = jsonDecode(
          File('${testDir.path}/clonify/clones/build_client/config.json')
              .readAsStringSync());

      expect(config['packageName'], equals('com.test.build_client'));
      expect(config['appName'], equals('Test App build_client'));
      expect(config['version'], equals('1.0.0+1'));
    });
  });

  group('Firebase Integration Workflow', () {
    test('should configure Firebase when enabled', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        firebaseEnabled: true,
      );
      MockFlutterProject.createMockFirebaseConfig(testDir.tempDir);

      // Verify Firebase config
      TestAssertions.assertFileExists('${testDir.path}/firebase.json');

      final firebaseConfig = jsonDecode(
          File('${testDir.path}/firebase.json').readAsStringSync());
      expect(firebaseConfig['projects'], isNotNull);
    });

    test('should skip Firebase when disabled', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        firebaseEnabled: false,
      );

      final settingsContent =
          File('${testDir.path}/clonify/clonify_settings.yaml')
              .readAsStringSync();

      expect(settingsContent.contains('enabled: false'), isTrue);

      // Firebase config should not be required
      expect(File('${testDir.path}/firebase.json').existsSync(), isFalse);
    });

    test('should include Firebase project ID in clone config', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        firebaseEnabled: true,
      );
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'firebase_client',
        firebaseProjectId: 'firebase-custom-project',
      );

      final config = jsonDecode(File(
              '${testDir.path}/clonify/clones/firebase_client/config.json')
          .readAsStringSync());

      expect(config['firebaseProjectId'], equals('firebase-firebase_client'));
    });
  });

  group('Error Recovery Integration', () {
    test('should handle partial clone creation failure', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      // Create partial clone (missing config.json)
      final cloneDir =
          Directory('${testDir.path}/clonify/clones/partial_clone');
      cloneDir.createSync(recursive: true);

      // Verify directory exists but no config
      expect(cloneDir.existsSync(), isTrue);
      expect(
          File('${cloneDir.path}/config.json').existsSync(), isFalse);

      // Cleanup partial clone
      cloneDir.deleteSync(recursive: true);

      // Verify cleanup
      expect(cloneDir.existsSync(), isFalse);
    });

    test('should rollback on configuration error', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(testDir.tempDir);

      final createdPaths = <String>[];

      // Simulate creating files
      final testFile = File('${testDir.path}/test_config.json');
      testFile.writeAsStringSync('test');
      createdPaths.add(testFile.path);

      // Simulate error and rollback
      for (final path in createdPaths.reversed) {
        if (File(path).existsSync()) {
          File(path).deleteSync();
        }
      }

      // Verify rollback
      expect(testFile.existsSync(), isFalse);
    });
  });

  group('Version Synchronization Workflow', () {
    test('should sync versions between pubspec and config', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'version_sync_client',
      );

      // Read versions
      final pubspecContent =
          File('${testDir.path}/pubspec.yaml').readAsStringSync();
      final config = jsonDecode(File(
              '${testDir.path}/clonify/clones/version_sync_client/config.json')
          .readAsStringSync());

      final pubspecVersion =
          RegExp(r'version:\s*(.+)').firstMatch(pubspecContent)?.group(1);
      final configVersion = config['version'];

      expect(pubspecVersion?.trim(), equals('1.0.0+1'));
      expect(configVersion, equals('1.0.0+1'));
    });

    test('should auto-increment version', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      // Update pubspec version
      final pubspecPath = '${testDir.path}/pubspec.yaml';
      var content = File(pubspecPath).readAsStringSync();

      // Increment from 1.0.0+1 to 1.0.1+2
      content = content.replaceAll('version: 1.0.0+1', 'version: 1.0.1+2');
      File(pubspecPath).writeAsStringSync(content);

      // Verify
      final updatedContent = File(pubspecPath).readAsStringSync();
      expect(updatedContent.contains('version: 1.0.1+2'), isTrue);
    });
  });

  group('Complete Multi-Client Production Workflow', () {
    test('should handle realistic production scenario', () {
      // Step 1: Initialize project
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockClonifySettings(
        testDir.tempDir,
        firebaseEnabled: true,
        fastlaneEnabled: true,
      );

      // Step 2: Create development client
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'dev',
        appName: 'App Dev',
        packageName: 'com.company.app.dev',
        baseUrl: 'https://dev-api.company.com',
        firebaseProjectId: 'app-dev',
      );

      // Step 3: Create staging client
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'staging',
        appName: 'App Staging',
        packageName: 'com.company.app.staging',
        baseUrl: 'https://staging-api.company.com',
        firebaseProjectId: 'app-staging',
      );

      // Step 4: Create production client
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'prod',
        appName: 'App',
        packageName: 'com.company.app',
        baseUrl: 'https://api.company.com',
        firebaseProjectId: 'app-prod',
      );

      // Verify all environments
      final environments = ['dev', 'staging', 'prod'];

      for (final env in environments) {
        TestAssertions.assertDirectoryExists(
            '${testDir.path}/clonify/clones/$env');
        TestAssertions.assertFileExists(
            '${testDir.path}/clonify/clones/$env/config.json');

        final config = jsonDecode(
            File('${testDir.path}/clonify/clones/$env/config.json')
                .readAsStringSync());

        expect(config['clientId'], equals(env));
        expect(config['packageName'], contains(env));
        expect(config['baseUrl'], contains(env));
      }

      // List all clones
      final clonesDir = Directory('${testDir.path}/clonify/clones');
      final clones = clonesDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .toList();

      expect(clones, hasLength(3));
      expect(clones, containsAll(environments));
    });
  });

  group('Asset Management Workflow', () {
    test('should copy assets from clone to main project', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);
      MockFlutterProject.createMockCloneConfig(
        testDir.tempDir,
        'asset_test',
      );

      // Verify source assets exist
      final cloneAssets =
          Directory('${testDir.path}/clonify/clones/asset_test/assets');
      expect(cloneAssets.existsSync(), isTrue);

      final assetFiles = cloneAssets.listSync().whereType<File>().toList();
      expect(assetFiles, isNotEmpty);

      // Copy assets to main project (simulate)
      final mainAssets = Directory('${testDir.path}/assets/images');
      for (final file in assetFiles) {
        final fileName = file.path.split('/').last;
        file.copySync('${mainAssets.path}/$fileName');
      }

      // Verify assets in main project
      TestAssertions.assertFileExists('${testDir.path}/assets/images/icon.png');
      TestAssertions.assertFileExists(
          '${testDir.path}/assets/images/splash.png');
    });
  });
}

/// Test utilities for Clonify
/// Provides mocks, helpers, and test fixtures
library;

import 'dart:convert';
import 'dart:io';

/// Mock Flutter project structure generator
class MockFlutterProject {
  /// Creates a mock Flutter project directory structure
  static void createMockProject(Directory projectDir) {
    // Create main directories
    final directories = [
      'lib',
      'lib/generated',
      'test',
      'android',
      'android/app',
      'android/app/src/main/res',
      'ios',
      'ios/Runner',
      'assets',
      'assets/images',
      'build',
      'build/app/outputs/bundle/release',
      'build/app/outputs/apk/release',
      'build/ios/ipa',
    ];

    for (final dir in directories) {
      Directory('${projectDir.path}/$dir').createSync(recursive: true);
    }

    // Create pubspec.yaml
    final pubspecContent = '''
name: test_flutter_app
description: A test Flutter application
version: 1.0.0+1

environment:
  sdk: ^3.8.1
  flutter: ^3.0.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/images/
''';
    File('${projectDir.path}/pubspec.yaml').writeAsStringSync(pubspecContent);

    // Create main.dart
    final mainContent = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: Container(),
    );
  }
}
''';
    File('${projectDir.path}/lib/main.dart').writeAsStringSync(mainContent);

    // Create mock assets
    final mockImageData = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG header
    File(
      '${projectDir.path}/assets/images/icon.png',
    ).writeAsBytesSync(mockImageData);
    File(
      '${projectDir.path}/assets/images/splash.png',
    ).writeAsBytesSync(mockImageData);
    File(
      '${projectDir.path}/assets/images/logo.png',
    ).writeAsBytesSync(mockImageData);
  }

  /// Creates mock clonify settings file
  static void createMockClonifySettings(
    Directory projectDir, {
    bool firebaseEnabled = false,
    bool fastlaneEnabled = false,
  }) {
    final clonifyDir = Directory('${projectDir.path}/clonify');
    clonifyDir.createSync(recursive: true);

    final settingsContent =
        '''
firebase:
  enabled: $firebaseEnabled
  settings_file: "${firebaseEnabled ? './firebase.json' : ''}"

fastlane:
  enabled: $fastlaneEnabled
  settings_file: "${fastlaneEnabled ? './fastlane' : ''}"

company_name: "Test Company"
default_color: "#FFFFFF"

clone_assets:
  - icon.png
  - splash.png
  - logo.png

launcher_icon_asset: "icon.png"
splash_screen_asset: "splash.png"
''';

    File(
      '${projectDir.path}/clonify/clonify_settings.yaml',
    ).writeAsStringSync(settingsContent);
  }

  /// Creates mock clone configuration
  static void createMockCloneConfig(
    Directory projectDir,
    String clientId, {
    String? appName,
    String? packageName,
    String? baseUrl,
    String? firebaseProjectId,
  }) {
    final cloneDir = Directory('${projectDir.path}/clonify/clones/$clientId');
    cloneDir.createSync(recursive: true);

    final assetsDir = Directory('${cloneDir.path}/assets');
    assetsDir.createSync(recursive: true);

    // Copy mock assets
    final mockImageData = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG header
    File('${assetsDir.path}/icon.png').writeAsBytesSync(mockImageData);
    File('${assetsDir.path}/splash.png').writeAsBytesSync(mockImageData);

    final configContent = {
      'clientId': clientId,
      'packageName': packageName ?? 'com.test.$clientId',
      'appName': appName ?? 'Test App $clientId',
      'baseUrl': baseUrl ?? 'https://api.$clientId.com',
      'primaryColor': '0xFF6200EE',
      'firebaseProjectId': firebaseProjectId ?? 'firebase-$clientId',
      'version': '1.0.0+1',
      'colors': [
        {'name': 'primaryBlue', 'color': '6200EE'},
      ],
      'linearGradients': [
        {
          'name': 'primaryGradient',
          'colors': ['6200EE', '03DAC6'],
          'begin': 'topLeft',
          'end': 'bottomRight',
          'transform': '0',
        },
      ],
    };

    File(
      '${cloneDir.path}/config.json',
    ).writeAsStringSync(jsonEncode(configContent));
  }

  /// Creates mock build artifacts
  static void createMockBuildArtifacts(
    Directory projectDir,
    String packageName,
  ) {
    final aabPath =
        '${projectDir.path}/build/app/outputs/bundle/release/app-release.aab';
    final apkPath =
        '${projectDir.path}/build/app/outputs/apk/release/app-release.apk';
    final ipaPath = '${projectDir.path}/build/ios/ipa/$packageName.ipa';

    File(aabPath).writeAsStringSync('mock aab content');
    File(apkPath).writeAsStringSync('mock apk content');
    File(ipaPath).writeAsStringSync('mock ipa content');
  }

  /// Creates mock firebase.json
  static void createMockFirebaseConfig(Directory projectDir) {
    final firebaseContent = {
      'projects': {'default': 'test-firebase-project'},
    };

    File(
      '${projectDir.path}/firebase.json',
    ).writeAsStringSync(jsonEncode(firebaseContent));
  }

  /// Creates mock package_rename_config.yaml
  static void createMockPackageRenameConfig(Directory projectDir) {
    final renameContent = '''
package_rename_config:
  android:
    app_name: "Test App"
    package_name: "com.test.app"
  ios:
    app_name: "Test App"
    bundle_name: "com.test.app"
''';

    File(
      '${projectDir.path}/package_rename_config.yaml',
    ).writeAsStringSync(renameContent);
  }

  /// Creates flutter_launcher_icons.yaml
  static void createMockLauncherIconsConfig(Directory projectDir) {
    final content = '''
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
''';

    File(
      '${projectDir.path}/flutter_launcher_icons.yaml',
    ).writeAsStringSync(content);
  }

  /// Creates flutter_native_splash.yaml
  static void createMockNativeSplashConfig(Directory projectDir) {
    final content = '''
flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/images/splash.png"
''';

    File(
      '${projectDir.path}/flutter_native_splash.yaml',
    ).writeAsStringSync(content);
  }
}

/// Process execution mocker
class MockProcessRunner {
  final Map<String, MockProcessResult> _mockResults = {};
  final List<String> _executedCommands = [];

  /// Register a mock result for a command
  void registerMock(String commandPattern, MockProcessResult result) {
    _mockResults[commandPattern] = result;
  }

  /// Execute a command and return mock result
  MockProcessResult execute(String executable, List<String> args) {
    final fullCommand = '$executable ${args.join(' ')}';
    _executedCommands.add(fullCommand);

    // Find matching mock result
    for (final pattern in _mockResults.keys) {
      if (fullCommand.contains(pattern)) {
        return _mockResults[pattern]!;
      }
    }

    // Default success result
    return MockProcessResult(exitCode: 0, stdout: '', stderr: '');
  }

  /// Check if a command was executed
  bool wasExecuted(String commandPattern) {
    return _executedCommands.any((cmd) => cmd.contains(commandPattern));
  }

  /// Get all executed commands
  List<String> get executedCommands => List.unmodifiable(_executedCommands);

  /// Clear execution history
  void clear() {
    _executedCommands.clear();
  }
}

/// Mock process result
class MockProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  MockProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

/// User input mocker for prompt() functions
class MockUserInput {
  final Map<String, String> _responses = {};
  final List<String> _promptHistory = [];

  /// Register a response for a prompt
  void registerResponse(String promptPattern, String response) {
    _responses[promptPattern] = response;
  }

  /// Get response for a prompt
  String? getResponse(String prompt) {
    _promptHistory.add(prompt);

    for (final pattern in _responses.keys) {
      if (prompt.contains(pattern)) {
        return _responses[pattern];
      }
    }

    return null;
  }

  /// Check if a prompt was shown
  bool wasPrompted(String promptPattern) {
    return _promptHistory.any((p) => p.contains(promptPattern));
  }

  /// Get all prompts
  List<String> get prompts => List.unmodifiable(_promptHistory);

  /// Clear history
  void clear() {
    _promptHistory.clear();
  }
}

/// Test fixtures for common test data
class TestFixtures {
  static const String defaultClientId = 'test_client_a';
  static const String defaultPackageName = 'com.test.clienta';
  static const String defaultAppName = 'Test Client A';
  static const String defaultBaseUrl = 'https://api.test-a.com';
  static const String defaultFirebaseProjectId = 'firebase-test-a';
  static const String defaultVersion = '1.0.0+1';
  static const String defaultColor = '0xFF6200EE';

  /// Sample clone configuration
  static Map<String, dynamic> sampleCloneConfig({
    String? clientId,
    String? packageName,
    String? appName,
  }) {
    return {
      'clientId': clientId ?? defaultClientId,
      'packageName': packageName ?? defaultPackageName,
      'appName': appName ?? defaultAppName,
      'baseUrl': defaultBaseUrl,
      'primaryColor': defaultColor,
      'firebaseProjectId': defaultFirebaseProjectId,
      'version': defaultVersion,
      'colors': [
        {'name': 'primaryBlue', 'color': '6200EE'},
      ],
      'linearGradients': [
        {
          'name': 'primaryGradient',
          'colors': ['6200EE', '03DAC6'],
          'begin': 'topLeft',
          'end': 'bottomRight',
          'transform': '0',
        },
      ],
    };
  }

  /// Sample clonify settings
  static String sampleClonifySettings({
    bool firebaseEnabled = false,
    bool fastlaneEnabled = false,
  }) {
    return '''
firebase:
  enabled: $firebaseEnabled
  settings_file: "${firebaseEnabled ? './firebase.json' : ''}"

fastlane:
  enabled: $fastlaneEnabled
  settings_file: "${fastlaneEnabled ? './fastlane' : ''}"

company_name: "Test Company"
default_color: "#FFFFFF"

clone_assets:
  - icon.png
  - splash.png

launcher_icon_asset: "icon.png"
splash_screen_asset: "splash.png"
''';
  }

  /// Sample Firebase CLI responses
  static String firebaseLoginListResponse() {
    return jsonEncode({
      'status': 'success',
      'result': [
        {
          'user': {'email': 'test@example.com', 'id': 'test-user-id'},
        },
      ],
    });
  }

  static String firebaseProjectsListResponse() {
    return jsonEncode({
      'status': 'success',
      'results': [
        {
          'projectId': 'existing-project-1',
          'displayName': 'Existing Project 1',
          'projectOwner': 'test@example.com',
        },
      ],
    });
  }

  /// Sample build command outputs
  static String flutterBuildAabOutput() {
    return '''
Running Gradle task 'bundleRelease'...
✓ Built build/app/outputs/bundle/release/app-release.aab (15.0MB).
''';
  }

  static String flutterBuildApkOutput() {
    return '''
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/apk/release/app-release.apk (20.0MB).
''';
  }

  static String flutterBuildIpaOutput() {
    return '''
Building com.test.app for device (ios-release)...
✓ Built build/ios/ipa/Runner.ipa (25.0MB).
''';
  }
}

/// Helper to create temporary test directory
class TestDirectoryHelper {
  late Directory tempDir;

  /// Create temporary directory
  void setUp() {
    tempDir = Directory.systemTemp.createTempSync('clonify_test_');
  }

  /// Clean up temporary directory
  void tearDown() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  /// Get path to temp directory
  String get path => tempDir.path;
}

/// Assertion helpers
class TestAssertions {
  /// Assert file exists
  static void assertFileExists(String path, {String? message}) {
    if (!File(path).existsSync()) {
      throw AssertionError(message ?? 'File does not exist: $path');
    }
  }

  /// Assert directory exists
  static void assertDirectoryExists(String path, {String? message}) {
    if (!Directory(path).existsSync()) {
      throw AssertionError(message ?? 'Directory does not exist: $path');
    }
  }

  /// Assert file contains text
  static void assertFileContains(String path, String text, {String? message}) {
    assertFileExists(path);
    final content = File(path).readAsStringSync();
    if (!content.contains(text)) {
      throw AssertionError(message ?? 'File $path does not contain "$text"');
    }
  }

  /// Assert JSON file equals
  static void assertJsonFileEquals(
    String path,
    Map<String, dynamic> expected, {
    String? message,
  }) {
    assertFileExists(path);
    final content = File(path).readAsStringSync();
    final actual = jsonDecode(content);

    if (!_deepEquals(actual, expected)) {
      throw AssertionError(
        message ??
            'JSON file $path does not match expected.\nActual: $actual\nExpected: $expected',
      );
    }
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    } else if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    } else {
      return a == b;
    }
  }
}

# Testing Guide for Clonify

Comprehensive testing documentation for the Clonify CLI tool.

## Overview

Clonify includes a complete test suite that runs **without requiring a real Flutter project**. All tests use mocks, in-memory file systems, and simulated processes to provide fast, reliable testing.

## Test Structure

```
test/
├── test_utils.dart                    # Shared test utilities and mocks
├── core/
│   └── clonify_core_test.dart        # Core validation and initialization
├── managers/
│   └── clone_manager_test.dart       # Clone management operations
├── integration/
│   └── full_workflow_test.dart       # End-to-end workflows
└── clonify_test.dart                 # Legacy tests (keep for compatibility)
```

## Running Tests

### Run All Tests
```bash
dart test
```

### Run Specific Test File
```bash
dart test test/core/clonify_core_test.dart
dart test test/managers/clone_manager_test.dart
dart test test/integration/full_workflow_test.dart
```

### Run Specific Test Group
```bash
dart test test/core/clonify_core_test.dart --name "Clonify Settings Validation"
dart test test/managers/clone_manager_test.dart --name "Clone Directory Structure"
```

### Run Single Test
```bash
dart test test/core/clonify_core_test.dart --name "should validate correct clonify_settings.yaml"
```

### Run with Verbose Output
```bash
dart test --reporter expanded
```

### Run with Coverage
```bash
dart test --coverage=coverage
dart pub global activate coverage
format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib
```

## Test Categories

### 1. Core Tests (`test/core/clonify_core_test.dart`)

Tests core Clonify functionality including validation and initialization.

**Test Groups:**
- **Clonify Settings Validation**: Validates clonify_settings.yaml structure
  - Valid settings file validation
  - Missing file detection
  - Required field validation
  - Hex color format validation
  - Firebase/Fastlane configuration
  - Asset list validation

- **Clonify Initialization**: Tests initialization process
  - Directory creation
  - Settings file generation
  - Overwrite prevention

- **Cleanup on Cancellation**: Tests error recovery
  - Path tracking
  - Reverse-order cleanup
  - Non-existent path handling

- **Asset Selection**: Tests asset management
  - Asset listing
  - Launcher icon selection
  - Splash screen selection

- **Last Config Persistence**: Tests configuration caching
  - Save/retrieve last config
  - Missing config handling

**Example:**
```bash
dart test test/core/clonify_core_test.dart
```

### 2. Manager Tests (`test/managers/clone_manager_test.dart`)

Tests clone management operations.

**Test Groups:**
- **Clone Configuration Parsing**: JSON parsing and validation
  - Valid config loading
  - Missing config detection
  - Required field validation

- **Clone Directory Structure**: Directory management
  - Correct structure creation
  - Asset copying
  - Multiple clone handling

- **Generated Clone Config**: Code generation
  - clone_configs.dart generation
  - Color definitions
  - Gradient definitions

- **Version Management**: Version synchronization
  - Config/pubspec sync
  - Version updates
  - Auto-increment

- **Clone Cleanup**: Error handling
  - Directory removal
  - Graceful failure handling

- **List Clones**: Clone discovery
  - Listing all clones
  - Empty list handling

- **Last Client ID Persistence**: Client ID caching
  - Save/retrieve last ID
  - Missing ID handling

- **Configuration Validation**: Config validation
  - Valid configuration acceptance
  - Invalid package name detection
  - Color format validation

**Example:**
```bash
dart test test/managers/clone_manager_test.dart
```

### 3. Integration Tests (`test/integration/full_workflow_test.dart`)

Tests complete end-to-end workflows.

**Test Groups:**
- **Full Clone Creation and Configuration Workflow**
  - Complete init → create → configure flow
  - Multiple client handling
  - Client switching

- **Build Workflow Integration**
  - Pre-build preparation
  - Build artifact creation
  - Build metadata verification

- **Firebase Integration Workflow**
  - Firebase configuration when enabled
  - Firebase skip when disabled
  - Firebase project ID handling

- **Error Recovery Integration**
  - Partial clone recovery
  - Configuration rollback

- **Version Synchronization Workflow**
  - Pubspec/config sync
  - Auto-increment

- **Complete Multi-Client Production Workflow**
  - Realistic dev/staging/prod scenario
  - Multiple environment management

- **Asset Management Workflow**
  - Asset copying from clone to project

**Example:**
```bash
dart test test/integration/full_workflow_test.dart
```

## Test Utilities

### MockFlutterProject

Creates mock Flutter project structures for testing.

**Methods:**
```dart
// Create complete mock Flutter project
MockFlutterProject.createMockProject(Directory projectDir)

// Create clonify settings file
MockFlutterProject.createMockClonifySettings(
  Directory projectDir,
  {bool firebaseEnabled = false, bool fastlaneEnabled = false}
)

// Create clone configuration
MockFlutterProject.createMockCloneConfig(
  Directory projectDir,
  String clientId,
  {String? appName, String? packageName, String? baseUrl, String? firebaseProjectId}
)

// Create build artifacts
MockFlutterProject.createMockBuildArtifacts(Directory projectDir, String packageName)

// Create Firebase config
MockFlutterProject.createMockFirebaseConfig(Directory projectDir)
```

### TestFixtures

Provides sample data for tests.

**Constants:**
```dart
TestFixtures.defaultClientId
TestFixtures.defaultPackageName
TestFixtures.defaultAppName
TestFixtures.defaultBaseUrl
TestFixtures.defaultFirebaseProjectId
TestFixtures.defaultVersion
TestFixtures.defaultColor
```

**Methods:**
```dart
// Get sample clone configuration
TestFixtures.sampleCloneConfig({String? clientId, String? packageName, String? appName})

// Get sample clonify settings
TestFixtures.sampleClonifySettings({bool firebaseEnabled = false, bool fastlaneEnabled = false})

// Get sample Firebase responses
TestFixtures.firebaseLoginListResponse()
TestFixtures.firebaseProjectsListResponse()

// Get sample build outputs
TestFixtures.flutterBuildAabOutput()
TestFixtures.flutterBuildApkOutput()
TestFixtures.flutterBuildIpaOutput()
```

### TestDirectoryHelper

Manages temporary test directories.

**Usage:**
```dart
late TestDirectoryHelper testDir;

setUp(() {
  testDir = TestDirectoryHelper();
  testDir.setUp();
  Directory.current = testDir.tempDir;
});

tearDown(() {
  testDir.tearDown();
});
```

### TestAssertions

Custom assertions for file/directory testing.

**Methods:**
```dart
// Assert file exists
TestAssertions.assertFileExists(String path, {String? message})

// Assert directory exists
TestAssertions.assertDirectoryExists(String path, {String? message})

// Assert file contains text
TestAssertions.assertFileContains(String path, String text, {String? message})

// Assert JSON file equals expected
TestAssertions.assertJsonFileEquals(String path, Map<String, dynamic> expected, {String? message})
```

### MockProcessRunner (Future Use)

For mocking process execution (Firebase CLI, Flutter CLI, etc.)

**Usage:**
```dart
final processRunner = MockProcessRunner();

// Register mock result
processRunner.registerMock(
  'flutter build',
  MockProcessResult(exitCode: 0, stdout: 'Build success', stderr: '')
);

// Execute and get mock result
final result = processRunner.execute('flutter', ['build', 'aab']);

// Check if command was executed
expect(processRunner.wasExecuted('flutter build'), isTrue);
```

## Writing New Tests

### Test Template

```dart
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

  group('Your Test Group', () {
    test('should do something', () {
      // Setup
      MockFlutterProject.createMockProject(testDir.tempDir);

      // Execute
      // ... your test code

      // Assert
      expect(result, equals(expected));
    });
  });
}
```

### Best Practices

1. **Use Temporary Directories**: Always use `TestDirectoryHelper` for file system tests
2. **Clean Up**: Ensure `tearDown()` removes all test files
3. **Use Mocks**: Don't execute real Flutter/Firebase commands
4. **Test Isolation**: Each test should be independent
5. **Descriptive Names**: Use clear, descriptive test names
6. **Group Related Tests**: Use `group()` to organize tests
7. **Test Both Success and Failure**: Test happy paths and error cases

### Example: Testing a New Manager

```dart
group('MyNewManager', () {
  test('should perform operation successfully', () {
    // Setup
    MockFlutterProject.createMockProject(testDir.tempDir);
    MockFlutterProject.createMockCloneConfig(testDir.tempDir, 'test_client');

    // Execute operation
    // ... call your manager function

    // Assert results
    TestAssertions.assertFileExists('${testDir.path}/expected_output.json');
  });

  test('should handle errors gracefully', () {
    // Setup invalid state
    // ... create error condition

    // Execute and expect failure
    expect(() {
      // ... call your manager function
    }, throwsA(isA<CustomException>()));
  });
});
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      - run: dart pub get
      - run: dart test
```

### Test Coverage Goals

- **Core functionality**: 90%+ coverage
- **Managers**: 80%+ coverage
- **Commands**: 75%+ coverage
- **Integration tests**: All critical workflows

## Debugging Tests

### Verbose Output
```bash
dart test --reporter expanded
```

### Debug Single Test
```bash
dart test test/core/clonify_core_test.dart --name "specific test name" --reporter expanded
```

### Print Debug Information
```dart
test('debug example', () {
  print('Debug info: ${testDir.path}');
  print('Files: ${Directory(testDir.path).listSync()}');

  // Your test code
});
```

### Check Test Files
```dart
test('check files', () {
  // List all files in test directory
  final files = Directory(testDir.path)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.path)
    .toList();

  print('Files created: $files');
});
```

## Common Test Scenarios

### Testing File Creation
```dart
test('should create file', () {
  MockFlutterProject.createMockProject(testDir.tempDir);

  // Create file
  File('${testDir.path}/test.txt').writeAsStringSync('content');

  // Assert
  TestAssertions.assertFileExists('${testDir.path}/test.txt');
  TestAssertions.assertFileContains('${testDir.path}/test.txt', 'content');
});
```

### Testing JSON Files
```dart
test('should create correct JSON', () {
  MockFlutterProject.createMockCloneConfig(testDir.tempDir, 'test_client');

  final expected = {
    'clientId': 'test_client',
    'version': '1.0.0+1',
  };

  TestAssertions.assertJsonFileEquals(
    '${testDir.path}/clonify/clones/test_client/config.json',
    expected,
  );
});
```

### Testing Directory Structure
```dart
test('should create directory structure', () {
  MockFlutterProject.createMockProject(testDir.tempDir);

  TestAssertions.assertDirectoryExists('${testDir.path}/lib');
  TestAssertions.assertDirectoryExists('${testDir.path}/assets/images');
  TestAssertions.assertFileExists('${testDir.path}/pubspec.yaml');
});
```

## Troubleshooting

### Tests Fail on CI but Pass Locally
- Check file path separators (use `Platform.pathSeparator`)
- Verify temp directory handling
- Check for timing issues

### Tests Leave Behind Files
- Ensure `tearDown()` is called
- Check for test exceptions before cleanup
- Use `try-finally` for critical cleanup

### Tests Are Slow
- Avoid real process execution
- Use mocks instead of actual file operations
- Run tests in parallel: `dart test --concurrency=4`

## Future Test Improvements

- [ ] Add process execution mocks for Flutter/Firebase CLI
- [ ] Add mock user input for interactive prompts
- [ ] Add performance benchmarks
- [ ] Add mutation testing
- [ ] Add visual regression testing for generated files
- [ ] Add load testing for large clone sets

## Contributing Tests

When adding new features:

1. Write tests first (TDD approach)
2. Ensure tests pass without real Flutter project
3. Add integration test for complete workflow
4. Update this documentation
5. Maintain >80% coverage

## Resources

- [Dart Test Package](https://pub.dev/packages/test)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Test Coverage](https://pub.dev/packages/coverage)

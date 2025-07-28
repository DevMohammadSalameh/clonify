import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml_edit/yaml_edit.dart';

// ✅ Validate directories before uploading
void validateDirectories(String clientId, String iosDir, String appBundleDir) {
  if (!Directory(iosDir).existsSync()) {
    print('❌ Error: iOS project for client "$clientId" not found.');
    exit(1);
  }

  if (!Directory(appBundleDir).existsSync()) {
    print('❌ Error: Android project for client "$clientId" not found.');
    exit(1);
  }
}

// ✅ Validate if the build file exists
Future<bool> validateBuildFiles(
  String filePath,
  String fileType,
  String clientId,
) async {
  if (!File(filePath).existsSync()) {
    print('❌ Error: $fileType file not found. Build the app first.');
    final answer = promptUser(
      'Do you want to build the $fileType? (y/n):',
      'Y',
    );
    if (answer.toLowerCase() == 'y') {
      await _buildApps(clientId);
    } else {
      return false;
    }
  }
  return true;
}

Future<void> _buildApps(String clientId) async {
  const pubspecFilePath = './pubspec.yaml';

  String version = await getVersionFromConfig(clientId);
  if (version.isEmpty) {
    return;
  }

  final newVersion = promptUser(
    'Current version is $version. Enter a new version or press Enter to keep:',
    version,
  );
  await _updatePubspecVersion(newVersion, pubspecFilePath);

  await _runFlutterBuildCommands();
}

// ✅ Update pubspec.yaml version
Future<void> _updatePubspecVersion(
  String newVersion,
  String pubspecFilePath,
) async {
  try {
    final pubspecFile = File(pubspecFilePath);
    if (!pubspecFile.existsSync()) {
      print('❌ pubspec.yaml file not found.');
      return;
    }

    final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
    yamlEditor.update(['version'], newVersion);
    pubspecFile.writeAsStringSync(yamlEditor.toString());
    print('✅ Updated version to $newVersion in pubspec.yaml.');
  } catch (e) {
    print('❌ Error updating pubspec.yaml: $e');
  }
}

Future<void> _runFlutterBuildCommands() async {
  await runCommand('flutter', [
    'pub',
    'get',
  ], successMessage: '✅ Pub get completed successfully.');

  if (_promptToBuild('IPA')) {
    await runCommand('flutter', [
      'build',
      'ipa',
      '--release',
      '--no-codesign',
    ], successMessage: '✅ IPA build completed successfully.');
  }

  if (_promptToBuild('AAB')) {
    await runCommand('flutter', [
      'build',
      'aab',
      '--release',
    ], successMessage: '✅ AAB build completed successfully.');
  }

  print('✅ Build process completed successfully.');
}

bool _promptToBuild(String buildType) {
  final answer = promptUser(
    'Do you want to build the $buildType? (y/n):',
    'Y',
    validator: (input) {
      return input.toLowerCase() == 'y' || input.toLowerCase() == 'n';
    },
  );
  return answer.toLowerCase() == 'y';
}

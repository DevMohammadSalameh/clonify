import 'dart:convert';
import 'dart:io';

import 'package:clonify/utils/build_manager.dart';
import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
// // 🚀 Upload the app to the App Store

// Future<void> uploadToAppStore(String clientId, List<String> args) async {
//   print('🚀 Uploading app for client: $clientId');

//   const iosDir = './build/ios';
//   const androidAppBundleDir = './build/app/outputs/bundle/release';

//   _validateBuildsDir(clientId, iosDir, androidAppBundleDir);

//   final appIdentifier = await _getAppBundleId(clientId);
//   if (appIdentifier.isEmpty) {
//     print('❌ Error: Could not determine bundle ID for client "$clientId".');
//     return;
//   }

//   final ipaPath = '$iosDir/ipa/$appIdentifier.ipa';
//   const aabPath = '$androidAppBundleDir/app-release.aab';

//   if (!await _validateBuildFiles(ipaPath, 'IPA', clientId) ||
//       !await _validateBuildFiles(aabPath, 'AAB', clientId)) {
//     return;
//   }

//   // const apiKeyPath =
//   //     '/Users/safeersoft/development/flutter_projects/natejsoft_hr_app/clonify/doc/fastlane_settings.json';

//   // final env = DotEnv(includePlatformEnvironment: true)..load();

//   // if (!env.isDefined('APPSTORE_API_KEY_PATH')) {
//   //   print(
//   //       '❌ Error: APPSTORE_API_KEY_PATH environment variable is not defined.\n\n');
//   //   return;
//   // }
//   // final apiKeyPath = env['APPSTORE_API_KEY_PATH'];
//   // if (apiKeyPath == null || apiKeyPath.isEmpty) {
//   //   print(
//   //       '❌ Error: APPSTORE_API_KEY_PATH environment variable is not set.\n\n');
//   //   return;
//   // }

//   await runFastlaneUpload(ipaPath, appIdentifier, apiKeyPath);
// }

// // ✅ Validate directories before uploading
// void _validateBuildsDir(String clientId, String iosDir, String appBundleDir) {
//   if (!Directory(iosDir).existsSync()) {
//     print('❌ Error: iOS project for client "$clientId" not found.');
//     exit(1);
//   }

//   if (!Directory(appBundleDir).existsSync()) {
//     print('❌ Error: Android project for client "$clientId" not found.');
//     exit(1);
//   }
// }

// // ✅ Validate if the build file exists
// Future<bool> _validateBuildFiles(
//     String filePath, String fileType, String clientId) async {
//   if (!File(filePath).existsSync()) {
//     print('❌ Error: $fileType file not found. Build the app first.');
//     final answer =
//         promptUser('Do you want to build the $fileType? (y/n):', 'Y');
//     if (answer.toLowerCase() == 'y') {
//       await _buildApps(clientId);
//     } else {
//       return false;
//     }
//   }
//   return true;
// }

// // 🚀 Run Fastlane command for uploading to App Store
// Future<void> runFastlaneUpload(
//   String ipaPath,
//   String appIdentifier,
//   String apiKeyPath,
// ) async {
//   final content = File(apiKeyPath).readAsStringSync();
//   try {
//     jsonDecode(content);
//   } catch (_) {
//     print(
//         '❌ Error: The file at $apiKeyPath is not valid JSON See fastlane_instructions.md.');
//     exit(1);
//   }

//   final deliverCommand = '''
//     fastlane deliver --ipa "$ipaPath" \\
//     --app_identifier "$appIdentifier" \\
//     --submit_for_review true \\
//     --automatic_release true \\
//     --api_key_path "$apiKeyPath"
//   ''';

//   print('🔄 Running Fastlane Deliver...');
//   final process = await Process.start('bash', ['-c', deliverCommand],
//       mode: ProcessStartMode.inheritStdio);

//   final exitCode = await process.exitCode;
//   if (exitCode == 0) {
//     print('✅ Successfully uploaded to the App Store!');
//   } else {
//     print('❌ Upload failed with exit code $exitCode.');
//   }
// }

// Future<String> _getAppBundleId(String clientId) async {
//   final Map<String, dynamic> configJson = await parseConfigFile(clientId);
//   return configJson['packageName'] ?? '';
// }

// Future<void> _buildApps(String clientId) async {
//   const pubspecFilePath = './pubspec.yaml';

//   String version = await getVersionFromConfig(clientId);
//   if (version.isEmpty) {
//     return;
//   }

//   final newVersion = promptUser(
//       'Current version is $version. Enter a new version or press Enter to keep:',
//       version);
//   await _updatePubspecVersion(newVersion, pubspecFilePath);

//   await _runFlutterBuildCommands();
// }

// // ✅ Get version from config.json
// Future<String> getVersionFromConfig(String clientId) async {
//   final configFilePath = './clonify/clones/$clientId/config.json';
//   try {
//     final configFile = File(configFilePath);
//     if (!configFile.existsSync()) {
//       print('❌ Config file not found.');
//       return '';
//     }

//     final configJson = await parseConfigFile('config');
//     if (configJson['version'] == null) {
//       // If version is not found, update the version in config.json
//       print('❌ Version not found in config.json.');
//       final newVersion = promptUser('Enter the version number:', '1.0.0+1');
//       configJson['version'] = newVersion;
//       configFile.writeAsStringSync(jsonEncode(configJson));
//     }
//     return configJson['version'] ?? '';
//   } catch (e) {
//     print('❌ Failed to read or parse config.json: $e');
//     return '';
//   }
// }

// // ✅ Update pubspec.yaml version
// Future<void> _updatePubspecVersion(
//   String newVersion,
//   String pubspecFilePath,
// ) async {
//   try {
//     final pubspecFile = File(pubspecFilePath);
//     if (!pubspecFile.existsSync()) {
//       print('❌ pubspec.yaml file not found.');
//       return;
//     }

//     final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
//     yamlEditor.update(['version'], newVersion);
//     pubspecFile.writeAsStringSync(yamlEditor.toString());
//     print('✅ Updated version to $newVersion in pubspec.yaml.');
//   } catch (e) {
//     print('❌ Error updating pubspec.yaml: $e');
//   }
// }

// Future<void> _runFlutterBuildCommands() async {
//   await runCommand('flutter', ['pub', 'get'],
//       successMessage: '✅ Pub get completed successfully.');

//   if (_promptToBuild('IPA')) {
//     await runCommand('flutter', ['build', 'ipa', '--release', '--no-codesign'],
//         successMessage: '✅ IPA build completed successfully.');
//   }

//   if (_promptToBuild('AAB')) {
//     await runCommand('flutter', ['build', 'aab', '--release'],
//         successMessage: '✅ AAB build completed successfully.');
//   }

//   print('✅ Build process completed successfully.');
// }

// bool _promptToBuild(String buildType) {
//   final answer = promptUser('Do you want to build the $buildType? (y/n):', 'Y',
//       validator: (input) {
//     return input.toLowerCase() == 'y' || input.toLowerCase() == 'n';
//   });
//   return answer.toLowerCase() == 'y';
// }

// 🚀 Upload the app to the App Store

Future<void> uploadToAppStore(String clientId) async {
  print('🚀 Uploading app for client: $clientId');
  await getCurrentCloneConfig();

  const iosDir = './build/ios';
  const appBundleDir = './build/app/outputs/bundle/release';

  validateDirectories(clientId, iosDir, appBundleDir);

  final appIdentifier = await getAppBundleId(clientId);
  if (appIdentifier.isEmpty) {
    print('❌ Error: Could not determine bundle ID for client "$clientId".');
    return;
  }

  final ipaPath = '$iosDir/ipa/$appIdentifier.ipa';
  const aabPath = '$appBundleDir/app-release.aab';

  if (!await validateBuildFiles(ipaPath, 'IPA', clientId) ||
      !await validateBuildFiles(aabPath, 'AAB', clientId)) {
    return;
  }

  final apiKeyPath = Platform.environment['APPSTORE_API_KEY_PATH'] ?? '';
  // =
  // '/Users/safeersoft/development/flutter_projects/natejsoft_hr_app/clonify/doc/fastlane_settings.json';
  if (apiKeyPath.isEmpty) {
    print('❌ Error: APPSTORE_API_KEY_PATH environment variable is not set.');
    return;
  }

  await _runFastlaneUpload(ipaPath, appIdentifier, apiKeyPath);
}

// 🚀 Run Fastlane command for uploading to App Store
Future<void> _runFastlaneUpload(
  String ipaPath,
  String appIdentifier,
  String apiKeyPath,
) async {
  final content = File(apiKeyPath).readAsStringSync();
  try {
    jsonDecode(content);
  } catch (_) {
    print(
      '❌ Error: The file at $apiKeyPath is not valid JSON See fastlane_instructions.md.',
    );
    exit(1);
  }

  final deliverCommand =
      '''
    fastlane deliver --ipa "$ipaPath" \\
    --app_identifier "$appIdentifier" \\
    --submit_for_review true \\
    --automatic_release true \\
    --api_key_path "$apiKeyPath"
  ''';

  print('🔄 Running Fastlane Deliver...');
  final process = await Process.start('bash', [
    '-c',
    deliverCommand,
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('✅ Successfully uploaded to the App Store!');
  } else {
    print('❌ Upload failed with exit code $exitCode.');
  }
}

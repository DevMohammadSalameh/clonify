import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml/yaml.dart';
// // 🚀 Upload the app to the App Store

// Future<void> uploadToAppStore(String clientId, List<String> args) async {
//   logger.i('🚀 Uploading app for client: $clientId');

//   const iosDir = './build/ios';
//   const androidAppBundleDir = './build/app/outputs/bundle/release';

//   _validateBuildsDir(clientId, iosDir, androidAppBundleDir);

//   final appIdentifier = await _getAppBundleId(clientId);
//   if (appIdentifier.isEmpty) {
//     logger.e('❌ Error: Could not determine bundle ID for client "$clientId".');
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
//     logger.e('❌ Error: iOS project for client "$clientId" not found.');
//     exit(1);
//   }

//   if (!Directory(appBundleDir).existsSync()) {
//     logger.e('❌ Error: Android project for client "$clientId" not found.');
//     exit(1);
//   }
// }

// // ✅ Validate if the build file exists
// Future<bool> _validateBuildFiles(
//     String filePath, String fileType, String clientId) async {
//   if (!File(filePath).existsSync()) {
//     logger.e('❌ Error: $fileType file not found. Build the app first.');
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
//     logger.e('❌ Upload failed with exit code $exitCode.');
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
//       logger.e('❌ Config file not found.');
//       return '';
//     }

//     final configJson = await parseConfigFile('config');
//     if (configJson['version'] == null) {
//       // If version is not found, update the version in config.json
//       logger.e('❌ Version not found in config.json.');
//       final newVersion = promptUser('Enter the version number:', '1.0.0+1');
//       configJson['version'] = newVersion;
//       configFile.writeAsStringSync(jsonEncode(configJson));
//     }
//     return configJson['version'] ?? '';
//   } catch (e) {
//     logger.e('❌ Failed to read or parse config.json: $e');
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
//       logger.e('❌ pubspec.yaml file not found.');
//       return;
//     }

//     final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
//     yamlEditor.update(['version'], newVersion);
//     pubspecFile.writeAsStringSync(yamlEditor.toString());
//     print('✅ Updated version to $newVersion in pubspec.yaml.');
//   } catch (e) {
//     logger.e('❌ Error updating pubspec.yaml: $e');
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

Future<void> uploadApps(
  String clientId, {

  bool skipAll = false,
  bool skipAndroidUploadCheck = false,
  bool skipIOSUploadCheck = false,
}) async {
  final configFilePath = './clonify/clones/$clientId/config.json';
  const pubspecFilePath = './pubspec.yaml';

  // Check if config.json exists
  final configFile = File(configFilePath);
  if (!configFile.existsSync()) {
    logger.e('❌ Config file not found for client ID: $clientId');
    return;
  }

  // Parse config.json to get the packageName
  String packageName;
  try {
    final configContent = jsonDecode(configFile.readAsStringSync());
    packageName = configContent['packageName'] ?? 'Unknown Package Name';
  } catch (e) {
    logger.e('❌ Failed to read or parse $configFilePath: $e');
    return;
  }

  // Read pubspec.yaml to get the version
  String version;
  try {
    final pubspecContent = File(pubspecFilePath).readAsStringSync();
    final pubspecMap = loadYaml(pubspecContent);
    version = pubspecMap['version'] ?? 'Unknown Version';
  } catch (e) {
    logger.e('❌ Failed to read or parse $pubspecFilePath: $e');
    return;
  }

  final uploadIOSAnswer = (skipAll || skipAndroidUploadCheck) == true
      ? true
      : prompt('Do you want to upload the iOS IPA? (y/n):');

  final uploadIOS = uploadIOSAnswer == true
      ? true
      : (uploadIOSAnswer as String).toLowerCase() == 'y';

  final uploadAndroidAnswer = (skipAll || skipAndroidUploadCheck) == true
      ? true
      : prompt('Do you want to upload the Android AAB? (y/n):');
  final uploadAndroid = uploadAndroidAnswer == true
      ? true
      : (uploadAndroidAnswer as String).toLowerCase() == 'y';

  if (packageName.isEmpty || version.isEmpty) {
    throw CustomException(
      'Package name and version cannot be empty. During upload.',
    );
  }
  final ipaFile = File(Constants.ipaPath(packageName));
  if (!ipaFile.existsSync() && uploadIOS) {
    throw CustomException('iOS IPA path does not exist. During upload.');
  }
  final aabFile = File(Constants.aabPath);

  if (!aabFile.existsSync() && uploadAndroid) {
    throw CustomException('Android AAB path does not exist. During upload.');
  }

  Future.wait([
    if (uploadAndroid)
      updateFastlaneFiles(
        fastlanePath: 'android/fastlane/Fastfile',
        bundleId: packageName,
        appVersion: version.split('+').first,
        appVersionCode: version.split('+').last,
      ),
    if (uploadAndroid)
      runCommand(
        'fastlane',
        ['upload'],
        workingDirectory: 'android',
        successMessage: '✅ Uploaded Android build!',
      ),

    if (uploadIOS)
      updateFastlaneFiles(
        fastlanePath: 'ios/fastlane/Fastfile',
        bundleId: packageName,
        appVersion: version,
      ),
    if (uploadIOS)
      runCommand(
        'fastlane',
        ['upload'],
        workingDirectory: 'ios',
        successMessage: '✅ Uploaded iOS build!',
      ),
  ]);
}

Future<void> updateFastlaneFiles({
  required String fastlanePath,
  required String bundleId,
  required String appVersion,
  String? appVersionCode,
}) async {
  // Function to replace variables in Fastlane files
  Future<void> updateFile(
    String filePath,
    Map<String, String> replacements,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      logger.e('❌ Fastlane file not found: $filePath');
      return;
    }

    String content = file.readAsStringSync();
    replacements.forEach((key, value) {
      content = content.replaceAll(RegExp(key), value);
    });

    file.writeAsStringSync(content);
    logger.i('✅ Updated $filePath');
  }

  // Define replacement mappings
  final Map<String, String> replacements = {
    r'bundleId = ".*?"': 'bundleId = "$bundleId"',
    r'app_version = ".*?"': 'app_version = "$appVersion"',
    r'app_version_code = ".*?"': 'app_version_code = "$appVersionCode"',
  };

  // Update Fastlane file
  await updateFile(fastlanePath, replacements);
}

// // 🚀 Upload the app to the App Store

// Future<void> uploadToAppStore(String clientId) async {
//   print('🚀 Uploading app for client: $clientId');
//   await getCurrentCloneConfig();

//   const iosDir = './build/ios';
//   const appBundleDir = './build/app/outputs/bundle/release';

//   validateDirectories(clientId, iosDir, appBundleDir);

//   final appIdentifier = await getAppBundleId(clientId);
//   if (appIdentifier.isEmpty) {
//     logger.e('❌ Error: Could not determine bundle ID for client "$clientId".');
//     return;
//   }

//   final ipaPath = '$iosDir/ipa/$appIdentifier.ipa';
//   const aabPath = '$appBundleDir/app-release.aab';

//   if (!await validateBuildFiles(ipaPath, 'IPA', clientId) ||
//       !await validateBuildFiles(aabPath, 'AAB', clientId)) {
//     return;
//   }

//   final apiKeyPath = Platform.environment['APPSTORE_API_KEY_PATH'] ?? '';
//   // =
//   // '/Users/safeersoft/development/flutter_projects/natejsoft_hr_app/clonify/doc/fastlane_settings.json';
//   if (apiKeyPath.isEmpty) {
//     logger.e('❌ Error: APPSTORE_API_KEY_PATH environment variable is not set.');
//     return;
//   }

//   await _runFastlaneUpload(ipaPath, appIdentifier, apiKeyPath);
// }

// // 🚀 Run Fastlane command for uploading to App Store
// Future<void> _runFastlaneUpload(
//   String ipaPath,
//   String appIdentifier,
//   String apiKeyPath,
// ) async {
//   final content = File(apiKeyPath).readAsStringSync();
//   try {
//     jsonDecode(content);
//   } catch (_) {
//     print(
//       '❌ Error: The file at $apiKeyPath is not valid JSON See fastlane_instructions.md.',
//     );
//     exit(1);
//   }

//   final deliverCommand =
//       '''
//     fastlane deliver --ipa "$ipaPath" \\
//     --app_identifier "$appIdentifier" \\
//     --submit_for_review true \\
//     --automatic_release true \\
//     --api_key_path "$apiKeyPath"
//   ''';

//   print('🔄 Running Fastlane Deliver...');
//   final process = await Process.start('bash', [
//     '-c',
//     deliverCommand,
//   ], mode: ProcessStartMode.inheritStdio);

//   final exitCode = await process.exitCode;
//   if (exitCode == 0) {
//     print('✅ Successfully uploaded to the App Store!');
//   } else {
//     logger.e('❌ Upload failed with exit code $exitCode.');
//   }
// }

import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/messages.dart';
import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/tui_helpers.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Builds Flutter applications for a specific client ID based on the provided build model.
///
/// This function orchestrates the build process for Android (APK/AAB) and iOS (IPA)
/// platforms. It loads build metadata, prompts the user for confirmation (unless skipped),
/// and then executes the appropriate `flutter build` commands.
///
/// [buildModel] A [BuildCommandModel] containing the client ID and various
///              flags to control the build process (e.g., `buildApk`, `buildAab`,
///              `buildIpa`, `skipBuildCheck`, `skipAll`).
///
/// Throws an [Exception] if the build metadata cannot be loaded or if any
/// of the underlying `flutter build` commands fail.
Future<void> buildApps(BuildCommandModel buildModel) async {
  final buildMetadata = await _loadBuildMetadata(buildModel.clientId!);
  if (buildMetadata == null) {
    return;
  }

  final packageName = buildMetadata['packageName']!;
  final appName = buildMetadata['appName']!;
  final version = buildMetadata['version']!;

  if (buildModel.buildIpa ||
      !buildModel.skipBuildCheck ||
      !buildModel.skipAll) {
    if (!_promptUserForConfirmation(
      packageName: packageName,
      appName: appName,
      version: version,
      skipBuildCheck: buildModel.skipBuildCheck,
    )) {
      return;
    }
  }

  logger.i('🚀 Building apps for client ID: ${buildModel.clientId}');

  final stopwatch = Stopwatch()..start();

  try {
    await _runFlutterBuildCommands(
      buildModel: buildModel,
      version: version,
      stopwatch: stopwatch,
    );

    logger.i(
      '✅ Apps built successfully for client ID: ${buildModel.clientId} in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.',
    );
  } catch (e) {
    // Error is already logged in _runFlutterBuildCommands
  } finally {
    stopwatch.stop();
  }
}

Future<Map<String, String>?> _loadBuildMetadata(String clientId) async {
  final configFilePath = Constants.configFilePath(clientId);

  final configFile = File(configFilePath);
  if (!configFile.existsSync()) {
    logger.e(Messages.configNotFoundForClientId(clientId));
    return null;
  }

  String packageName;
  String appName;
  try {
    final configContent = jsonDecode(configFile.readAsStringSync());
    packageName = configContent['packageName'];
    appName = configContent['appName'];
  } catch (e) {
    logger.e(Messages.failedToReadOrParseConfigFile(configFilePath, e));
    return null;
  }

  String version;
  try {
    final pubspecContent = File(Constants.pubspecFilePath).readAsStringSync();
    final pubspecMap = yaml.loadYaml(pubspecContent);
    version = pubspecMap['version'];
  } catch (e) {
    logger.e(Messages.failedToReadOrParsePubspecFile(e));
    return null;
  }

  return {'packageName': packageName, 'appName': appName, 'version': version};
}

bool _promptUserForConfirmation({
  required String packageName,
  required String appName,
  required String version,
  required bool skipBuildCheck,
}) {
  final answer = prompt(
    ' Have you verified the Bundle ID ($packageName) and App Name ($appName) in the Xcode project, with the version [$version]? (y/n):',
    skip: skipBuildCheck,
    skipValue: 'y',
  );
  if (answer.toLowerCase() != 'y') {
    logger.e(Messages.pleaseVerifyBundleIdAndAppNameInXcodeProject);
    return false;
  }
  return true;
}

Future<void> _runFlutterBuildCommands({
  required BuildCommandModel buildModel,
  required String version,
  required Stopwatch stopwatch,
}) async {
  // Build list of platforms being built
  final platforms = <String>[];
  if (buildModel.buildApk) platforms.add('APK');
  if (buildModel.buildAab) platforms.add('AAB');
  if (buildModel.buildIpa) platforms.add('IPA');

  final buildProgress = progressWithTUI(
    '🛠  Building ${platforms.join(', ')}...',
  );

  try {
    await Future.wait([
      if (buildModel.buildApk)
        runCommand(
          'flutter',
          ['build', 'apk', '--release'],
          successMessage: '✅ Android application is built successfully!',
          showLoading: false,
        ),
      if (buildModel.buildAab)
        runCommand(
          'flutter',
          ['build', 'aab', '--release'],
          successMessage: '✅ Android app bundle is built successfully!',
          showLoading: false,
        ),
      if (buildModel.buildIpa)
        runCommand(
          'flutter',
          [
            'build',
            'ipa',
            '--release',
            '--build-number=${version.split('+').last}',
          ],
          successMessage: '✅ iOS app archive is built successfully!',
          showLoading: false,
        ),
    ]);

    buildProgress?.complete(
      'Builds completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s',
    );

    if (buildModel.buildIpa) {
      infoMessage('✓ iOS app archive at: build/ios/archive/Runner.xcarchive');
    }
    if (buildModel.buildAab) {
      infoMessage(
        '✓ Android app bundle at: build/app/outputs/bundle/release/app-release.aab',
      );
    }
  } catch (e) {
    buildProgress?.fail();
    logger.e('❌ Error during app build: $e');
    rethrow;
  }
}

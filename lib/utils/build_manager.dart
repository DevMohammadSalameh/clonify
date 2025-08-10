import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/messages.dart';
import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml/yaml.dart' as yaml;

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
  final progress = Stream.periodic(const Duration(milliseconds: 100), (count) {
    logger.i(
      'Building these apps : ${buildModel.buildApk ? '\n- APK' : ''} ${buildModel.buildAab ? '\n- AAB' : ''} ${buildModel.buildIpa ? '\n- IPA' : ''}',
    );
    stdout.write(
      '\r🛠 Apps are being built... [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]',
    );
  });
  final progressSubscription = progress.listen((_) {});

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

    progressSubscription.cancel();
    stdout.write('\r'); // Clear the line
    if (buildModel.buildIpa) {
      logger.i(
        '✓ You can find the iOS app archive at\n  ${'-' * 10}→ build/ios/archive/Runner.xcarchive',
      );
    }
    if (buildModel.buildAab) {
      logger.i(
        '✓ You can find the Android app bundle at\n  ${'-' * 10}→ build/app/outputs/bundle/release/app-release.aab',
      );
    }
  } catch (e) {
    progressSubscription.cancel();
    stdout.write('\r'); // Clear the line
    logger.e('❌ Error during app build: $e');
    rethrow;
  } finally {
    progressSubscription.cancel();
  }
}

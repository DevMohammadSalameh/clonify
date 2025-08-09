import 'dart:convert';
import 'dart:io';

import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml/yaml.dart' as yaml;

Future<void> buildApps(BuildCommandModel buildModel) async {
  final configFilePath = './clonify/clones/${buildModel.clientId}/config.json';
  const pubspecFilePath = './pubspec.yaml';

  // Check if config.json exists
  final configFile = File(configFilePath);
  if (!configFile.existsSync()) {
    logger.e('❌ Config file not found for client ID: ${buildModel.clientId}');
    return;
  }

  // Parse config.json to get the packageName
  String packageName;
  String appName;
  try {
    final configContent = jsonDecode(configFile.readAsStringSync());
    packageName = configContent['packageName'] ?? 'Unknown Package Name';
    appName = configContent['appName'] ?? 'Unknown App Name';
  } catch (e) {
    logger.e('❌ Failed to read or parse $configFilePath: $e');
    return;
  }

  // Read pubspec.yaml to get the version
  String version;
  try {
    final pubspecContent = File(pubspecFilePath).readAsStringSync();
    final pubspecMap = yaml.loadYaml(pubspecContent);
    version = pubspecMap['version'] ?? 'Unknown Version';
  } catch (e) {
    logger.e('❌ Failed to read or parse $pubspecFilePath: $e');
    return;
  }

  // Update prompt message with packageName, appName, and version
  final answer = prompt(
    ' Have you verified the Bundle ID ($packageName) and App Name ($appName) in the Xcode project, with the version [$version]? (y/n):',
    skip: buildModel.skipBuildCheck,
    skipValue: 'y',
  );
  if (answer.toLowerCase() != 'y') {
    logger.e(
      '❌ Please verify the Bundle ID and App Name in the Xcode project.',
    );
    return;
  }

  logger.i('🚀 Building apps for client ID: ${buildModel.clientId}');

  // Start a stopwatch to track total build time
  final stopwatch = Stopwatch()..start();

  // Periodically display a loading message with the elapsed time
  final progress = Stream.periodic(const Duration(milliseconds: 100), (count) {
    stdout.write(
      '\r🛠 Apps are being built... [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]',
    );
  });
  final progressSubscription = progress.listen((_) {});

  try {
    // Run all commands in parallel
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

    // Stop the progress display
    progressSubscription.cancel();
    stdout.write('\r'); // Clear the line
    logger.i(
      '✓ You can find the iOS app archive at\n  ${'-' * 10}→ build/ios/archive/Runner.xcarchive',
    );
    logger.i(
      '✓ You can find the Android app bundle at\n  ${'-' * 10}→ build/app/outputs/bundle/release/app-release.aab',
    );
    // Display the total build time
    logger.i(
      '✅ Apps built successfully for client ID: ${buildModel.clientId} in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.',
    );
  } catch (e) {
    // Stop the progress display and print the error
    progressSubscription.cancel();
    stdout.write('\r'); // Clear the line
    logger.e('❌ Error during app build: $e');
  } finally {
    stopwatch.stop();
  }
}

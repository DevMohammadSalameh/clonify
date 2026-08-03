import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/clonify_helpers.dart';

/// Fixed Shorebird config path used by Clonify (no settings_file needed).
const String defaultShorebirdYamlPath = './shorebird.yaml';

/// Syncs [shorebirdAppId] into `./shorebird.yaml`.
///
/// Updates the first top-level `app_id:` line.
///
/// Unlike Firebase configure, this is cheap and should usually run even when
/// `--skipAll` is set. Pass [skip] only for an explicit
/// `--skipShorebirdConfigure`.
Future<void> configureShorebirdAppId({
  required String shorebirdAppId,
  bool skip = false,
}) async {
  if (skip) {
    logger.i('>>| Skipping Shorebird configuration.');
    return;
  }

  final appId = shorebirdAppId.trim();
  if (appId.isEmpty) {
    logger.i('>>| Skipping Shorebird configuration (empty shorebirdAppId).');
    return;
  }

  final file = File(defaultShorebirdYamlPath);
  if (!file.existsSync()) {
    logger.e('❌ Shorebird file not found at $defaultShorebirdYamlPath');
    logger.i('  Run `shorebird init` in the Flutter project root first.');
    return;
  }

  final content = file.readAsStringSync();
  final appIdPattern = RegExp(r'^app_id:\s*.*$', multiLine: true);

  late final String updated;
  if (appIdPattern.hasMatch(content)) {
    updated = content.replaceFirstMapped(appIdPattern, (_) => 'app_id: $appId');
  } else {
    updated = 'app_id: $appId\n$content';
  }

  file.writeAsStringSync(updated);
  logger.i('✅ Updated Shorebird app_id to $appId in $defaultShorebirdYamlPath');
}

/// Reads `shorebirdAppId` from a clone config map.
String resolveShorebirdAppId(Map<String, dynamic> configJson) {
  final value = configJson['shorebirdAppId'];
  if (value is String) {
    return value.trim();
  }
  return '';
}

/// Reads the current `app_id` from `./shorebird.yaml`.
String readCurrentShorebirdAppId() {
  final file = File(defaultShorebirdYamlPath);
  if (!file.existsSync()) {
    return '';
  }
  final match = RegExp(
    r'^app_id:\s*(.+)$',
    multiLine: true,
  ).firstMatch(file.readAsStringSync());
  return match?.group(1)?.trim() ?? '';
}

/// Reads Android `applicationId` from `android/app/build.gradle(.kts)`.
String? readAndroidApplicationId() {
  final kts = File(Constants.androidAppLevelKotlinBuildGradleFilePath);
  final groovy = File(Constants.androidAppLevelBuildGradleFilePath);
  final file = kts.existsSync()
      ? kts
      : groovy.existsSync()
      ? groovy
      : null;
  if (file == null) return null;

  final match = RegExp(
    r'''applicationId\s*(?:=|:)\s*["']([^"']+)["']''',
  ).firstMatch(file.readAsStringSync());
  return match?.group(1);
}

/// Reads iOS `PRODUCT_BUNDLE_IDENTIFIER` from the Xcode project.
String? readIosBundleId() {
  final file = File(Constants.iosProjectFilePath);
  if (!file.existsSync()) return null;

  final match = RegExp(
    r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);',
  ).firstMatch(file.readAsStringSync());
  return match?.group(1)?.trim();
}

/// Ensures the active native bundle id matches [expectedPackageName]
/// for the platforms present in [shorebirdArgs].
void assertBundleIdMatches({
  required List<String> shorebirdArgs,
  required String expectedPackageName,
}) {
  final lowerArgs = shorebirdArgs.map((a) => a.toLowerCase()).toList();

  if (lowerArgs.contains('android')) {
    final current = readAndroidApplicationId();
    if (current != expectedPackageName) {
      throw CustomException(
        'Android applicationId is "$current" but clone needs "$expectedPackageName".',
      );
    }
  }

  if (lowerArgs.contains('ios')) {
    final current = readIosBundleId();
    if (current != expectedPackageName) {
      throw CustomException(
        'iOS bundle id is "$current" but clone needs "$expectedPackageName".',
      );
    }
  }
}

/// Ensures `shorebird.yaml` app_id matches the clone's [expectedAppId].
void assertShorebirdAppIdMatches(String expectedAppId) {
  final current = readCurrentShorebirdAppId();
  if (current != expectedAppId) {
    throw CustomException(
      'shorebird.yaml app_id is "$current" but clone needs "$expectedAppId". '
      'Enable shorebird in clonify_settings.yaml and re-run configure.',
    );
  }
}

/// Runs the Shorebird CLI with inherited stdio.
Future<void> execShorebird(List<String> shorebirdArgs) async {
  final result = await Process.start(
    'shorebird',
    shorebirdArgs,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  final exitCode = await result.exitCode;
  if (exitCode != 0) {
    throw CustomException('shorebird exited with code $exitCode');
  }
}

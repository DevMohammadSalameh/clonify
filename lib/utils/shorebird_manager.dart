import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';

/// Syncs [shorebirdAppId] into the project's Shorebird settings file.
///
/// Updates the first top-level `app_id:` line in [settingsFilePath]
/// (defaults to `./shorebird.yaml` when empty).
///
/// Unlike Firebase configure, this is cheap and should usually run even when
/// `--skipAll` is set. Pass [skip] only for an explicit
/// `--skipShorebirdConfigure`.
Future<void> configureShorebirdAppId({
  required String shorebirdAppId,
  required String settingsFilePath,
  bool skip = false,
}) async {
  if (skip) {
    logger.i('>>| Skipping Shorebird configuration.');
    return;
  }

  final appId = shorebirdAppId.trim();
  if (appId.isEmpty) {
    logger.i(
      '>>| Skipping Shorebird configuration (empty shorebirdAppId).',
    );
    return;
  }

  final path =
      settingsFilePath.trim().isEmpty ? './shorebird.yaml' : settingsFilePath;
  final file = File(path);
  if (!file.existsSync()) {
    logger.e('❌ Shorebird settings file not found at $path');
    logger.i(
      '  Create shorebird.yaml (shorebird init) or fix shorebird.settings_file.',
    );
    return;
  }

  final content = file.readAsStringSync();
  final appIdPattern = RegExp(r'^app_id:\s*.*$', multiLine: true);

  late final String updated;
  if (appIdPattern.hasMatch(content)) {
    updated = content.replaceFirstMapped(
      appIdPattern,
      (_) => 'app_id: $appId',
    );
  } else {
    updated = 'app_id: $appId\n$content';
  }

  file.writeAsStringSync(updated);
  logger.i('✅ Updated Shorebird app_id to $appId in $path');
}

/// Reads `shorebirdAppId` from a clone config map.
String resolveShorebirdAppId(Map<String, dynamic> configJson) {
  final value = configJson['shorebirdAppId'];
  if (value is String) {
    return value.trim();
  }
  return '';
}

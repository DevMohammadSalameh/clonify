import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:path/path.dart' as p;

const notificationIconConfigKey = 'notificationIcon';
const backgroundNotificationColorConfigKey = 'backgroundNotificationColor';
const defaultNotificationIconFileName = 'ic_notification.png';
const androidNotificationIconFileName = 'ic_notification.png';
const androidNotificationColorName = 'notification_color';

const androidNotificationDrawableDirs = <String>[
  'drawable',
  'drawable-mdpi',
  'drawable-hdpi',
  'drawable-xhdpi',
  'drawable-xxhdpi',
  'drawable-xxxhdpi',
];

/// Syncs a per-clone Android status-bar notification icon (and optional tint)
/// when `clonify/clones/{clientId}/assets/{notificationIcon}` exists.
///
/// - Copies the white-on-transparent PNG into `android/app/src/main/res/drawable*/`
/// - Updates `notification_color` in `android/app/src/main/res/values/colors.xml`
///   from `backgroundNotificationColor`, falling back to `primaryColor`
Future<void> applyAndroidNotificationIcon(
  String clientId,
  Map<String, dynamic> configJson,
) async {
  final configuredIcon =
      (configJson[notificationIconConfigKey] as String?)?.trim();
  final iconFileName =
      (configuredIcon != null && configuredIcon.isNotEmpty)
      ? configuredIcon
      : defaultNotificationIconFileName;

  final source = File(
    p.join('clonify', 'clones', clientId, 'assets', iconFileName),
  );
  if (!source.existsSync()) {
    logger.i(
      'ℹ️  No Android notification icon at ${source.path}; skipped.',
    );
    return;
  }

  final resRoot = Directory(
    p.join(Constants.androidMainDirPath, 'res'),
  );
  if (!resRoot.existsSync()) {
    logger.w(
      '⚠️  ${resRoot.path} not found; skipped Android notification icon.',
    );
    return;
  }

  for (final dirName in androidNotificationDrawableDirs) {
    final dir = Directory(p.join(resRoot.path, dirName));
    dir.createSync(recursive: true);
    final target = File(p.join(dir.path, androidNotificationIconFileName));
    source.copySync(target.path);
  }

  logger.i(
    '✅ Android notification icon synced from ${source.path}',
  );

  final tint = resolveBackgroundNotificationColor(configJson);
  if (tint != null) {
    await applyAndroidNotificationColor(tint);
  }
}

/// Prefers `backgroundNotificationColor`, then `primaryColor`.
String? resolveBackgroundNotificationColor(Map<String, dynamic> configJson) {
  final dedicated =
      (configJson[backgroundNotificationColorConfigKey] as String?)?.trim();
  if (dedicated != null && dedicated.isNotEmpty) return dedicated;
  final primary = (configJson['primaryColor'] as String?)?.trim();
  if (primary != null && primary.isNotEmpty) return primary;
  return null;
}

/// Converts clone colors like `0xFFFF7300` / `#FF7300` to `#RRGGBB`.
String? notificationColorHexFromPrimary(String primaryColor) {
  var value = primaryColor.trim();
  if (value.isEmpty) return null;

  if (value.startsWith('#')) {
    value = value.substring(1);
  } else if (value.toLowerCase().startsWith('0x')) {
    value = value.substring(2);
  }

  value = value.toUpperCase();
  if (value.length == 8) {
    // AARRGGBB → RRGGBB
    value = value.substring(2);
  }
  if (value.length != 6 || !RegExp(r'^[0-9A-F]{6}$').hasMatch(value)) {
    return null;
  }
  return '#$value';
}

Future<void> applyAndroidNotificationColor(String colorValue) async {
  final hex = notificationColorHexFromPrimary(colorValue);
  if (hex == null) {
    logger.w(
      '⚠️  Could not parse notification tint "$colorValue".',
    );
    return;
  }

  final colorsFile = File(
    p.join(Constants.androidMainDirPath, 'res', 'values', 'colors.xml'),
  );
  if (!colorsFile.existsSync()) {
    logger.w(
      '⚠️  ${colorsFile.path} not found; skipped notification_color sync.',
    );
    return;
  }

  final content = await colorsFile.readAsString();
  final colorRegex = RegExp(
    '<color name="$androidNotificationColorName">([^<]*)</color>',
  );
  if (!colorRegex.hasMatch(content)) {
    logger.w(
      '⚠️  <$androidNotificationColorName> not found in colors.xml; skipped tint sync.',
    );
    return;
  }

  final updated = content.replaceFirst(
    colorRegex,
    '<color name="$androidNotificationColorName">$hex</color>',
  );
  await colorsFile.writeAsString(updated);
  logger.i('✅ Android notification_color set to $hex');
}

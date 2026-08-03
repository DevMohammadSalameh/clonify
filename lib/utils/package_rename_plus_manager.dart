// Package Rename Plus

import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/models/clonify_settings_model.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/src/package_rename_plus/package_rename_plus.dart'
    as package_rename;
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:yaml_edit/yaml_edit.dart';

/// Returns a short label suitable for iOS CFBundleName (max 15 characters).
String shortIosBundleName(String appName) {
  if (appName.length <= 15) {
    return appName;
  }
  return appName.substring(0, 15);
}

/// Reads the currently configured package name from generated clone config.
String? readCurrentPackageName() {
  final cloneConfigFile = File('./lib/generated/clone_configs.dart');
  if (cloneConfigFile.existsSync()) {
    final content = cloneConfigFile.readAsStringSync();
    final match = RegExp(
      r'static const String packageName = "([^"]+)";',
    ).firstMatch(content);
    if (match != null) {
      return match.group(1);
    }
  }

  final gradleFile = File('./android/app/build.gradle.kts');
  final legacyGradleFile = File('./android/app/build.gradle');
  for (final file in [gradleFile, legacyGradleFile]) {
    if (!file.existsSync()) {
      continue;
    }
    final match = RegExp(
      r'applicationId\s*=\s*"([^"]+)"',
    ).firstMatch(file.readAsStringSync());
    if (match != null) {
      return match.group(1);
    }
  }

  return null;
}

/// Runs the `package_rename_plus` tool to rename the application and package.
///
/// This function first ensures that a `package_rename_config.yaml` file exists
/// and is properly configured with the provided [appName] and [packageName]
/// for Android, iOS, web, Linux, and Windows. It then calls the internalized
/// package_rename_plus function directly to apply these renaming changes.
///
/// [appName] The new application name to set.
/// [packageName] The new package name (bundle ID) to set.
///
/// Throws an [Exception] if updating the config file fails
/// or if the package renaming process encounters an error.
Future<void> runRenamePackage({
  required String appName,
  required String packageName,
}) async {
  final clonifySettings = getClonifySettings();
  final renameConfigFile = File(Constants.packageRenameConfigFileName);
  final shortBundleName = shortIosBundleName(appName);
  final oldPackageName = readCurrentPackageName();
  final overrideOldPackage =
      oldPackageName != null && oldPackageName != packageName
      ? oldPackageName
      : null;

  logger.i('✅ Loading ${Constants.packageRenameConfigFileName}...');
  try {
    if (!renameConfigFile.existsSync()) {
      renameConfigFile.createSync(recursive: true);
      renameConfigFile.writeAsStringSync(
        _buildRenameConfigYaml(
          clonifySettings: clonifySettings,
          appName: appName,
          packageName: packageName,
          shortBundleName: shortBundleName,
          overrideOldPackage: overrideOldPackage,
        ),
      );
      logger.i('✅ Created default ${Constants.packageRenameConfigFileName}.');
    } else {
      _ensureRenameConfigSections(renameConfigFile, clonifySettings);
    }
    logger.i('✅ ${Constants.packageRenameConfigFileName} loaded successfully.');
  } on Exception catch (e) {
    logger.e('❌ Failed to create ${Constants.packageRenameConfigFileName}: $e');
    rethrow;
  }

  final yamlContent = renameConfigFile.readAsStringSync();
  final yamlEditor = YamlEditor(yamlContent);

  try {
    if (clonifySettings.updateAndroidInfo) {
      yamlEditor.update([
        'package_rename_config',
        'android',
        'app_name',
      ], appName);
      yamlEditor.update([
        'package_rename_config',
        'android',
        'package_name',
      ], packageName);
      yamlEditor.update([
        'package_rename_config',
        'android',
        'language',
      ], 'kotlin');
      _updateOptionalKey(yamlEditor, [
        'package_rename_config',
        'android',
        'override_old_package',
      ], overrideOldPackage);
    }

    if (clonifySettings.updateIOSInfo) {
      yamlEditor.update(['package_rename_config', 'ios', 'app_name'], appName);
      yamlEditor.update([
        'package_rename_config',
        'ios',
        'bundle_name',
      ], shortBundleName);
      yamlEditor.update([
        'package_rename_config',
        'ios',
        'package_name',
      ], packageName);
      _updateOptionalKey(yamlEditor, [
        'package_rename_config',
        'ios',
        'override_old_package',
      ], overrideOldPackage);
    }

    yamlEditor.update(['package_rename_config', 'web', 'app_name'], appName);
    yamlEditor.update([
      'package_rename_config',
      'web',
      'short_app_name',
    ], shortBundleName);
    yamlEditor.update(['package_rename_config', 'web', 'description'], appName);
    yamlEditor.update(['package_rename_config', 'linux', 'app_name'], appName);
    yamlEditor.update([
      'package_rename_config',
      'windows',
      'app_name',
    ], appName);

    renameConfigFile.writeAsStringSync(yamlEditor.toString());
    logger.i(
      '✅ Updated ${Constants.packageRenameConfigFileName} with app name "$appName" and package name "$packageName".',
    );
  } catch (e) {
    logger.e('❌ YAML update error: $e');
    throw Exception(
      '❌ Failed to update ${Constants.packageRenameConfigFileName}: $e',
    );
  }

  try {
    final args = <String>['--path', Constants.packageRenameConfigFileName];
    package_rename.set(args);
    logger.i('✅ Successfully renamed the package and app.');
  } catch (e) {
    logger.e('❌ Error during package renaming process: $e');
    rethrow;
  }
}

void _updateOptionalKey(
  YamlEditor yamlEditor,
  List<String> path,
  String? value,
) {
  if (value == null) {
    return;
  }
  yamlEditor.update(path, value);
}

void _ensureRenameConfigSections(
  File renameConfigFile,
  ClonifySettings clonifySettings,
) {
  final parsed = yaml.loadYaml(renameConfigFile.readAsStringSync());
  if (parsed is! yaml.YamlMap) {
    return;
  }

  final root = Map<String, dynamic>.from(parsed);
  final config = Map<String, dynamic>.from(
    root['package_rename_config'] as yaml.YamlMap? ?? yaml.YamlMap(),
  );

  var changed = false;
  if (clonifySettings.updateAndroidInfo && !config.containsKey('android')) {
    config['android'] = {
      'app_name': '',
      'package_name': '',
      'language': 'kotlin',
    };
    changed = true;
  }
  if (clonifySettings.updateIOSInfo && !config.containsKey('ios')) {
    config['ios'] = {'app_name': '', 'bundle_name': '', 'package_name': ''};
    changed = true;
  }
  if (!config.containsKey('web')) {
    config['web'] = {'app_name': '', 'short_app_name': '', 'description': ''};
    changed = true;
  }
  if (!config.containsKey('linux')) {
    config['linux'] = {'app_name': ''};
    changed = true;
  }
  if (!config.containsKey('windows')) {
    config['windows'] = {'app_name': ''};
    changed = true;
  }

  if (!changed) {
    return;
  }

  root['package_rename_config'] = config;
  renameConfigFile.writeAsStringSync(_mapToYaml(root));
}

String _buildRenameConfigYaml({
  required ClonifySettings clonifySettings,
  required String appName,
  required String packageName,
  required String shortBundleName,
  required String? overrideOldPackage,
}) {
  final buffer = StringBuffer('package_rename_config:\n');

  if (clonifySettings.updateAndroidInfo) {
    buffer.write('  android:\n');
    buffer.write('    app_name: "$appName"\n');
    buffer.write('    package_name: "$packageName"\n');
    buffer.write('    language: kotlin\n');
    if (overrideOldPackage != null) {
      buffer.write('    override_old_package: "$overrideOldPackage"\n');
    }
  }

  if (clonifySettings.updateIOSInfo) {
    buffer.write('  ios:\n');
    buffer.write('    app_name: "$appName"\n');
    buffer.write('    bundle_name: "$shortBundleName"\n');
    buffer.write('    package_name: "$packageName"\n');
    if (overrideOldPackage != null) {
      buffer.write('    override_old_package: "$overrideOldPackage"\n');
    }
  }

  buffer.write('  web:\n');
  buffer.write('    app_name: "$appName"\n');
  buffer.write('    short_app_name: "$shortBundleName"\n');
  buffer.write('    description: "$appName"\n');
  buffer.write('  linux:\n');
  buffer.write('    app_name: "$appName"\n');
  buffer.write('  windows:\n');
  buffer.write('    app_name: "$appName"\n');

  return buffer.toString();
}

String _mapToYaml(Map<String, dynamic> map, {int indent = 0}) {
  final buffer = StringBuffer();
  final prefix = ' ' * indent;

  for (final entry in map.entries) {
    final value = entry.value;
    if (value is Map) {
      buffer.writeln('$prefix${entry.key}:');
      buffer.write(
        _mapToYaml(Map<String, dynamic>.from(value), indent: indent + 2),
      );
    } else {
      buffer.writeln('$prefix${entry.key}: "$value"');
    }
  }

  return buffer.toString();
}

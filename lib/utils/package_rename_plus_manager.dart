// Package Rename Plus

import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/src/package_rename_plus/package_rename_plus.dart'
    as package_rename;
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Runs the `package_rename_plus` tool to rename the application and package.
///
/// This function first ensures that a `package_rename_config.yaml` file exists
/// and is properly configured with the provided [appName] and [packageName]
/// for both Android and iOS platforms. It then calls the internalized
/// package_rename_plus function directly to apply these renaming changes.
///
/// [appName] The new application name to set.
/// [packageName] The new package name (bundle ID) to set.
/// [configPath] Optional custom path to the config file.
///
/// Throws an [Exception] if updating the config file fails
/// or if the package renaming process encounters an error.
Future<void> runRenamePackage({
  required String appName,
  required String packageName,
}) async {
  final clonifySettings = getClonifySettings();

  // Step 1: Load and parse the YAML file
  final renameConfigFile = File(Constants.packageRenameConfigFileName);
  logger.i('✅ Loading ${Constants.packageRenameConfigFileName}...');
  // Create the config file if it does not exist
  try {
    if (!renameConfigFile.existsSync()) {
      renameConfigFile.createSync(recursive: true);

      // Build YAML content dynamically to avoid empty string indentation issues
      final yamlContent = StringBuffer('package_rename_config:\n');
      if (clonifySettings.updateAndroidInfo) {
        yamlContent.write(_getAndroidConfig());
      }
      if (clonifySettings.updateIOSInfo) {
        yamlContent.write(_getIOSConfig());
      }

      renameConfigFile.writeAsStringSync(yamlContent.toString());
      logger.i('✅ Created default ${Constants.packageRenameConfigFileName}.');
    }
    logger.i('✅ ${Constants.packageRenameConfigFileName} loaded successfully.');
  } on Exception catch (e) {
    logger.e('❌ Failed to create ${Constants.packageRenameConfigFileName}: $e');
    rethrow;
  }
  final yamlContent = renameConfigFile.readAsStringSync();
  final yamlEditor = YamlEditor(yamlContent);

  // Step 2: Update YAML file with new app name and package name
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
    }

    if (clonifySettings.updateIOSInfo) {
      yamlEditor.update(['package_rename_config', 'ios', 'app_name'], appName);
      yamlEditor.update([
        'package_rename_config',
        'ios',
        'bundle_name',
      ], packageName);
    }

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

  // Step 3: Run package rename directly (no external command!)
  try {
    // Pass config path as argument if provided
    final args = <String>['--path', Constants.packageRenameConfigFileName];
    package_rename.set(args);
    logger.i('✅ Successfully renamed the package and app.');
  } catch (e) {
    logger.e('❌ Error during package renaming process: $e');
    rethrow;
  }
}

String _getAndroidConfig() {
  return '''  android:
    app_name: ""
    package_name: ""
''';
}

String _getIOSConfig() {
  return '''  ios:
    app_name: ""
    bundle_name: ""
''';
}

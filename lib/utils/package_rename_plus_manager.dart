// Package Rename Plus

import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Runs the `package_rename_plus` tool to rename the application and package.
///
/// This function first ensures that a `package_rename_config.yaml` file exists
/// and is properly configured with the provided [appName] and [packageName]
/// for both Android and iOS platforms. It then executes the `dart run package_rename_plus`
/// command to apply these renaming changes to the Flutter project.
///
/// [appName] The new application name to set.
/// [packageName] The new package name (bundle ID) to set.
///
/// Throws an [Exception] if updating the `package_rename_config.yaml` file fails
/// or if the `package_rename_plus` command encounters an error.
Future<void> runRenamePackage({
  required String appName,
  required String packageName,
}) async {
  const renameConfigFilePath = 'package_rename_config.yaml';

  // Step 1: Load and parse the YAML file
  final renameConfigFile = File(renameConfigFilePath);

  // Create the config file if it does not exist
  if (!renameConfigFile.existsSync()) {
    renameConfigFile.createSync(recursive: true);
    renameConfigFile.writeAsStringSync('''
package_rename_config:
  android:
    app_name: ""
    package_name: ""
  ios:
    app_name: ""
    bundle_name: ""
''');
    logger.i('✅ Created default $renameConfigFilePath.');
  }
  final yamlContent = renameConfigFile.readAsStringSync();
  final yamlEditor = YamlEditor(yamlContent);

  // Step 2: Update YAML file with new app name and package name
  try {
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
    yamlEditor.update(['package_rename_config', 'ios', 'app_name'], appName);
    yamlEditor.update([
      'package_rename_config',
      'ios',
      'bundle_name',
    ], packageName);

    renameConfigFile.writeAsStringSync(yamlEditor.toString());
    logger.i(
      '✅ Updated $renameConfigFilePath with app name "$appName" and package name "$packageName".',
    );
  } catch (e) {
    throw Exception('❌ Failed to update $renameConfigFilePath: $e');
  }

  // Step 3: Run package_rename_plus command
  try {
    await runCommand('dart', [
      'run',
      'package_rename_plus',
    ], successMessage: '✅ Successfully renamed the package and app.');
  } catch (e) {
    logger.e('❌ Error during package renaming process: $e');
  }
}

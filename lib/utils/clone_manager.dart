// Clone Config Section
import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/models/config_model.dart';
import 'package:clonify/models/commands_calls_models/configure_command_model.dart';
import 'package:clonify/utils/asset_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/firebase_manager.dart';
import 'package:clonify/utils/package_rename_plus_manager.dart';
import 'package:yaml_edit/yaml_edit.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart' as yaml;

Future<void> generateCloneConfigFile(CloneConfigModel configModel) async {
  // 1. Check if the 'generated' directory exists
  final generatedDir = Directory('./lib/generated');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync(recursive: true);
    logger.i('Created "lib/generated" directory.');
  }

  // 2. Create 'clone_configs.dart' file
  final file = File('${generatedDir.path}/clone_configs.dart');
  final sink = file.openWrite();

  // 3. Write 'CloneConfigs' class
  sink.writeln(
    '// Auto-generated file. any changes will be overwritten. edit clone config instead.',
  );
  // sink.writeln("import 'package:flutter/material.dart';\n");
  sink.writeln('abstract class CloneConfigs {');

  // 3.1. Write colors
  for (var i = 0; i < (configModel.colors?.length ?? 0); i++) {
    final color = configModel.colors![i];
    sink.writeln('  static const ${color.name} = Color(0xFF${color.color});');
  }
  // 3.2. Write gradients
  for (var i = 0; i < (configModel.gradientsColors?.length ?? 0); i++) {
    final gradient = configModel.gradientsColors![i];
    sink.writeln(
      '  static const ${gradient.name} = LinearGradient('
      'colors: <Color>['
      '${gradient.colors?.map((color) => 'Color(0xFF$color)').join(', ')}'
      '],'
      'begin: Alignment.${gradient.begin},'
      'end: Alignment.${gradient.end},'
      'transform: GradientRotation(${gradient.transform})'
      ');',
    );
  }

  // 3.3 Write Base URL
  sink.writeln('  static const String baseUrl = "${configModel.baseUrl}";');
  // 3.4 Write Client ID
  sink.writeln('  static const String clientId = "${configModel.clientId}";');
  // 3.6 Write Version
  sink.writeln('  static const String version = "${configModel.version}";');
  // 3.7 Write Primary Color
  sink.writeln(
    '  static const String primaryColor = "${configModel.primaryColor}";',
  );

  // 4. Access the _assetTargetDirectory and for each file in that directory add its path
  // final assetsDirectory =
  //     Directory('./clonify/clones/${configModel.clientId}/assets');

  // if (assetsDirectory.existsSync()) {
  //   final assetFiles = assetsDirectory.listSync();
  //   for (final asset in assetFiles) {
  //     if (asset is File) {
  //       final assetFileName = asset.path.split(Platform.pathSeparator).last;
  //       // final variableName = path.withoutExtension(assetFileName).replaceAll(
  //       //     RegExp(r'\W+'), '_'); // Sanitize file names to valid variable names
  //       final variableName = assetFileName
  //           .replaceAll(RegExp(r'\W+'), '_')
  //           .replaceAll(RegExp(r'^\d+'),
  //               ''); // Sanitize file names to valid variable names
  //       sink.writeln(
  //           '  static const String $variableName = "${asset.path}$assetFileName";');
  //     }
  //   }
  // }

  sink.writeln('}');

  // Close the file stream
  sink.close();

  logger.i(
    'Generated clone_configs.dart file. You can find it in lib/generated/clone_configs.dart',
  );
}

/// Tracks created directories and files for cleanup on cancellation.
final List<String> _createdClonePaths = [];

/// Cleans up created clone files and directories.
void _cleanupCloneCreation() {
  for (final path in _createdClonePaths.reversed) {
    try {
      final entity = FileSystemEntity.typeSync(path);
      switch (entity) {
        case FileSystemEntityType.file:
          File(path).deleteSync();
          logger.i('🧹 Cleaned up file: $path');
          break;
        case FileSystemEntityType.directory:
          Directory(path).deleteSync(recursive: true);
          logger.i('🧹 Cleaned up directory: $path');
          break;
        default:
          break;
      }
    } catch (e) {
      logger.w('⚠️ Could not clean up $path: $e');
    }
  }
  _createdClonePaths.clear();
}

/// Prompts for clone basic information.
///
/// Returns a map with clone configuration or null if cancelled.
Map<String, String>? _promptCloneBasicInfo() {
  try {
    final clientId = prompt(
      'Enter Clone ID. This ID will be used to identify your project:',
    );

    final baseUrl = promptUser(
      'Enter the base URL (e.g., https://example.com):',
      'https://example.com',
      validator: (value) => Uri.parse(value).isAbsolute,
    );

    final primaryColor = promptUser(
      'Enter the primary color (e.g., 0xFFFFFFFF):',
      clonifySettings.defaultColor,
      validator: (value) => RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(value),
    );

    final packageName = promptUser(
      'Enter the package name (e.g., com.example.example):',
      'com.${clonifySettings.companyName}.${clientId.toLowerCase()}',
      validator: (value) =>
          RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$').hasMatch(value),
    );

    final appName = promptUser(
      'Enter the app name (e.g., Clone App):',
      toTitleCase(clientId),
      validator: (value) => value.isNotEmpty,
    );

    final version = promptUser(
      'Enter the app version (e.g., 1.0.0+1):',
      '1.0.0+1',
      validator: (value) => value.isNotEmpty,
    );
    String firebaseProjectId = '';
    if (clonifySettings.firebaseEnabled) {
      firebaseProjectId = promptUser(
        'Enter the Firebase project ID (e.g., my-project-id):',
        'firebase-$clientId-flutter',
      );
    }

    return {
      'clientId': clientId,
      'baseUrl': baseUrl,
      'primaryColor': primaryColor,
      'packageName': packageName,
      'appName': appName,
      'version': version,
      'firebaseProjectId': firebaseProjectId,
    };
  } catch (e) {
    logger.e('❌ Error during input collection: $e');
    return null;
  }
}

/// Creates the clone directory and config file.
///
/// Returns true if successful, false otherwise.
bool _createCloneStructure(Map<String, String> config) {
  try {
    final clientId = config['clientId']!;
    final cloneDir = Directory('./clonify/clones/$clientId');

    cloneDir.createSync(recursive: true);
    _createdClonePaths.add(cloneDir.path);

    final configFile = File('${cloneDir.path}/config.json');
    configFile.writeAsStringSync('''
{
  "clientId": "${config['clientId']}",
  "packageName": "${config['packageName']}",
  "appName": "${config['appName']}",
  "baseUrl": "${config['baseUrl']}",
  "primaryColor": "${config['primaryColor']}",
  "firebaseProjectId": "${config['firebaseProjectId']}",
  "version": "${config['version']}"
}
''');
    _createdClonePaths.add(configFile.path);

    logger.i('✅ Config file created at: ${configFile.path}');
    return true;
  } catch (e) {
    logger.e('❌ Failed to create clone structure: $e');
    return false;
  }
}

/// Handles the rename and Firebase setup process.
///
/// Returns true if successful, false otherwise.
Future<bool> _setupCloneServices(Map<String, String> config) async {
  try {
    final doRename = prompt(
      'Do you want to rename the app with ${config['appName']} and package with ${config['packageName']}? (y/n):',
    );

    if (doRename.toLowerCase() == 'y') {
      await runRenamePackage(
        appName: config['appName']!,
        packageName: config['packageName']!,
      );
    } else {
      logger.i('🚀 Skipping renaming process...');
    }

    if (clonifySettings.firebaseEnabled) {
      await createFirebaseProject(
        clientId: config['clientId']!,
        packageName: config['packageName']!,
        firebaseProjectId: config['firebaseProjectId']!,
      );
    }

    createAssetsDirectory(config['clientId']!);
    return true;
  } catch (e) {
    logger.e('❌ Error during service setup: $e');
    return false;
  }
}

/// Creates a new project clone with cancellation support.
///
/// If the user cancels during the process, any created directories
/// and files will be automatically cleaned up.
Future<void> createClone() async {
  logger.i('🛠 Creating a new project clone...');

  try {
    // Step 1: Collect clone configuration
    final config = _promptCloneBasicInfo();
    if (config == null) {
      logger.w('⚠️ Clone creation cancelled by user');
      _cleanupCloneCreation();
      return;
    }

    // Step 2: Create directory structure and config file
    if (!_createCloneStructure(config)) {
      _cleanupCloneCreation();
      return;
    }

    // Step 3: Setup services (rename, Firebase, assets)
    if (!await _setupCloneServices(config)) {
      _cleanupCloneCreation();
      return;
    }

    // Success!
    logger.i('🎉 Clone successfully created for ${config['clientId']}!');
    logger.i(
      '🚀 Run "clonify configure --clientId ${config['clientId']}" to generate this clone.',
    );

    // Clear tracking list on successful completion
    _createdClonePaths.clear();
  } catch (e) {
    logger.e('❌ Error during clone creation: $e');
    _cleanupCloneCreation();
    rethrow;
  }
}

/// Handles the initial setup steps (renaming and Firebase).
///
/// Returns true if successful, false otherwise.
Future<bool> _performInitialSetup(
  ConfigureCommandModel callModel,
  Map<String, dynamic> configJson,
) async {
  try {
    // Step 1: Rename app name and package
    await runRenamePackage(
      appName: configJson['appName'],
      packageName: configJson['packageName'],
    );

    if (callModel.isDebug) {
      return true; // Early return for debug mode
    }

    // Step 2: Create Firebase project and enable FCM
    if (clonifySettings.firebaseEnabled) {
      await addFirebaseToApp(
        packageName: configJson['packageName'],
        firebaseProjectId: configJson['firebaseProjectId'],
        skip: callModel.skipAll || callModel.skipFirebaseConfigure,
      );
    }

    // Step 3: Replace assets
    replaceAssets(callModel.clientId!);
    return true;
  } catch (e) {
    logger.e('❌ Error during initial setup: $e');
    return false;
  }
}

/// Gets the current version from pubspec.yaml.
///
/// Returns the version string or null if an error occurs.
String? _getCurrentPubspecVersion() {
  const pubspecFilePath = './pubspec.yaml';
  try {
    final pubspecContent = File(pubspecFilePath).readAsStringSync();
    final pubspecMap = yaml.loadYaml(pubspecContent);
    return pubspecMap['version'] ?? 'Unknown Version';
  } catch (e) {
    logger.e('❌ Failed to read or parse $pubspecFilePath: $e');
    return null;
  }
}

/// Handles version management logic.
///
/// Returns the final version or null if process should be cancelled.
Future<String?> _handleVersionManagement(
  ConfigureCommandModel callModel,
  Map<String, dynamic> configJson,
) async {
  final yamlVersion = _getCurrentPubspecVersion();
  if (yamlVersion == null) return null;

  String configVersion = configJson['version'] ?? '';

  // Handle missing config version
  if (configVersion.isEmpty) {
    configVersion = promptUser(
      'Config file does not have a version parameter. Enter a new version or use the default (1.0.0+1):',
      '1.0.0+1',
      validator: (value) => RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(value),
      skipValue: '1.0.0+1',
      skip: callModel.skipAll || callModel.skipVersionUpdate,
    );
    configJson['version'] = configVersion;
    await File(
      './clonify/clones/${callModel.clientId}/config.json',
    ).writeAsString(jsonEncode(configJson));
  }

  // Sync pubspec version with config
  if (yamlVersion != configVersion) {
    final updateYamlVersionAnswer = prompt(
      'Version in pubspec.yaml ($yamlVersion) is different from config file ($configVersion). Do you want to update pubspec.yaml with the config version? (y/n):',
      skip: callModel.skipAll || callModel.skipPubUpdate,
      skipValue: 'y',
    );

    if (updateYamlVersionAnswer.toLowerCase() == 'y') {
      await updateYamlVersionInPubspec(configVersion);
    }
  }

  // Handle version updates
  final changeVersionAnswer = prompt(
    'Do you want to update the version number ($configVersion)? (y/n):',
    skip: callModel.skipVersionUpdate,
    skipValue: callModel.autoUpdate ? 'y' : 'No',
  );

  if (changeVersionAnswer.toLowerCase() == 'y') {
    final newVersion = promptUser(
      'Enter the new version number:',
      configVersion,
      validator: (value) => RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(value),
      skipValue: versionNumberIncrementor(configVersion),
      skip: callModel.autoUpdate,
    );
    await updateYamlVersionInPubspec(newVersion);
    configJson['version'] = newVersion;
    await File(
      './clonify/clones/${callModel.clientId}/config.json',
    ).writeAsString(jsonEncode(configJson));
    return newVersion;
  }

  return configVersion;
}

/// Runs Flutter build commands and generates configuration.
///
/// Returns true if successful, false otherwise.
Future<bool> _configureLauncherIconsAndSplashScreen(
  Map<String, dynamic> configJson,
) async {
  try {
    const flutterLauncherIconsPath = 'flutter_launcher_icons.yaml';
    const flutterNativeSplashPath = 'flutter_native_splash.yaml';

    // Step 1: Load and parse the YAML files
    final launcherIconsConfigFile = File(flutterLauncherIconsPath);
    final nativeSplashConfigFile = File(flutterNativeSplashPath);

    // Create the config files if it does not exist
    if (!launcherIconsConfigFile.existsSync()) {
      launcherIconsConfigFile.createSync(recursive: true);
      launcherIconsConfigFile.writeAsStringSync(
        Constants.flutterLauncherIconsYaml,
      );
      logger.i(
        '✅ Created $flutterLauncherIconsPath. you can modify it for customization.',
      );
    }
    if (!nativeSplashConfigFile.existsSync()) {
      nativeSplashConfigFile.createSync(recursive: true);
      nativeSplashConfigFile.writeAsStringSync(
        Constants.flutterNativeSplashYaml,
      );
      logger.i(
        '✅ Created $flutterNativeSplashPath. you can modify it for customization.',
      );
    }
    final launcherIconsYamlContent = launcherIconsConfigFile.readAsStringSync();
    final launcherIconsYamlEditor = YamlEditor(launcherIconsYamlContent);
    final nativeSplashYamlContent = nativeSplashConfigFile.readAsStringSync();
    final nativeSplashYamlEditor = YamlEditor(nativeSplashYamlContent);

    // Step 2: Update YAML files with new app name and package name
    try {
      launcherIconsYamlEditor.update([
        'flutter_launcher_icons',
        'image_path',
      ], "assets/images/${clonifySettings.launcherIconAsset}");
      launcherIconsYamlEditor.update([
        'flutter_launcher_icons',
        'adaptive_icon_foreground',
      ], "assets/images/${clonifySettings.launcherIconAsset}");
      launcherIconsConfigFile.writeAsStringSync(
        launcherIconsYamlEditor.toString(),
      );
      logger.i('✅ Updated $flutterLauncherIconsPath with launcher icon asset');
    } catch (e) {
      logger.e('❌ Error updating $flutterLauncherIconsPath: $e');
    }
    if (clonifySettings.splashScreenAsset != null) {
      try {
        nativeSplashYamlEditor.update([
          'flutter_native_splash',
          'image',
        ], "assets/images/${clonifySettings.splashScreenAsset}");
        nativeSplashConfigFile.writeAsStringSync(
          nativeSplashYamlEditor.toString(),
        );
        logger.i('✅ Updated $flutterNativeSplashPath with splash screen asset');
      } catch (e) {
        logger.e('❌ Error updating $flutterNativeSplashPath: $e');
      }
    } else {
      logger.i(
        'No splash screen asset provided. Skipping update of $flutterNativeSplashPath',
      );
    }

    // Step 3: Run build commands
    await runCommand('dart', [
      'run',
      'flutter_launcher_icons',
    ], successMessage: '✅ Flutter launcher icons generated successfully!');

    if (clonifySettings.splashScreenAsset != null) {
      await runCommand(
        'dart',
        ['run', 'flutter_native_splash:create'],
        successMessage: '✅ Flutter native splash screen created successfully!',
      );
    }

    await runCommand('dart', [
      'run',
      'intl_utils:generate',
    ], successMessage: '✅ Intl utils generated successfully!');

    generateCloneConfigFile(CloneConfigModel.fromJson(configJson));
    return true;
  } catch (e) {
    logger.e('❌ Error during build commands: $e');
    return false;
  }
}

/// Configures an application clone with cancellation support.
///
/// This function performs the complete configuration process including:
/// - Renaming app and package
/// - Setting up Firebase
/// - Replacing assets
/// - Managing versions
/// - Running build commands
///
/// Returns the configuration JSON if successful, null if cancelled or failed.
Future<Map<String, dynamic>?> configureApp(
  ConfigureCommandModel callModel,
) async {
  saveLastClientId(callModel.clientId!);
  logger.i('🚀 Starting cloning process for client: ${callModel.clientId}');

  try {
    // Parse configuration file
    final Map<String, dynamic> configJson = await parseConfigFile(
      callModel.clientId!,
    );

    // Step 1: Perform initial setup (rename, Firebase, assets)
    if (!await _performInitialSetup(callModel, configJson)) {
      return null;
    }

    if (callModel.isDebug) {
      return {}; // Return empty map for debug mode
    }

    // Step 2: Handle version management
    final finalVersion = await _handleVersionManagement(callModel, configJson);
    if (finalVersion == null) {
      return null;
    }

    // Step 3: Run build commands
    if (!await _configureLauncherIconsAndSplashScreen(configJson)) {
      return null;
    }

    logger.i('✅ Successfully cloned app for ${callModel.clientId}!');
    return configJson;
  } catch (e) {
    logger.e('❌ Error during cloning: $e');
    rethrow;
  }
}

Future<void> updateYamlVersionInPubspec(String newVersion) async {
  const pubspecFilePath = './pubspec.yaml';
  final pubspecContent = File(pubspecFilePath).readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);
  yamlEditor.update(['version'], newVersion);
  File(pubspecFilePath).writeAsStringSync(yamlEditor.toString());
  logger.i('✅ Updated version in pubspec.yaml to $newVersion');
}

Future<void> cleanupPartialClone(String clientId) async {
  final cloneDir = Directory('./clonify/clones/$clientId');
  if (cloneDir.existsSync()) {
    cloneDir.deleteSync(recursive: true);
    logger.i('🧹 Partial clone cleaned up for $clientId.');
  }
}

Future<void> getCurrentCloneConfig() async {
  try {
    // Run 'rename getAppName'
    final ProcessResult appNameResult = await Process.run('dart', [
      'run',
      'rename',
      'getAppName',
    ], runInShell: true);

    // Run 'rename getBundleId'
    final ProcessResult bundleIdResult = await Process.run('dart', [
      'run',
      'rename',
      'getBundleId',
    ], runInShell: true);

    // Check and print the results
    if (appNameResult.stderr.toString().isNotEmpty) {
      logger.e('❌ Error getting app name: ${appNameResult.stderr}');
    } else {
      logger.i('App Name:\n${appNameResult.stdout}');
    }

    if (bundleIdResult.stderr.toString().isNotEmpty) {
      logger.e('❌ Error getting bundle ID: ${bundleIdResult.stderr}');
    } else {
      logger.i('Bundle ID:\n${bundleIdResult.stdout}');
    }
  } catch (e) {
    logger.e('❌ Error getting current clone config: $e');
  }
}

Future<Map<String, dynamic>> parseConfigFile(String clientId) async {
  final configFile = File('./clonify/clones/$clientId/config.json');

  if (!configFile.existsSync()) {
    throw FileSystemException(
      'Config file not found for $clientId',
      configFile.path,
    );
  }

  final content = await configFile.readAsString();
  final config = jsonDecode(content) as Map<String, dynamic>;

  logger.i('📄 Loaded configuration:');
  logger.i('App Name: ${config['appName']}');
  logger.i('Primary Color: ${config['primaryColor']}');
  // logger.i('Base URL: ${config['baseUrl']}');

  return config;
}

void listClients() {
  logger.i('📋 Listing all Currently Available clients...');
  final dir = Directory('./clonify/clones');
  if (!dir.existsSync()) {
    logger.i('No clients found.');
    return;
  }

  // Column Widths (adjust as needed)
  int clientIdWidth = 15;
  int appNameWidth = 20;
  int firebaseProjectIdWidth = 30;
  const int versionWidth = 10;

  final List<Map<String, String>> clientsData = [];

  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      final configFile = File('${entity.path}/config.json');
      if (configFile.existsSync()) {
        try {
          final content = jsonDecode(configFile.readAsStringSync());
          final clientId = content['clientId'] ?? '';
          final appName = content['appName'] ?? '';
          final firebaseProjectId = content['firebaseProjectId'] ?? '';
          final version = content['version']?.toString() ?? 'N/A';

          //adjust column widths
          clientIdWidth = clientId.length > clientIdWidth
              ? clientId.length
              : clientIdWidth;
          appNameWidth = appName.length > appNameWidth
              ? appName.length
              : appNameWidth;
          firebaseProjectIdWidth =
              firebaseProjectId.length > firebaseProjectIdWidth
              ? firebaseProjectId.length
              : firebaseProjectIdWidth;

          clientsData.add({
            'clientId': clientId,
            'appName': appName,
            'firebaseProjectId': firebaseProjectId,
            'version': version,
          });
        } catch (e) {
          // Handle JSON parsing error
          logger.e('❌ Error parsing config file: $e');
        }
      }
    }
  }

  if (clientsData.isEmpty) {
    logger.i('No clients found.');
    return;
  }

  // Print Table Header
  logger.i(
    '\n+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+',
  );
  logger.i(
    '| ${'Client ID'.padRight(clientIdWidth)}|'
    ' ${'App Name'.padRight(appNameWidth)}|'
    ' ${'Firebase Project ID'.padRight(firebaseProjectIdWidth)}|'
    ' ${'Version'.padRight(versionWidth)}|',
  );
  logger.i(
    '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+',
  );

  // Print Table Rows
  for (final client in clientsData) {
    logger.i(
      '| ${client['clientId']!.padRight(clientIdWidth)}|'
      ' ${client['appName']!.padRight(appNameWidth)}|'
      ' ${client['firebaseProjectId']!.padRight(firebaseProjectIdWidth)}|'
      ' ${client['version']!.padRight(versionWidth)}|',
    );
  }

  logger.i(
    '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+',
  );
}

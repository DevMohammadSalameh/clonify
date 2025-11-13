// Clone Config Section
import 'dart:convert';
import 'dart:io';

import 'package:chalkdart/chalk.dart';
import 'package:clonify/constants.dart';
import 'package:clonify/models/config_model.dart';
import 'package:clonify/models/commands_calls_models/configure_command_model.dart';
import 'package:clonify/utils/asset_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/firebase_manager.dart';
import 'package:clonify/utils/package_rename_plus_manager.dart';
import 'package:clonify/utils/tui_helpers.dart';
import 'package:yaml_edit/yaml_edit.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart' as yaml;

/// Generates the `clone_configs.dart` file based on the provided [configModel].
///
/// This function creates or updates `lib/generated/clone_configs.dart`,
/// which contains static constants for various configuration parameters
/// such as colors, gradients, base URL, client ID, version, primary color,
/// and custom fields. This file allows Flutter applications to access
/// clone-specific configurations at compile time.
///
/// [configModel] The [CloneConfigModel] containing the configuration data
///                to be written to the generated file.
///
/// Throws a [FileSystemException] if the 'generated' directory cannot be created
/// or the 'clone_configs.dart' file cannot be written.
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

  // 3.8 Write Custom Fields (if any exist in clonifySettings)
  if (clonifySettings.customFields.isNotEmpty) {
    // Read the config file to get custom field values
    final configPath = './clonify/clones/${configModel.clientId}/config.json';
    final configFile = File(configPath);
    if (configFile.existsSync()) {
      final configJson =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;

      for (final field in clonifySettings.customFields) {
        final value = configJson[field.name];
        if (value != null) {
          // Generate the constant based on type
          switch (field.type) {
            case 'int':
              sink.writeln('  static const int ${field.name} = $value;');
              break;
            case 'double':
              sink.writeln('  static const double ${field.name} = $value;');
              break;
            case 'bool':
              sink.writeln('  static const bool ${field.name} = $value;');
              break;
            case 'string':
            default:
              sink.writeln('  static const String ${field.name} = "$value";');
              break;
          }
        }
      }
    }
  }

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
    infoMessage('\n📦 Creating New Clone Configuration');
    infoMessage('Please provide the following information:\n');

    final clientId = promptUserTUI(
      '🆔 Enter Clone ID (used to identify your project)',
      '',
      validator: (value) {
        if (value.trim().isEmpty) {
          errorMessage('Clone ID cannot be empty');
          return false;
        }
        return true;
      },
    );

    final baseUrl = promptUserTUI(
      '🌐 Enter the base URL (e.g., https://example.com OR "no" for no base URL)',
      '',
      validator: (value) {
        if (value.trim() == 'no') {
          infoMessage('No base URL will be used');
          return true;
        }
        if (!Uri.parse(value).isAbsolute) {
          errorMessage('Invalid URL format. Must be an absolute URL.');
          return false;
        }
        return true;
      },
    );

    final primaryColor = promptUserTUI(
      '🎨 Enter the primary color (hex format: 0xAARRGGBB)',
      clonifySettings.defaultColor,
      validator: (value) {
        if (!RegExp(r'^0x[0-9a-fA-F]{8}$').hasMatch(value)) {
          errorMessage(
            'Invalid color format. Use 0xAARRGGBB (e.g., 0xAAFFFFFF)',
          );
          return false;
        }
        return true;
      },
    );

    final packageName = promptUserTUI(
      '📦 Enter the package name (e.g., com.example.app)',
      'com.${clonifySettings.companyName}.${clientId.toLowerCase()}',
      validator: (value) {
        if (!RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$').hasMatch(value)) {
          errorMessage('Invalid package name format. Use com.company.app');
          return false;
        }
        return true;
      },
    );

    final appName = promptUserTUI(
      '📱 Enter the app name (e.g., My App)',
      toTitleCase(clientId),
      validator: (value) {
        if (value.isEmpty) {
          errorMessage('App name cannot be empty');
          return false;
        }
        return true;
      },
    );

    final version = promptUserTUI(
      '🔢 Enter the app version (e.g., 1.0.0+1)',
      '1.0.0+1',
      validator: (value) {
        if (!RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(value)) {
          errorMessage('Invalid version format. Use X.Y.Z+B (e.g., 1.0.0+1)');
          return false;
        }
        return true;
      },
    );

    String firebaseProjectId = '';
    if (clonifySettings.firebaseEnabled) {
      firebaseProjectId = promptUserTUI(
        '🔥 Enter the Firebase project ID (e.g., my-project-id)',
        'firebase-$clientId-flutter',
      );
    }

    // Prompt for custom fields if any are defined
    final configMap = <String, String>{
      'clientId': clientId,
      'baseUrl': baseUrl,
      'primaryColor': primaryColor,
      'packageName': packageName,
      'appName': appName,
      'version': version,
      'firebaseProjectId': firebaseProjectId,
    };

    if (clonifySettings.needsLauncherIcon) {
      final launcherIcon = promptUserTUI(
        '🎯 Enter the launcher icon filename (e.g., icon.png)',
        '',
        validator: (value) {
          if (value.trim().isEmpty) {
            errorMessage('Launcher icon filename cannot be empty');
          } else if (!File('assets/images/$value').existsSync()) {
            errorMessage(
              'Launcher icon file does not exist at assets/images/$value',
            );
            return false;
          }
          return true;
        },
      );
      configMap['launcherIcon'] = launcherIcon;
    }

    if (clonifySettings.needsSplashScreen) {
      final splashScreen = promptUserTUI(
        '🎯 Enter the splash screen filename (e.g., splash.png)',
        '',
        validator: (value) {
          if (value.trim().isEmpty) {
            errorMessage('Splash screen filename cannot be empty');
          } else if (!File('assets/images/$value').existsSync()) {
            errorMessage(
              'Splash screen file does not exist at assets/images/$value',
            );
            return false;
          }
          return true;
        },
      );
      configMap['splashScreen'] = splashScreen;
    }

    if (clonifySettings.needsLogo) {
      final logo = promptUserTUI(
        '🎯 Enter the logo filename (e.g., logo.png)',
        'logo.png',
        validator: (value) {
          if (value.trim().isEmpty) {
            errorMessage('Logo filename cannot be empty');
          } else if (!File('assets/images/$value').existsSync()) {
            errorMessage('Logo file does not exist at assets/images/$value');
            return false;
          }
          return true;
        },
      );
      configMap['logo'] = logo;
    }

    if (clonifySettings.customFields.isNotEmpty) {
      infoMessage('\n⚙️  Custom Configuration Fields:');
      for (final field in clonifySettings.customFields) {
        final value = promptUserTUI(
          '🔧 Enter value for "${field.name}" (type: ${field.type})',
          '',
          validator: (value) {
            if (value.trim().isEmpty) {
              errorMessage('Value cannot be empty');
              return false;
            }
            switch (field.type) {
              case 'int':
                if (int.tryParse(value) == null) {
                  errorMessage('Must be a valid integer number');
                  return false;
                }
                return true;
              case 'double':
                if (double.tryParse(value) == null) {
                  errorMessage('Must be a valid decimal number');
                  return false;
                }
                return true;
              case 'bool':
                if (value.toLowerCase() != 'true' &&
                    value.toLowerCase() != 'false') {
                  errorMessage('Must be either "true" or "false"');
                  return false;
                }
                return true;
              case 'string':
              default:
                return true;
            }
          },
        );
        configMap['custom_${field.name}'] = value;
        successMessage('Set ${field.name} = $value');
      }
    }

    // Display configuration summary
    infoMessage('\n📋 Configuration Summary:');
    infoMessage('  🆔 Client ID: ${configMap['clientId']}');
    infoMessage('  🌐 Base URL: ${configMap['baseUrl']}');
    infoMessage('  🎨 Primary Color: ${configMap['primaryColor']}');
    infoMessage('  📦 Package: ${configMap['packageName']}');
    infoMessage('  📱 App Name: ${configMap['appName']}');
    infoMessage('  🔢 Version: ${configMap['version']}');
    if (firebaseProjectId.isNotEmpty) {
      infoMessage('  🔥 Firebase: $firebaseProjectId');
    }

    return configMap;
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

    // Build config JSON dynamically to include custom fields
    final configJson = <String, dynamic>{
      'clientId': config['clientId'],
      'packageName': config['packageName'],
      'appName': config['appName'],
      'baseUrl': config['baseUrl'],
      'primaryColor': config['primaryColor'],
      'firebaseProjectId': config['firebaseProjectId'],
      'version': config['version'],
      'launcherIcon': config['launcherIcon'],
      'splashScreen': config['splashScreen'],
      'logo': config['logo'],
    };

    // Add custom fields to config
    for (final key in config.keys) {
      if (key.startsWith('custom_')) {
        final fieldName = key.substring(7); // Remove 'custom_' prefix
        configJson[fieldName] = config[key];
      }
    }

    final configFile = File('${cloneDir.path}/config.json');
    configFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(configJson),
    );
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

    return true;
  } catch (e) {
    logger.e('❌ Error during service setup: $e');
    return false;
  }
}

/// Initiates the process of creating a new Flutter project clone.
///
/// This function guides the user through collecting basic clone information,
/// creating the necessary directory structure and configuration files,
/// and setting up associated services like package renaming and Firebase.
///
/// It includes robust cancellation support: if the user cancels at any stage
/// or an error occurs, any files or directories created during the process
/// will be automatically cleaned up to maintain a clean state.
///
/// Throws an [Exception] if an unhandled error occurs during the clone creation process.
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

    // Step 4: Create assets directory
    if (!createCloneAssetsDirectory(config['clientId']!, [
      config['launcherIcon']!,
      config['splashScreen']!,
      config['logo']!,
    ])) {
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
    final renameProgress = progressWithTUI(
      '📦 Renaming package to ${configJson['packageName']}...',
    );
    await runRenamePackage(
      appName: configJson['appName'],
      packageName: configJson['packageName'],
    );
    renameProgress?.complete('Package renamed successfully');

    if (callModel.isDebug) {
      return true; // Early return for debug mode
    }

    // Step 2: Create Firebase project and enable FCM
    if (clonifySettings.firebaseEnabled) {
      final firebaseProgress = progressWithTUI(
        '🔥 Configuring Firebase for ${configJson['firebaseProjectId']}...',
      );
      await addFirebaseToApp(
        packageName: configJson['packageName'],
        firebaseProjectId: configJson['firebaseProjectId'],
        skip: callModel.skipAll || callModel.skipFirebaseConfigure,
      );
      firebaseProgress?.complete('Firebase configured successfully');
    }

    // Step 3: Replace assets
    // final assetsProgress = progressWithTUI('🎨 Replacing client assets...');
    // replaceAssets(callModel.clientId!);
    // assetsProgress?.complete('Assets replaced successfully');

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
    // Step 1: Load and parse the YAML files
    final launcherIconsConfigFile = File(Constants.flutterLauncherIconsPath);
    final nativeSplashConfigFile = File(Constants.flutterNativeSplashPath);

    // Create the config files if it does not exist
    if (!launcherIconsConfigFile.existsSync()) {
      launcherIconsConfigFile.createSync(recursive: true);
      launcherIconsConfigFile.writeAsStringSync(
        Constants.flutterLauncherIconsYaml,
      );
      logger.i(
        '✅ Created ${Constants.flutterLauncherIconsPath}. you can modify it for customization.',
      );
    }
    if (!nativeSplashConfigFile.existsSync()) {
      nativeSplashConfigFile.createSync(recursive: true);
      nativeSplashConfigFile.writeAsStringSync(
        Constants.flutterNativeSplashYaml,
      );
      logger.i(
        '✅ Created ${Constants.flutterNativeSplashPath}. you can modify it for customization.',
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
      ], "assets/images/${configJson['launcherIcon']}");
      launcherIconsYamlEditor.update([
        'flutter_launcher_icons',
        'adaptive_icon_foreground',
      ], "assets/images/${configJson['launcherIcon']}");
      launcherIconsConfigFile.writeAsStringSync(
        launcherIconsYamlEditor.toString(),
      );
      logger.i(
        '✅ Updated ${Constants.flutterLauncherIconsPath} with launcher icon asset',
      );
    } catch (e) {
      logger.e('❌ Error updating ${Constants.flutterLauncherIconsPath}: $e');
    }
    if (configJson['splashScreen'] != null) {
      try {
        nativeSplashYamlEditor.update([
          'flutter_native_splash',
          'image',
        ], "assets/images/${configJson['splashScreen']}");
        nativeSplashConfigFile.writeAsStringSync(
          nativeSplashYamlEditor.toString(),
        );
        logger.i(
          '✅ Updated ${Constants.flutterNativeSplashPath} with splash screen asset',
        );
      } catch (e) {
        logger.e('❌ Error updating ${Constants.flutterNativeSplashPath}: $e');
      }
    } else {
      logger.i(
        'No splash screen asset provided. Skipping update of ${Constants.flutterNativeSplashPath}',
      );
    }

    // Step 3: Check for dependencies and run build commands
    final pubspecFile = File(Constants.pubspecFilePath);
    if (!pubspecFile.existsSync()) {
      logger.w(
        '⚠️ ${Constants.pubspecFilePath} not found, skipping package commands.',
      );
      return true;
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspecYaml = yaml.loadYaml(pubspecContent);
    final dependencies = pubspecYaml['dependencies'] as yaml.YamlMap?;
    final devDependencies = pubspecYaml['dev_dependencies'] as yaml.YamlMap?;

    // Helper function to check if a package exists in dependencies
    bool hasPackage(String packageName) {
      return (dependencies != null && dependencies.containsKey(packageName)) ||
          (devDependencies != null && devDependencies.containsKey(packageName));
    }

    // Run flutter_launcher_icons if available
    if (hasPackage('flutter_launcher_icons')) {
      final iconProgress = progressWithTUI('🚀 Generating launcher icons...');
      await runCommand('dart', [
        'run',
        'flutter_launcher_icons',
      ], successMessage: '✅ Flutter launcher icons generated successfully!');
      iconProgress?.complete('Launcher icons generated');
    } else {
      logger.w(
        '⚠️ `flutter_launcher_icons` not found in your pubspec.yaml.\n'
        '   Add it to dev_dependencies to generate launcher icons:\n'
        '   dev_dependencies:\n'
        '     flutter_launcher_icons: ^0.13.1',
      );
    }

    // Run flutter_native_splash if splash screen is configured and package is available
    if (configJson['splashScreen'] != null) {
      if (hasPackage('flutter_native_splash')) {
        final splashProgress = progressWithTUI('💦 Creating splash screen...');
        await runCommand(
          'dart',
          ['run', 'flutter_native_splash:create'],
          successMessage:
              '✅ Flutter native splash screen created successfully!',
        );
        splashProgress?.complete('Splash screen created');
      } else {
        logger.w(
          '⚠️ `flutter_native_splash` not found in your pubspec.yaml.\n'
          '   Add it to dev_dependencies to generate splash screens:\n'
          '   dev_dependencies:\n'
          '     flutter_native_splash: ^2.3.1',
        );
      }
    }

    // Run intl_utils if available
    if (hasPackage('intl_utils')) {
      final intlProgress = progressWithTUI(
        '🌍 Generating internationalization files...',
      );
      await runCommand('dart', [
        'run',
        'intl_utils:generate',
      ], successMessage: '✅ Intl utils generated successfully!');
      intlProgress?.complete('Internationalization files generated');
    } else {
      logger.w(
        '⚠️ `intl_utils` not found in your pubspec.yaml, skipping `intl_utils:generate` command.',
      );
    }

    generateCloneConfigFile(CloneConfigModel.fromJson(configJson));
    return true;
  } catch (e) {
    logger.e('❌ Error during build commands: $e');
    return false;
  }
}

/// Configures an application clone based on a provided [ConfigureCommandModel].
///
/// This function orchestrates the entire configuration process for a specific
/// client ID, including:
/// - Saving the last used client ID.
/// - Parsing the client's configuration file.
/// - Performing initial setup steps (package renaming, Firebase integration, asset replacement).
/// - Managing and updating application versions.
/// - Running necessary build commands for launcher icons and splash screens.
///
/// It provides robust error handling and ensures that the process can be
/// controlled by various flags within the [callModel].
///
/// [callModel] A [ConfigureCommandModel] containing the client ID and
///             various configuration flags.
///
/// Returns a `Future<Map<String, dynamic>?>` representing the final
/// configuration JSON if successful, or `null` if the process is cancelled
/// or fails at any stage.
///
/// Throws an [Exception] if an unhandled error occurs during the configuration process.
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

/// Updates the 'version' field in the `pubspec.yaml` file.
///
/// This function reads the `pubspec.yaml` file, updates its 'version' field
/// to the [newVersion] using `yaml_edit`, and then writes the modified
/// content back to the file.
///
/// [newVersion] The new version string to set in `pubspec.yaml`.
///
/// Throws a [FileSystemException] if the `pubspec.yaml` file cannot be read or written.
/// Throws a [YamlException] if the `pubspec.yaml` content is invalid.
Future<void> updateYamlVersionInPubspec(String newVersion) async {
  final pubspecFilePath = Constants.pubspecFilePath;
  final pubspecContent = File(pubspecFilePath).readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);
  yamlEditor.update(['version'], newVersion);
  File(pubspecFilePath).writeAsStringSync(yamlEditor.toString());
  logger.i('✅ Updated version in ${Constants.pubspecFilePath} to $newVersion');
}

/// Cleans up a partial or broken clone by removing its associated directory.
///
/// This function deletes the entire directory corresponding to the specified
/// [clientId] within the `./clonify/clones/` path. This is useful for
/// removing incomplete or problematic clone setups.
///
/// [clientId] The ID of the client whose clone directory should be removed.
///
/// Throws a [FileSystemException] if the directory exists but cannot be deleted.
Future<void> cleanupPartialClone(String clientId) async {
  final cloneDir = Directory('./clonify/clones/$clientId');
  if (cloneDir.existsSync()) {
    cloneDir.deleteSync(recursive: true);
    logger.i('🧹 Partial clone cleaned up for $clientId.');
  }
}

/// Retrieves and displays the currently active application's name and bundle ID.
///
/// This function executes `dart run rename getAppName` and `dart run rename getBundleId`
/// to fetch the current application name and bundle ID of the Flutter project.
/// It then prints these details to the console.
///
/// Throws an [Exception] if there's an error executing the `rename` commands.
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

/// Parses the configuration file for a specific client ID.
///
/// This function reads the `config.json` file located in the
/// `./clonify/clones/[clientId]/` directory, decodes its JSON content,
/// and returns it as a map. It also logs some key configuration details.
///
/// [clientId] The ID of the client whose configuration file is to be parsed.
///
/// Throws a [FileSystemException] if the configuration file does not exist.
/// Throws a [FormatException] if the file content is not valid JSON.
///
/// Returns a `Future<Map<String, dynamic>>` representing the parsed configuration.
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

/// Lists all currently available Clonify project clones.
///
/// This function scans the `./clonify/clones` directory, reads the `config.json`
/// file for each found client, and then prints a formatted table displaying
/// the Client ID, App Name, Firebase Project ID, and Version for each clone.
///
/// If no clones are found or if there are errors parsing configuration files,
/// appropriate messages are logged.
void listClients() async {
  infoMessage('\n📋 Available Clones');

  final dir = Directory('./clonify/clones');
  if (!dir.existsSync()) {
    warningMessage('No clones directory found.');
    infoMessage(
      'Run "clonify init" to initialize, then "clonify create" to create your first clone.',
    );
    return;
  }

  // Get last active client
  final lastClientId = await getLastClientId();

  // Column Widths (adjust as needed)
  int clientIdWidth = 15;
  int appNameWidth = 20;
  int firebaseProjectIdWidth = 30;
  const int versionWidth = 12;

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

          // Adjust column widths
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
          errorMessage('Error parsing config file: $e');
        }
      }
    }
  }

  if (clientsData.isEmpty) {
    warningMessage('No clones found.');
    infoMessage('Create your first clone with: clonify create');
    return;
  }

  // Print styled table header
  if (isTUIEnabled()) {
    final chalk = Chalk();
    final headerLine =
        '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 10)}+';
    print(chalk.cyan(headerLine));

    final header =
        '| '
        '${'🆔 Client ID'.padRight(clientIdWidth + 2)}| '
        '${'📱 App Name'.padRight(appNameWidth + 2)}| '
        '${'🔥 Firebase'.padRight(firebaseProjectIdWidth + 2)}| '
        '${'🔢 Version'.padRight(versionWidth + 2)}|';
    print(chalk.cyan.bold(header));
    print(chalk.cyan(headerLine));
  } else {
    // Basic table for non-TUI mode
    final headerLine =
        '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+';
    logger.i('\n$headerLine');
    logger.i(
      '| ${'Client ID'.padRight(clientIdWidth)}|'
      ' ${'App Name'.padRight(appNameWidth)}|'
      ' ${'Firebase Project ID'.padRight(firebaseProjectIdWidth)}|'
      ' ${'Version'.padRight(versionWidth)}|',
    );
    logger.i(headerLine);
  }

  // Print table rows with highlighting for active client
  for (final client in clientsData) {
    final isActive = client['clientId'] == lastClientId;
    final row =
        '| '
        '${client['clientId']!.padRight(clientIdWidth)}| '
        '${client['appName']!.padRight(appNameWidth)}| '
        '${(client['firebaseProjectId'] ?? '').padRight(firebaseProjectIdWidth)}| '
        '${client['version']!.padRight(versionWidth)}|';

    if (isTUIEnabled()) {
      final chalk = Chalk();
      if (isActive) {
        print(chalk.green.bold('▶ ${row.substring(2)}'));
      } else {
        print(chalk.white('  $row'));
      }
    } else {
      if (isActive) {
        logger.i('▶ $row');
      } else {
        logger.i(row);
      }
    }
  }

  // Print table footer
  if (isTUIEnabled()) {
    final chalk = Chalk();
    final footerLine =
        '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 10)}+';
    print(chalk.cyan(footerLine));
  } else {
    final footerLine =
        '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+';
    logger.i(footerLine);
  }

  // Display summary
  final totalClones = clientsData.length;
  if (isTUIEnabled()) {
    print('');
    if (lastClientId != null) {
      successMessage('📌 Active Clone: $lastClientId');
    }
    infoMessage('📊 Total Clones: $totalClones');
  } else {
    logger.i('');
    if (lastClientId != null) {
      logger.i('Active client: $lastClientId');
    }
    logger.i('Total clients: $totalClones');
  }
}

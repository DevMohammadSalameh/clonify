// Clone Config Section
import 'dart:convert';
import 'dart:io';

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
  sink.writeln('// Auto-generated file. Do not edit manually.');
  sink.writeln("import 'package:flutter/material.dart';\n");
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

  logger.i('Generated clone_configs.dart file.');
}

Future<void> createClone() async {
  logger.i('🛠 Creating a new project clone...');

  // Step 1: Prompt user for inputs
  final clientId = prompt(
    'Enter Clone ID. This ID will be used to identify your project:',
  );

  final primaryColor = promptUser(
    'Enter the primary color (e.g., 0xFFFFFFFF):',
    '0xFF3EA7E1',
    validator: (value) => RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(value),
  );

  final packageName = promptUser(
    'Enter the package name (e.g., com.example.example):',
    // 'com.${clientId.toLowerCase()}.${clientId.toLowerCase()}hr',
    'com.natejsoft.${clientId.toLowerCase()}hr',
    validator: (value) =>
        RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$').hasMatch(value),
  );

  final appName = promptUser(
    'Enter the app name (e.g., Clone App):',
    '${toTitleCase(clientId)} HR',
    validator: (value) => value.isNotEmpty,
  );

  final version = promptUser(
    'Enter the app version (e.g., 1.0.0+1):',
    '1.0.0+1',
    validator: (value) => value.isNotEmpty,
  );

  final cloneDir = Directory('./clonify/clones/$clientId');
  cloneDir.createSync(recursive: true);

  final firebaseProjectId = promptUser(
    'Enter the Firebase project ID (e.g., my-project-id):',
    'firebase-$clientId-flutter',
  );

  final configFile = File('${cloneDir.path}/config.json');

  await configFile.writeAsString('''
{
  "clientId": "$clientId",
  "packageName": "$packageName",
  "appName": "$appName",
  "primaryColor": "$primaryColor",
  "firebaseProjectId": "$firebaseProjectId",
  "version": "$version"
}
''');

  logger.i('✅ Config file created at: ${configFile.path}');

  // Step 3: Create Firebase project and configure
  try {
    final doRename = prompt(
      'Do you want to rename the app with $appName and package with $packageName? (y/n):',
    );
    if (doRename.toLowerCase() == 'y') {
      await runRenamePackage(appName: appName, packageName: packageName);
    } else {
      logger.i('🚀 Skipping renaming process...');
    }

    await createFirebaseProject(
      clientId: clientId,
      packageName: packageName,
      firebaseProjectId: firebaseProjectId,
    );

    createAssetsDirectory(clientId);

    logger.i('🎉 Clone successfully created for $clientId!');
    logger.i(
      '🚀 Run "clonify configure --clientId $clientId" to generate this clone.',
    );
    // logger.i('Dont forget to add the assets to the assets folder');
  } catch (e) {
    logger.e('❌ Error during clone creation: $e');
  }
}

Future<Map<String, dynamic>?> configureApp(
  ConfigureCommandModel callModel,
) async {
  logger.i('🚀 Starting cloning process for client: ${callModel.clientId}');

  try {
    final Map<String, dynamic> configJson = await parseConfigFile(
      callModel.clientId!,
    );

    // Step 1: Rename app name and package
    await runRenamePackage(
      appName: configJson['appName'],
      packageName: configJson['packageName'],
    );
    if (callModel.isDebug) {
      final Map<String, dynamic> temp = {};
      return temp;
    }
    // Step 2: Create Firebase project and enable FCM
    await addFirebaseToApp(
      packageName: configJson['packageName'],
      firebaseProjectId: configJson['firebaseProjectId'],
      skip: callModel.skipAll || callModel.skipFirebaseConfigure,
    );

    // Step 3: Replace assets
    replaceAssets(callModel.clientId!);

    // Step 4: Check and update version
    const pubspecFilePath = './pubspec.yaml';
    String yamlVersion;
    try {
      final pubspecContent = File(pubspecFilePath).readAsStringSync();
      final pubspecMap = yaml.loadYaml(pubspecContent);
      yamlVersion = pubspecMap['version'] ?? 'Unknown Version';
    } catch (e) {
      logger.e('❌ Failed to read or parse $pubspecFilePath: $e');
      return null;
    }

    String configVersion = configJson['version'] ?? '';
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

    if (yamlVersion != configVersion) {
      final String updateYamlVersionAnswer = prompt(
        'Version in pubspec.yaml ($yamlVersion) is different from config file ($configVersion). Do you want to update pubspec.yaml with the config version? (y/n):',
        skip: callModel.skipAll || callModel.skipPubUpdate,
        skipValue: 'y',
      );

      if (updateYamlVersionAnswer.toLowerCase() == 'y') {
        await updateYamlVersionInPubspec(configVersion);
      }
    }

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
    }

    // Step 5: run flutter_launcher_icons
    try {
      await runCommand('dart', [
        'run',
        'flutter_launcher_icons',
      ], successMessage: '✅ Flutter launcher icons generated successfully!');

      // Step 6: run flutter_native_splash
      await runCommand(
        'dart',
        ['run', 'flutter_native_splash:create'],
        successMessage: '✅ Flutter native splash screen created successfully!',
      );

      // Step 7: run intl_utils:generate
      await runCommand('dart', [
        'run',
        'intl_utils:generate',
      ], successMessage: '✅ Intl utils generated successfully!');

      generateCloneConfigFile(CloneConfigModel.fromJson(configJson));
    } catch (e) {
      logger.e('❌ Error during Flutter launcher icons generation: $e');
    }

    logger.i('✅ Successfully cloned app for ${callModel.clientId}!');
    return configJson; // Return the parsed configuration
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

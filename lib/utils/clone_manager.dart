part of 'clonify_helpers.dart';

// Clone Config Section
Future<void> generateCloneConfigFile(CloneConfigModel configModel) async {
  // 1. Check if the 'generated' directory exists
  final generatedDir = Directory('./lib/generated');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync(recursive: true);
    print('Created "lib/generated" directory.');
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
    sink.writeln('  static const ${gradient.name} = LinearGradient('
        'colors: <Color>['
        '${gradient.colors?.map((color) => 'Color(0xFF$color)').join(', ')}'
        '],'
        'begin: Alignment.${gradient.begin},'
        'end: Alignment.${gradient.end},'
        'transform: GradientRotation(${gradient.transform})'
        ');');
  }

  // 3.3 Write Base URL
  sink.writeln('  static const String baseUrl = "${configModel.baseUrl}";');
  // 3.4 Write Client ID
  sink.writeln('  static const String clientId = "${configModel.clientId}";');
  // 3.6 Write Version
  sink.writeln('  static const String version = "${configModel.version}";');
  // 3.7 Write Primary Color
  sink.writeln(
      '  static const String primaryColor = "${configModel.primaryColor}";');

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

  print('Generated clone_configs.dart file.');
}

Future<void> createClone() async {
  print('🛠 Creating a new project clone...');

  // Step 1: Prompt user for inputs
  final clientId =
      prompt('Enter Clone ID. This ID will be used to identify your project:');

  final primaryColor = promptUser(
      'Enter the primary color (e.g., 0xFFFFFFFF):', '0xFF3EA7E1',
      validator: (value) => RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(value));

  final packageName = promptUser(
      'Enter the package name (e.g., com.example.example):',
      // 'com.${clientId.toLowerCase()}.${clientId.toLowerCase()}hr',
      'com.natejsoft.${clientId.toLowerCase()}hr',
      validator: (value) =>
          RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$').hasMatch(value));

  final appName = promptUser(
      'Enter the app name (e.g., Clone App):', '${toTitleCase(clientId)} HR',
      validator: (value) => value.isNotEmpty);

  final version = promptUser(
      'Enter the app version (e.g., 1.0.0+1):', '1.0.0+1',
      validator: (value) => value.isNotEmpty);

  final cloneDir = Directory('./clonify/clones/$clientId');
  cloneDir.createSync(recursive: true);

  final firebaseProjectId = promptUser(
      'Enter the Firebase project ID (e.g., my-project-id):',
      'firebase-$clientId-flutter');

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

  print('✅ Config file created at: ${configFile.path}');

  // Step 3: Create Firebase project and configure
  try {
    final doRename = prompt(
        'Do you want to rename the app with $appName and package with $packageName? (y/n):');
    if (doRename.toLowerCase() == 'y') {
      await runRenamePackage(
        appName: appName,
        packageName: packageName,
      );
    } else {
      print('🚀 Skipping renaming process...');
    }

    await createFirebaseProject(
      clientId: clientId,
      packageName: packageName,
      firebaseProjectId: firebaseProjectId,
    );

    createAssetsDirectory(clientId);

    print('🎉 Clone successfully created for $clientId!');
    print(
        '🚀 Run "clonify configure --clientId $clientId" to generate this clone.');
    // print('Dont forget to add the assets to the assets folder');
  } catch (e) {
    print('❌ Error during clone creation: $e');
  }
}

Future<Map<String, dynamic>?> configureApp(List<String> args) async {
  final clientId = _getArgValue(args, '--clientId');
  print('🚀 Starting cloning process for client: $clientId');

  try {
    final Map<String, dynamic> configJson = await parseConfigFile(clientId);
    // final isDebug = args.any((arg) => arg == '--debug' || arg == '-D');
    // Step 1: Rename app name and package
    await runRenamePackage(
      appName: configJson['appName'],
      packageName: configJson['packageName'],
    );
    // if (isDebug) {
    //   final Map<String, dynamic> temp = {};
    //   return temp;
    // }
    // Step 2: Create Firebase project and enable FCM
    await addFirebaseToApp(
      packageName: configJson['packageName'],
      firebaseProjectId: configJson['firebaseProjectId'],
      skip: args.any((arg) =>
          arg == '--skip-firebase-configure' ||
          arg == '-SF' ||
          arg == '--skip-all' ||
          arg == '-SA'),
    );

    // Step 3: Replace assets
    replaceAssets(clientId);

    // Step 4: Check and update version
    const pubspecFilePath = './pubspec.yaml';
    String yamlVersion;
    try {
      final pubspecContent = File(pubspecFilePath).readAsStringSync();
      final pubspecMap = loadYaml(pubspecContent);
      yamlVersion = pubspecMap['version'] ?? 'Unknown Version';
    } catch (e) {
      print('❌ Failed to read or parse $pubspecFilePath: $e');
      return null;
    }

    String configVersion = configJson['version'] ?? '';
    if (configVersion.isEmpty) {
      configVersion = promptUser(
        'Config file does not have a version parameter. Enter a new version or use the default (1.0.0+1):',
        '1.0.0+1',
        validator: (value) => RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(value),
        skipValue: '1.0.0+1',
        skip: args.any((arg) =>
            arg == '--skip-version' ||
            arg == '-SV' ||
            arg == '--skip-all' ||
            arg == '-SA'),
      );
      configJson['version'] = configVersion;
      await File('./clonify/clones/$clientId/config.json')
          .writeAsString(jsonEncode(configJson));
    }

    if (yamlVersion != configVersion) {
      final skipPubUpdate = args.any((arg) =>
          arg == '--skip-pub-update' ||
          arg == '-SPU' ||
          arg == '--skip-all' ||
          arg == '-SA');

      final String updateYamlVersionAnswer = prompt(
        'Version in pubspec.yaml ($yamlVersion) is different from config file ($configVersion). Do you want to update pubspec.yaml with the config version? (y/n):',
        skip: skipPubUpdate,
        skipValue: 'y',
      );

      if (updateYamlVersionAnswer.toLowerCase() == 'y') {
        await updateYamlVersionInPubspec(configVersion);
      }
    }

    final skipVersionUpdate = args.any((arg) =>
        arg == '--skip-version-update' ||
        arg == '-SVU' ||
        arg == '--skip-all' ||
        arg == '-SA');

    final autoUpdate =
        args.any((arg) => arg == '--auto-update' || arg == '-AU');
    final changeVersionAnswer = prompt(
      'Do you want to update the version number ($configVersion)? (y/n):',
      skip: skipVersionUpdate,
      skipValue: autoUpdate ? 'y' : 'No',
    );
    if (changeVersionAnswer.toLowerCase() == 'y') {
      final newVersion = promptUser(
        'Enter the new version number:',
        configVersion,
        validator: (value) => RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(value),
        skipValue: versionNumberIncrementor(configVersion),
        skip: autoUpdate,
      );
      await updateYamlVersionInPubspec(newVersion);
      configJson['version'] = newVersion;
      await File('./clonify/clones/$clientId/config.json')
          .writeAsString(jsonEncode(configJson));
    }

    // Step 5: run flutter_launcher_icons
    try {
      await runCommand(
        'dart',
        ['run', 'flutter_launcher_icons'],
        successMessage: '✅ Flutter launcher icons generated successfully!',
      );

      // Step 6: run flutter_native_splash
      await runCommand(
        'dart',
        ['run', 'flutter_native_splash:create'],
        successMessage: '✅ Flutter native splash screen created successfully!',
      );

      // Step 7: run intl_utils:generate
      await runCommand(
        'dart',
        ['run', 'intl_utils:generate'],
        successMessage: '✅ Intl utils generated successfully!',
      );

      generateCloneConfigFile(CloneConfigModel.fromJson(configJson));
    } catch (e) {
      print('❌ Error during Flutter launcher icons generation: $e');
    }

    print('✅ Successfully cloned app for $clientId!');
    return configJson; // Return the parsed configuration
  } catch (e) {
    print('❌ Error during cloning: $e');
    rethrow;
  }
}

Future<void> updateYamlVersionInPubspec(String newVersion) async {
  const pubspecFilePath = './pubspec.yaml';
  final pubspecContent = File(pubspecFilePath).readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);
  yamlEditor.update(['version'], newVersion);
  File(pubspecFilePath).writeAsStringSync(yamlEditor.toString());
  print('✅ Updated version in pubspec.yaml to $newVersion');
}

Future<void> cleanupPartialClone(String clientId) async {
  final cloneDir = Directory('./clonify/clones/$clientId');
  if (cloneDir.existsSync()) {
    cloneDir.deleteSync(recursive: true);
    print('🧹 Partial clone cleaned up for $clientId.');
  }
}

Future<void> buildApps(String clientId, List<String> args) async {
  final configFilePath = './clonify/clones/$clientId/config.json';
  const pubspecFilePath = './pubspec.yaml';

  // Check if config.json exists
  final configFile = File(configFilePath);
  if (!configFile.existsSync()) {
    print('❌ Config file not found for client ID: $clientId');
    print('Please run "clonify configure --clientId $clientId" first.');
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
    print('❌ Failed to read or parse $configFilePath: $e');
    return;
  }

  // Read pubspec.yaml to get the version
  String version;
  try {
    final pubspecContent = File(pubspecFilePath).readAsStringSync();
    final pubspecMap = loadYaml(pubspecContent);
    version = pubspecMap['version'] ?? 'Unknown Version';
  } catch (e) {
    print('❌ Failed to read or parse $pubspecFilePath: $e');
    return;
  }

  //change bundleId in xcode project
  // _changeBundleIdInXcodeProject(bundleId: packageName);

  final skipBuildCheck = args.any((arg) =>
      arg == '--skip-build-check' ||
      arg == '-SBC' ||
      arg == '--skip-all' ||
      arg == '-SA');
  // Update prompt message with packageName, appName, and version
  final answer = prompt(
    ' Have you verified the Bundle ID ($packageName) and App Name ($appName) in the Xcode project, with the version [$version]? (y/n):',
    skip: skipBuildCheck,
    skipValue: 'y',
  );
  if (answer.toLowerCase() != 'y') {
    print('❌ Please verify the Bundle ID and App Name in the Xcode project.');
    return;
  }

  print('🚀 Building apps for client ID: $clientId');

  // Start a stopwatch to track total build time
  final stopwatch = Stopwatch()..start();

  // Periodically display a loading message with the elapsed time
  final progress = Stream.periodic(const Duration(milliseconds: 100), (count) {
    stdout.write(
        '\r🛠 Apps are being built... [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]');
  });
  final progressSubscription = progress.listen((_) {});

  try {
    // Run all commands in parallel
    await Future.wait([
      runCommand(
        'flutter',
        ['build', 'apk', '--release'],
        successMessage: '✅ Android application is built successfully!',
        showLoading: false,
      ),
      runCommand(
        'flutter',
        ['build', 'aab', '--release'],
        successMessage: '✅ Android app bundle is built successfully!',
        showLoading: false,
      ),
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
    print(
        '✓ You can find the iOS app archive at\n  ${'-' * 10}→ build/ios/archive/Runner.xcarchive');
    print(
        '✓ You can find the Android app bundle at\n  ${'-' * 10}→ build/app/outputs/bundle/release/app-release.aab');
    // Display the total build time
    print(
        '✅ Apps built successfully for client ID: $clientId in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.');
  } catch (e) {
    // Stop the progress display and print the error
    progressSubscription.cancel();
    stdout.write('\r'); // Clear the line
    print('❌ Error during app build: $e');
  } finally {
    stopwatch.stop();
  }

  // Upload apps
  final skipAndroidUploadCheck = args.any((arg) =>
      arg == '--upload-all' ||
      arg == '-UALL' ||
      arg == '--upload-android' ||
      arg == '-UA');
  final uploadAndroid = prompt(
    'Do you want to upload the Android AAB? (y/n):',
    skip: skipAndroidUploadCheck,
    skipValue: 'y',
  );
  if (uploadAndroid.toLowerCase() == 'y') {
    // 1. Update android/fastlane/Fastfile variables with packageName, version, etc.
    updateFastlaneFiles(
      fastlanePath: 'android/fastlane/Fastfile',
      bundleId: packageName,
      appVersion: version.split('+').first,
      appVersionCode: version.split('+').last,
    );
    // 2. Run "fastlane upload" in android folder
    await runCommand(
      'fastlane',
      ['upload'],
      workingDirectory: 'android',
      successMessage: '✅ Uploaded Android build!',
    );
  }

  final skipIOSUploadCheck = args.any((arg) =>
      arg == '--upload-all' ||
      arg == '-UALL' ||
      arg == '--upload-ios' ||
      arg == '-UI');
  final uploadIOS = prompt(
    'Do you want to upload the iOS IPA? (y/n):',
    skip: skipIOSUploadCheck,
    skipValue: 'y',
  );
  if (uploadIOS.toLowerCase() == 'y') {
    // 1. Update ios/fastlane/Fastfile variables (bundleId, app_version)
    updateFastlaneFiles(
      fastlanePath: 'ios/fastlane/Fastfile',
      bundleId: packageName,
      appVersion: version,
    );
    // 2. Run "fastlane upload" in ios folder
    await runCommand(
      'fastlane',
      ['upload'],
      workingDirectory: 'ios',
      successMessage: '✅ Uploaded iOS build!',
    );
  }
}

Future<void> updateFastlaneFiles({
  required String fastlanePath,
  required String bundleId,
  required String appVersion,
  String? appVersionCode,
}) async {
  // Function to replace variables in Fastlane files
  Future<void> updateFile(
      String filePath, Map<String, String> replacements) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('❌ Fastlane file not found: $filePath');
      return;
    }

    String content = file.readAsStringSync();
    replacements.forEach((key, value) {
      content = content.replaceAll(RegExp(key), value);
    });

    file.writeAsStringSync(content);
    print('✅ Updated $filePath');
  }

  // Define replacement mappings
  final Map<String, String> replacements = {
    r'bundleId = ".*?"': 'bundleId = "$bundleId"',
    r'app_version = ".*?"': 'app_version = "$appVersion"',
    r'app_version_code = ".*?"': 'app_version_code = "$appVersionCode"',
  };

  // Update Fastlane file
  await updateFile(fastlanePath, replacements);
}

Future<void> getCurrentCloneConfig() async {
  try {
    // Run 'rename getAppName'
    final ProcessResult appNameResult = await Process.run(
      'dart',
      ['run', 'rename', 'getAppName'],
      runInShell: true,
    );

    // Run 'rename getBundleId'
    final ProcessResult bundleIdResult = await Process.run(
      'dart',
      ['run', 'rename', 'getBundleId'],
      runInShell: true,
    );

    // Check and print the results
    if (appNameResult.stderr.toString().isNotEmpty) {
      print('❌ Error getting app name: ${appNameResult.stderr}');
    } else {
      print('App Name:\n${appNameResult.stdout}');
    }

    if (bundleIdResult.stderr.toString().isNotEmpty) {
      print('❌ Error getting bundle ID: ${bundleIdResult.stderr}');
    } else {
      print('Bundle ID:\n${bundleIdResult.stdout}');
    }
  } catch (e) {
    print('❌ Error getting current clone config: $e');
  }
}

Future<Map<String, dynamic>> parseConfigFile(String clientId) async {
  final configFile = File('./clonify/clones/$clientId/config.json');

  if (!configFile.existsSync()) {
    throw FileSystemException(
        'Config file not found for $clientId', configFile.path);
  }

  final content = await configFile.readAsString();
  final config = jsonDecode(content) as Map<String, dynamic>;

  print('📄 Loaded configuration:');
  print('App Name: ${config['appName']}');
  print('Primary Color: ${config['primaryColor']}');
  // print('Base URL: ${config['baseUrl']}');

  return config;
}

void listClients() {
  print('📋 Listing all Currently Available clients...');
  final dir = Directory('./clonify/clones');
  if (!dir.existsSync()) {
    print('No clients found.');
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
          clientIdWidth =
              clientId.length > clientIdWidth ? clientId.length : clientIdWidth;
          appNameWidth =
              appName.length > appNameWidth ? appName.length : appNameWidth;
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
          print('❌ Error parsing config file: $e');
        }
      }
    }
  }

  if (clientsData.isEmpty) {
    print('No clients found.');
    return;
  }

  // Print Table Header
  print(
      '\n+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+');
  print('| ${'Client ID'.padRight(clientIdWidth)}|'
      ' ${'App Name'.padRight(appNameWidth)}|'
      ' ${'Firebase Project ID'.padRight(firebaseProjectIdWidth)}|'
      ' ${'Version'.padRight(versionWidth)}|');
  print(
      '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+');

  // Print Table Rows
  for (final client in clientsData) {
    print('| ${client['clientId']!.padRight(clientIdWidth)}|'
        ' ${client['appName']!.padRight(appNameWidth)}|'
        ' ${client['firebaseProjectId']!.padRight(firebaseProjectIdWidth)}|'
        ' ${client['version']!.padRight(versionWidth)}|');
  }

  print(
      '+${'─' * (clientIdWidth + appNameWidth + firebaseProjectIdWidth + versionWidth + 7)}+');
}

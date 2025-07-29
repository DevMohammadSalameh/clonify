import 'dart:convert';
import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart' as yaml;

const lastClientFilePath = './clonify/last_client.txt';
const lastConfigFilePath = './clonify/last_config.json';

Future<void> saveLastClientId(String clientId) async {
  final file = File(lastClientFilePath);
  await file.writeAsString(clientId);
}

Future<String?> getLastClientId() async {
  final file = File(lastClientFilePath);
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  return null;
}

Future<void> saveLastConfig(Map<String, dynamic> config) async {
  final file = File('./clonify/last_config.json');
  await file.writeAsString(jsonEncode(config));
}

Future<Map<String, dynamic>?> getLastConfig() async {
  final file = File(lastConfigFilePath);
  if (file.existsSync()) {
    return jsonDecode(await file.readAsString());
  }
  return null;
}

Future<String?> getClientIdFromArgsOrLast(List<String> args) async {
  String? clientId =
      getArgumentValue(args, '--clientId') ??
      getArgumentValue(args, '-id') ??
      getArgumentValue(args, '--clientId');
  if (getArgumentValue(args, '--clientId') != null) {
    // I added this case because i have typed it wrong multiple times
    print(
      ' [!] Typo in argument name. Use "--clientId" instead of "--clientId" next time.',
    );
  }

  if (clientId == null) {
    final lastConfig = await getLastConfig();
    if (lastConfig != null) {
      clientId = lastConfig['clientId'];
      final answer = prompt(
        'No client ID provided. Use last configured client ID "$clientId"? (y/n):',
      );
      if (answer.toLowerCase() != 'y') {
        throw Exception('Client ID is required.');
      }
    } else {
      throw Exception(
        'No client ID provided and no last configured client found.',
      );
    }
  }
  return clientId;
}

/// Initializes the Clonify environment by performing the following steps:
///
/// - Checks for the existence of the `clonify` directory and creates it if it does not exist.
/// - Checks for the existence of the `clonify_settings.yaml` file inside the `clonify` directory.
///   - If the file does not exist, creates it with default settings for Firebase, Fastlane, company name, and default color.
///   - If the file exists, calls `validatedClonifySettings()` to validate the settings.
///
/// The initialization process includes prompts for enabling Firebase and Fastlane services,
/// specifying their respective settings files, entering the company name (used for package naming),
/// and setting the default app color.
Future<void> initClonify() async {
  final clonifyDir = Directory('./clonify');
  if (!clonifyDir.existsSync()) {
    clonifyDir.createSync(recursive: true);
    print('✅ Created clonify directory at ${clonifyDir.path}.');
  }

  final settingsFile = File('./clonify/clonify_settings.yaml');
  if (!settingsFile.existsSync()) {
    settingsFile.createSync(recursive: true);

    final bool enableFirebase =
        promptUser('Do you want to enable Firebase? (y/n)', 'n') == 'y';
    String firebaseSettingsFilePath = '';
    if (enableFirebase) {
      firebaseSettingsFilePath = promptUser(
        'Enter Firebase settings file path:',
        '',
        validator: (value) {
          if (value.isEmpty) {
            print('❌ Firebase settings file path cannot be empty.');
            return false;
          }
          if (!File(value).existsSync()) {
            print('❌ Firebase settings file does not exist at $value.');
            return false;
          }
          return true;
        },
      );
    }
    final bool enableFastlane =
        promptUser('Do you want to enable Fastlane? (y/n)', 'n') == 'y';

    String fastlaneSettingsFilePath = '';
    if (enableFastlane) {
      fastlaneSettingsFilePath = promptUser(
        'Enter Fastlane settings file path:',
        '',
        validator: (value) {
          if (value.isEmpty) {
            print('❌ Fastlane settings file path cannot be empty.');
            return false;
          } else if (!File(value).existsSync()) {
            print('❌ Fastlane settings file does not exist at $value.');
            return false;
          }
          return true;
        },
      );
    }
    final String companyName = promptUser(
      'Enter your company name:',
      '',
      validator: (value) {
        if (value.isEmpty) {
          print('❌ Company name cannot be empty.');
          return false;
        }
        return true;
      },
    );
    final String defaultColor = promptUser(
      'Enter default app color (hex format, e.g., #FFFFFF):',
      '#FFFFFF',
      //check for valid hex color
      validator: (value) {
        if (RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$').hasMatch(value)) {
          return true;
        }
        print('Invalid hex color format. Use #FFFFFF or #FFF.');
        return false;
      },
    );

    settingsFile.writeAsStringSync('''
# Clonify Settings
firebase:
  enabled: $enableFirebase
  settings_file: "${enableFirebase ? firebaseSettingsFilePath : ''}"
  
fastlane:
  enabled: $enableFastlane
  settings_file: "${enableFastlane ? fastlaneSettingsFilePath : ''}"
company_name: "$companyName"

default_color: "$defaultColor"
''');
    print('✅ Created default clonify_settings.yaml at ${settingsFile.path}.');
  } else {
    print('ℹ️ clonify_settings.yaml already exists at ${settingsFile.path}.');
    validatedClonifySettings();
  }
}

/// Validates the `clonify_settings.yaml` configuration file.
///
/// This function checks for the existence and correctness of the
/// `clonify_settings.yaml` file in the `./clonify/` directory. It ensures:
/// - The file exists and is not empty.
/// - The YAML content is valid and can be parsed.
/// - All required fields (`firebase`, `fastlane`, `company_name`, `default_color`)
///   are present and have the correct types.
/// - The `firebase` and `fastlane` fields contain `enabled` (bool) and
///   `settings_file` (string) subfields.
/// - The `company_name` field is a non-empty string.
/// - The `default_color` field is a valid hex color string (e.g., `#FFFFFF`).
///
/// Prints error messages for any validation failures.
///
/// Returns `true` if the settings file is valid, otherwise `false`.

bool validatedClonifySettings([bool isSilent = true]) {
  final settingsFile = File('./clonify/clonify_settings.yaml');
  if (!settingsFile.existsSync()) {
    print('❌ clonify_settings.yaml not found. Please run "clonify init".');
    return false;
  }

  final content = settingsFile.readAsStringSync();
  if (content.isEmpty) {
    print('❌ clonify_settings.yaml is empty. Please run "clonify init".');
    return false;
  }

  // Parse YAML content
  dynamic rawSettings;
  try {
    rawSettings = yaml.loadYaml(content);
  } catch (e) {
    print('❌ Failed to parse clonify_settings.yaml: $e');
    return false;
  }

  // Convert YamlMap to Map<String, dynamic>
  Map<String, dynamic> settings = {};
  if (rawSettings is Map) {
    rawSettings.forEach((key, value) {
      settings[key.toString()] = value is yaml.YamlMap
          ? Map<String, dynamic>.from(value)
          : value;
    });
  } else {
    print('❌ clonify_settings.yaml does not contain a valid map.');
    return false;
  }
  // Required fields and their types
  final requiredFields = {
    'firebase': yaml.YamlMap,
    'fastlane': yaml.YamlMap,
    'company_name': String,
    'default_color': String,
  };

  for (final field in requiredFields.keys) {
    if (!rawSettings.containsKey(field)) {
      print('❌ Missing required field: $field');
      return false;
    }
    if (rawSettings[field] == null ||
        rawSettings[field].runtimeType != requiredFields[field]) {
      print(
        '❌ Field "$field" has invalid type ${rawSettings[field].runtimeType}. Expected ${requiredFields[field]}.',
      );
      return false;
    }
  }

  // Check firebase and fastlane subfields
  for (final service in ['firebase', 'fastlane']) {
    final serviceSettings = rawSettings[service];
    if (!serviceSettings.containsKey('enabled') ||
        serviceSettings['enabled'] is! bool) {
      print('❌ "$service.enabled" must be a boolean.');
      return false;
    }
    if (!serviceSettings.containsKey('settings_file') ||
        serviceSettings['settings_file'] is! String) {
      print('❌ "$service.settings_file" must be a string.');
      return false;
    }
  }

  // Check company_name
  if ((rawSettings['company_name'] as String).trim().isEmpty) {
    print('❌ "company_name" cannot be empty.');
    return false;
  }

  // Check default_color is a valid hex color
  final color = rawSettings['default_color'] as String;
  final hexColorRegExp = RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$');
  if (!hexColorRegExp.hasMatch(color)) {
    print('❌ "default_color" must be a valid hex color (e.g., #FFFFFF).');
    return false;
  }
  if (!isSilent) {
    print('✅ clonify_settings.yaml is valid.');
  }

  return true;
}

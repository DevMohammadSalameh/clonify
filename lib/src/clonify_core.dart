import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/messages.dart';
import 'package:clonify/models/clonify_settings_model.dart';
import 'package:clonify/utils/clonify_helpers.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart' as yaml;

const lastClientFilePath = './clonify/last_client.txt';
const lastConfigFilePath = './clonify/last_config.json';

Future<void> saveLastClientId(String clientId) async {
  final file = File(lastClientFilePath);
  await file.writeAsString(clientId);
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
    logger.w(
      'Typo in argument name. Use "--clientId" instead of "--clientId" next time.',
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

/// Tracks created files and directories for cleanup on cancellation.
final List<String> _createdPaths = [];

/// Cleans up created files and directories.
void _cleanupCreatedPaths() {
  for (final path in _createdPaths.reversed) {
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
  _createdPaths.clear();
}

/// Creates the clonify directory if it doesn't exist.
///
/// Returns true if directory was created or already exists, false on error.
bool _ensureClonifyDirectory() {
  final clonifyDir = Directory('./clonify');
  if (!clonifyDir.existsSync()) {
    try {
      clonifyDir.createSync(recursive: true);
      _createdPaths.add(clonifyDir.path);
      logger.i('✅ Created clonify directory at ${clonifyDir.path}.');
    } catch (e) {
      logger.e('❌ Failed to create clonify directory: $e');
      return false;
    }
  }
  return true;
}

/// Prompts for Firebase configuration settings.
///
/// Returns a map with 'enabled' and 'settingsFile' keys.
Map<String, dynamic> _promptFirebaseSettings() {
  final bool enableFirebase =
      promptUser('Do you want to enable Firebase? (y/n)', 'n') == 'y';
  
  String firebaseSettingsFilePath = '';
  if (enableFirebase) {
    firebaseSettingsFilePath = promptUser(
      'Enter Firebase settings file path:',
      '',
      validator: (value) {
        if (value.isEmpty) {
          logger.e('❌ Firebase settings file path cannot be empty.');
          return false;
        }
        if (!File(value).existsSync()) {
          logger.e('❌ Firebase settings file does not exist at $value.');
          return false;
        }
        return true;
      },
    );
  }
  
  return {
    'enabled': enableFirebase,
    'settingsFile': firebaseSettingsFilePath,
  };
}

/// Prompts for Fastlane configuration settings.
///
/// Returns a map with 'enabled' and 'settingsFile' keys.
Map<String, dynamic> _promptFastlaneSettings() {
  final bool enableFastlane =
      promptUser('Do you want to enable Fastlane? (y/n)', 'n') == 'y';

  String fastlaneSettingsFilePath = '';
  if (enableFastlane) {
    fastlaneSettingsFilePath = promptUser(
      'Enter Fastlane settings file path:',
      '',
      validator: (value) {
        if (value.isEmpty) {
          logger.e('❌ Fastlane settings file path cannot be empty.');
          return false;
        } else if (!File(value).existsSync()) {
          logger.e('❌ Fastlane settings file does not exist at $value.');
          return false;
        }
        return true;
      },
    );
  }
  
  return {
    'enabled': enableFastlane,
    'settingsFile': fastlaneSettingsFilePath,
  };
}

/// Prompts for basic project settings.
///
/// Returns a map with 'companyName' and 'defaultColor' keys.
Map<String, String> _promptBasicSettings() {
  final String companyName = promptUser(
    'Enter your company name:',
    '',
    validator: (value) {
      if (value.isEmpty) {
        logger.e('❌ Company name cannot be empty.');
        return false;
      }
      return true;
    },
  );
  
  final String defaultColor = promptUser(
    'Enter default app color (hex format, e.g., #FFFFFF):',
    '#FFFFFF',
    validator: (value) {
      if (RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$').hasMatch(value)) {
        return true;
      }
      logger.e('Invalid hex color format. Use #FFFFFF or #FFF.');
      return false;
    },
  );
  
  return {
    'companyName': companyName,
    'defaultColor': defaultColor,
  };
}

/// Creates the settings file with the provided configurations.
///
/// Returns true if file was created successfully, false on error.
bool _createSettingsFile(
  File settingsFile,
  Map<String, dynamic> firebaseConfig,
  Map<String, dynamic> fastlaneConfig,
  Map<String, String> basicConfig,
) {
  try {
    settingsFile.createSync(recursive: true);
    _createdPaths.add(settingsFile.path);
    
    settingsFile.writeAsStringSync('''
# Clonify Settings
firebase:
  enabled: ${firebaseConfig['enabled']}
  settings_file: "${firebaseConfig['enabled'] ? firebaseConfig['settingsFile'] : ''}"
  
fastlane:
  enabled: ${fastlaneConfig['enabled']}
  settings_file: "${fastlaneConfig['enabled'] ? fastlaneConfig['settingsFile'] : ''}"
company_name: "${basicConfig['companyName']}"

default_color: "${basicConfig['defaultColor']}"
''');
    
    logger.i(
      '✅ Created default clonify_settings.yaml at ${settingsFile.path}.',
    );
    return true;
  } catch (e) {
    logger.e('❌ Failed to create settings file: $e');
    return false;
  }
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
///
/// Supports cancellation cleanup - if the user cancels during initialization,
/// any created files or directories will be automatically cleaned up.
Future<void> initClonify() async {
  try {
    // Step 1: Ensure clonify directory exists
    if (!_ensureClonifyDirectory()) {
      _cleanupCreatedPaths();
      return;
    }

    final settingsFile = File('./clonify/clonify_settings.yaml');
    if (!settingsFile.existsSync()) {
      // Step 2: Gather configuration through prompts
      final firebaseConfig = _promptFirebaseSettings();
      final fastlaneConfig = _promptFastlaneSettings();
      final basicConfig = _promptBasicSettings();
      
      // Step 3: Create settings file
      if (!_createSettingsFile(settingsFile, firebaseConfig, fastlaneConfig, basicConfig)) {
        _cleanupCreatedPaths();
        return;
      }
    } else {
      logger.i(
        'ℹ️ clonify_settings.yaml already exists at ${settingsFile.path}.',
      );
      validatedClonifySettings(isSilent: false);
    }
    
    // Clear tracking list on successful completion
    _createdPaths.clear();
  } catch (e) {
    logger.e('❌ Initialization failed: $e');
    _cleanupCreatedPaths();
    rethrow;
  }
}

/// Validates the existence and readability of the settings file.
///
/// Returns the file content if valid, otherwise returns null and logs errors.
String? _validateSettingsFile() {
  final settingsFile = File(Constants.clonifySettingsFilePath);
  if (!settingsFile.existsSync()) {
    logger.e(Messages.clonifySettingsFileNotFound);
    return null;
  }

  final content = settingsFile.readAsStringSync();
  if (content.isEmpty) {
    logger.e(Messages.clonifySettingsFileNotFound);
    return null;
  }

  return content;
}

/// Parses YAML content and returns the settings map.
///
/// Returns the parsed settings if successful, otherwise returns null and logs errors.
Map<String, dynamic>? _parseYamlSettings(String content) {
  dynamic rawSettings;
  try {
    rawSettings = yaml.loadYaml(content);
  } catch (e) {
    logger.e(Messages.failedToParseClonifySettings(e));
    return null;
  }

  if (rawSettings is! Map) {
    logger.e(Messages.clonifySettingsDoesNotContainAValidMap);
    return null;
  }

  // Convert YamlMap to Map<String, dynamic>
  final Map<String, dynamic> settings = {};
  rawSettings.forEach((key, value) {
    settings[key.toString()] = value is yaml.YamlMap
        ? Map<String, dynamic>.from(value)
        : value;
  });

  return settings;
}

/// Validates that all required fields are present and have correct types.
///
/// Returns true if all required fields are valid, otherwise false.
bool _validateRequiredFields(Map<String, dynamic> rawSettings) {
  const requiredFields = {
    'firebase': yaml.YamlMap,
    'fastlane': yaml.YamlMap,
    'company_name': String,
    'default_color': String,
  };

  for (final field in requiredFields.keys) {
    if (!rawSettings.containsKey(field)) {
      logger.e(Messages.missingRequiredField(field));
      return false;
    }
    if (rawSettings[field] == null ||
        rawSettings[field].runtimeType != requiredFields[field]) {
      logger.e(
        Messages.fieldHasInvalidType(
          field,
          rawSettings[field].runtimeType,
          requiredFields[field],
        ),
      );
      return false;
    }
  }

  return true;
}

/// Validates firebase and fastlane service configurations.
///
/// Returns true if all service configurations are valid, otherwise false.
bool _validateServiceConfigurations(Map<String, dynamic> rawSettings) {
  for (final service in ['firebase', 'fastlane']) {
    final serviceSettings = rawSettings[service];
    if (!serviceSettings.containsKey('enabled') ||
        serviceSettings['enabled'] is! bool) {
      logger.e('❌ "$service.enabled" must be a boolean.');
      return false;
    }
    if (!serviceSettings.containsKey('settings_file') ||
        serviceSettings['settings_file'] is! String) {
      logger.e('❌ "$service.settings_file" must be a string.');
      return false;
    }
  }

  return true;
}

/// Validates business rule fields (company name and default color).
///
/// Returns true if all business rules are satisfied, otherwise false.
bool _validateBusinessRules(Map<String, dynamic> rawSettings) {
  // Check company_name
  if ((rawSettings['company_name'] as String).trim().isEmpty) {
    logger.e('❌ "company_name" cannot be empty.');
    return false;
  }

  // Check default_color is a valid hex color
  final color = rawSettings['default_color'] as String;
  final hexColorRegExp = RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$');
  if (!hexColorRegExp.hasMatch(color)) {
    logger.e('❌ "default_color" must be a valid hex color (e.g., #FFFFFF).');
    return false;
  }

  return true;
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
bool validatedClonifySettings({bool isSilent = true}) {
  // Step 1: Validate file existence and readability
  final content = _validateSettingsFile();
  if (content == null) return false;

  // Step 2: Parse YAML content
  final rawSettings = _parseYamlSettings(content);
  if (rawSettings == null) return false;

  // Step 3: Validate required fields
  if (!_validateRequiredFields(rawSettings)) return false;

  // Step 4: Validate service configurations
  if (!_validateServiceConfigurations(rawSettings)) return false;

  // Step 5: Validate business rules
  if (!_validateBusinessRules(rawSettings)) return false;

  // Success message
  if (!isSilent) {
    logger.i('✅ clonify_settings.yaml is valid.');
  }

  return true;
}

/// GetClonifySettings file as a ClonifySettings object.
/// This function reads the `clonify_settings.yaml` file and returns a map of settings
/// as a ClonifySettings object.
ClonifySettings getClonifySettings() {
  final settingsFile = File(Constants.clonifySettingsFilePath);
  if (!settingsFile.existsSync()) {
    throw Exception(Messages.clonifySettingsFileNotFound);
  }

  final content = settingsFile.readAsStringSync();
  final yaml.YamlMap rawSettings = yaml.loadYaml(content);
  return ClonifySettings.fromYaml(rawSettings);
}

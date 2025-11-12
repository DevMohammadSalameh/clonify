import 'dart:convert';
import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/messages.dart';
import 'package:clonify/models/clonify_settings_model.dart';
import 'package:clonify/models/custom_field_model.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/tui_helpers.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart' as yaml;

const lastClientFilePath = './clonify/last_client.txt';
const lastConfigFilePath = './clonify/last_config.json';

/// Saves the last used client ID to a file.
///
/// This function writes the provided [clientId] to the `last_client.txt` file
/// located in the `./clonify/` directory. This allows the CLI to remember
/// the last active client for convenience.
///
/// Throws a [FileSystemException] if the file cannot be written.
Future<void> saveLastClientId(String clientId) async {
  final file = File(lastClientFilePath);
  await file.writeAsString(clientId);
}

/// Saves the last used configuration map to a JSON file.
///
/// This function serializes the provided [config] map to a JSON string
/// and writes it to the `last_config.json` file located in the `./clonify/`
/// directory. This allows the CLI to remember the last active configuration
/// for convenience.
///
/// Throws a [FileSystemException] if the file cannot be written.
Future<void> saveLastConfig(Map<String, dynamic> config) async {
  final file = File('./clonify/last_config.json');
  await file.writeAsString(jsonEncode(config));
}

/// Retrieves the last saved configuration map from a JSON file.
///
/// This function reads the `last_config.json` file from the `./clonify/`
/// directory, decodes its JSON content, and returns it as a map.
///
/// Returns a `Future<Map<String, dynamic>?>` which is the last saved
/// configuration, or `null` if the file does not exist.
///
/// Throws a [FileSystemException] if the file exists but cannot be read,
/// or a [FormatException] if the file content is not valid JSON.
Future<Map<String, dynamic>?> getLastConfig() async {
  final file = File(lastConfigFilePath);
  if (file.existsSync()) {
    return jsonDecode(await file.readAsString());
  }
  return null;
}

/// Retrieves the client ID from command-line arguments or the last saved configuration.
///
/// This function attempts to extract the client ID from the provided [args]
/// using `--clientId` or `-id`. If not found, it checks the last saved
/// configuration. If a last configured client ID is found, the user is
/// prompted for confirmation to use it.
///
/// Throws an [Exception] if no client ID is provided via arguments and
/// no last configured client is found, or if the user declines to use
/// the last configured client ID.
///
/// Returns a `Future<String?>` representing the client ID, or `null` if
/// no client ID can be determined.
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
  final bool enableFirebase = confirmTUI(
    '\n🔥 Do you want to enable Firebase?',
    defaultValue: false,
  );

  String firebaseSettingsFilePath = '';
  if (enableFirebase) {
    firebaseSettingsFilePath = promptUserTUI(
      '📁 Enter Firebase settings file path',
      '',
      validator: (value) {
        if (value.isEmpty) {
          errorMessage('Firebase settings file path cannot be empty.');
          return false;
        }
        if (!File(value).existsSync()) {
          errorMessage('Firebase settings file does not exist at $value.');
          return false;
        }
        return true;
      },
    );
  }

  return {'enabled': enableFirebase, 'settingsFile': firebaseSettingsFilePath};
}

/// Prompts for Fastlane configuration settings.
///
/// Returns a map with 'enabled' and 'settingsFile' keys.
Map<String, dynamic> _promptFastlaneSettings() {
  final bool enableFastlane = confirmTUI(
    '\n🚀 Do you want to enable Fastlane?',
    defaultValue: false,
  );

  String fastlaneSettingsFilePath = '';
  if (enableFastlane) {
    fastlaneSettingsFilePath = promptUserTUI(
      '📁 Enter Fastlane settings file path',
      '',
      validator: (value) {
        if (value.isEmpty) {
          errorMessage('Fastlane settings file path cannot be empty.');
          return false;
        } else if (!File(value).existsSync()) {
          errorMessage('Fastlane settings file does not exist at $value.');
          return false;
        }
        return true;
      },
    );
  }

  return {'enabled': enableFastlane, 'settingsFile': fastlaneSettingsFilePath};
}

/// Prompts for basic project settings.
///
/// Returns a map with 'companyName' and 'defaultColor' keys.
Map<String, String> _promptBasicSettings() {
  infoMessage('\n📋 Basic Project Settings');

  final String companyName = promptUserTUI(
    '🏢 Enter your company name',
    '',
    validator: (value) {
      if (value.isEmpty) {
        errorMessage('Company name cannot be empty.');
        return false;
      }
      return true;
    },
  );

  final String defaultColor = promptUserTUI(
    '🎨 Enter default app color (hex format, e.g., #FFFFFF)',
    '#FFFFFF',
    validator: (value) {
      if (RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$').hasMatch(value)) {
        return true;
      }
      errorMessage('Invalid hex color format. Use #FFFFFF or #FFF.');
      return false;
    },
  );

  return {'companyName': companyName, 'defaultColor': defaultColor};
}

/// Prompts for assets settings with direct questions about specific asset needs.
///
/// Returns a list of Strings with the names of the assets to be cloned.
/// The launcher icon asset will be the first in the list.
/// The splash screen asset (if any) will be the second in the list.
/// The logo asset (if any) will be the third in the list.
(List<String>, bool) _promptCloneAssetsSettings() {
  final sourceDir = Directory('./assets/images');

  if (!sourceDir.existsSync()) {
    throw FileSystemException(
      'Assets directory does not exist',
      sourceDir.path,
    );
  }

  infoMessage('\n🖼️  Asset Configuration');

  final List<String> selectedAssets = [];

  // Ask about launcher icon
  final needsLauncherIcon = confirmTUI(
    '\n📱 Does your app need a custom launcher icon?',
    defaultValue: true,
  );

  if (needsLauncherIcon) {
    final launcherIconFile = promptUserTUI(
      '🎯 Enter the launcher icon filename (e.g., icon.png)',
      'icon.png',
      validator: (value) => value.trim().isNotEmpty,
    );
    selectedAssets.add(launcherIconFile);
  } else {
    // Launcher icon is required, use default
    warningMessage('Using default launcher icon filename: icon.png');
    selectedAssets.add('icon.png');
  }

  // Ask about splash screen
  final needsSplashScreen = confirmTUI(
    '💫 Does your app need a custom splash screen?',
    defaultValue: false,
  );

  String? splashScreenFile;
  if (needsSplashScreen) {
    splashScreenFile = promptUserTUI(
      '🌟 Enter the splash screen filename (e.g., splash.png)',
      'splash.png',
      validator: (value) => value.trim().isNotEmpty,
    );
    selectedAssets.add(splashScreenFile);
  }

  // Ask about logo asset
  final needsLogo = confirmTUI(
    '🏷️  Does your app need a logo asset?',
    defaultValue: false,
  );

  if (needsLogo) {
    final logoFile = promptUserTUI(
      '🖼️  Enter the logo filename (e.g., logo.png)',
      'logo.png',
      validator: (value) => value.trim().isNotEmpty,
    );
    selectedAssets.add(logoFile);
  }

  if (selectedAssets.isEmpty) {
    logger.e('No assets selected for cloning.');
    return ([], false);
  }

  logger.i('Selected assets: ${selectedAssets.join(', ')}');
  return (selectedAssets, needsSplashScreen);
}

/// Prompts for custom configuration fields.
///
/// Returns a list of CustomField objects.
List<CustomField> _promptCustomFields() {
  final fields = <CustomField>[];

  final wantsCustomFields = confirmTUI(
    '\n⚙️  Do you want to add custom configuration fields?',
    defaultValue: false,
  );

  if (!wantsCustomFields) {
    infoMessage('No custom fields added.');
    return fields;
  }

  infoMessage(
    '\n📝 You can now add custom fields that will be required for each clone.',
  );
  infoMessage('Supported types: string, int, bool, double');

  while (true) {
    print('\n');
    final fieldName = promptUserTUI(
      '🔤 Enter field name (e.g., socketUrl, apiKey)',
      '',
      validator: (value) {
        if (value.trim().isEmpty) {
          errorMessage('Field name cannot be empty.');
          return false;
        }
        if (fields.any((f) => f.name == value.trim())) {
          errorMessage('Field name "$value" already exists.');
          return false;
        }
        return true;
      },
    );

    // Use TUI selection for type
    final typeOptions = ['String', 'Int', 'Bool', 'Double'];
    final selectedType = selectOneTUI(
      '📊 Select field type',
      typeOptions,
      defaultValue: 'String',
    );

    if (selectedType == null) {
      warningMessage('Type selection cancelled, defaulting to String');
    }

    final type = (selectedType ?? 'String').toLowerCase();

    final field = CustomField(name: fieldName, type: type);
    fields.add(field);

    successMessage('Added custom field: $fieldName ($type)');

    final addMore = confirmTUI('\n➕ Add another field?', defaultValue: false);

    if (!addMore) break;
  }

  if (fields.isNotEmpty) {
    infoMessage('\n📋 Custom fields summary:');
    for (final field in fields) {
      infoMessage('  - ${field.name} (${field.type})');
    }
  }

  return fields;
}

/// Creates the settings file with the provided configurations.
///
/// Returns true if file was created successfully, false on error.
bool _createSettingsFile(
  File settingsFile,
  Map<String, dynamic> firebaseConfig,
  Map<String, dynamic> fastlaneConfig,
  Map<String, String> basicConfig,
  List<String> cloneAssets,
  bool isThereASplashScreen,
  List<CustomField> customFields,
) {
  try {
    settingsFile.createSync(recursive: true);
    _createdPaths.add(settingsFile.path);

    // Build custom fields YAML section
    String customFieldsYaml = '';
    if (customFields.isNotEmpty) {
      customFieldsYaml = '\ncustom_fields:\n';
      for (final field in customFields) {
        customFieldsYaml += '  - name: "${field.name}"\n';
        customFieldsYaml += '    type: "${field.type}"\n';
      }
    }

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

clone_assets:
  - ${cloneAssets.join('\n  - ')}

launcher_icon_asset: "${cloneAssets[0]}"

${isThereASplashScreen ? 'splash_screen_asset: "${cloneAssets[1]}"' : ''}$customFieldsYaml
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

/// Initializes the Clonify environment, setting up necessary directories and configuration files.
///
/// This function performs the following steps:
/// - Checks for the existence of the `clonify` directory and creates it if it does not exist.
/// - Checks for the existence of the `clonify_settings.yaml` file inside the `clonify` directory.
///   - If the file does not exist, it prompts the user for various settings (Firebase, Fastlane,
///     company name, default color, clone assets, and custom fields) and creates the file.
///   - If the file exists, it validates the existing settings using `validatedClonifySettings()`.
///
/// The initialization process includes interactive prompts for enabling Firebase and Fastlane services,
/// specifying their respective settings files, entering the company name (used for package naming),
/// setting the default app color, and defining custom configuration fields.
///
/// Supports cancellation cleanup: if the user cancels during initialization,
/// any created files or directories will be automatically cleaned up.
///
/// Throws an [Exception] if initialization fails at any step.
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
      final (List<String>, bool) cloneAssetsConfig =
          _promptCloneAssetsSettings();
      final customFields = _promptCustomFields();

      // Step 3: Create settings file
      if (!_createSettingsFile(
        settingsFile,
        firebaseConfig,
        fastlaneConfig,
        basicConfig,
        cloneAssetsConfig.$1,
        cloneAssetsConfig.$2,
        customFields,
      )) {
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
    logger.e(Messages.failedToReadOrParseClonifySettings(e));
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
    'firebase': Map<String, dynamic>,
    'fastlane': Map<String, dynamic>,
    'company_name': String,
    'default_color': String,
  };

  for (final field in requiredFields.keys) {
    if (!rawSettings.containsKey(field)) {
      logger.e(Messages.missingRequiredField(field));
      return false;
    }

    final expectedType = requiredFields[field];
    if (expectedType == String && rawSettings[field] is! String) {
      logger.e(
        Messages.fieldHasInvalidType(
          field,
          rawSettings[field].runtimeType,
          String,
        ),
      );
      return false;
    }
    if (expectedType == (Map<String, dynamic>) && rawSettings[field] is! Map) {
      logger.e(
        Messages.fieldHasInvalidType(
          field,
          rawSettings[field].runtimeType,
          Map<String, dynamic>,
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

/// Validates the `clonify_settings.yaml` configuration file for correctness and completeness.
///
/// This function performs a series of checks on the `clonify_settings.yaml` file
/// located in the `./clonify/` directory to ensure it is properly structured
/// and contains valid data. The validation steps include:
/// - Verifying the file's existence and readability.
/// - Parsing the YAML content and confirming its validity.
/// - Checking for the presence and correct data types of all required fields
///   (`firebase`, `fastlane`, `company_name`, `default_color`).
/// - Validating the structure and types of subfields within `firebase` and `fastlane`
///   (e.g., `enabled` as boolean, `settings_file` as string).
/// - Applying business rules such as ensuring `company_name` is not empty
///   and `default_color` is a valid hexadecimal color string.
///
/// Error messages are printed to the console for any validation failures.
///
/// [isSilent] A boolean flag. If `true`, success messages will not be printed.
/// Defaults to `true`.
///
/// Returns `true` if the `clonify_settings.yaml` file is valid according to
/// all checks, otherwise returns `false`.
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

/// Retrieves the Clonify settings from the `clonify_settings.yaml` file.
///
/// This function reads the `clonify_settings.yaml` file, parses its YAML content,
/// and converts it into a [ClonifySettings] object. This object provides
/// structured access to all configured settings for the Clonify CLI tool.
///
/// Throws an [Exception] if the `clonify_settings.yaml` file does not exist
/// or if its content cannot be parsed into a valid [ClonifySettings] object.
///
/// Returns a [ClonifySettings] object containing the parsed configuration.
ClonifySettings getClonifySettings() {
  final settingsFile = File(Constants.clonifySettingsFilePath);
  if (!settingsFile.existsSync()) {
    throw Exception(Messages.clonifySettingsFileNotFound);
  }

  final content = settingsFile.readAsStringSync();
  final yaml.YamlMap rawSettings = yaml.loadYaml(content);
  return ClonifySettings.fromYaml(rawSettings);
}

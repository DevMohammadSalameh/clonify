import 'package:yaml/yaml.dart';
import 'package:clonify/models/custom_field_model.dart';

/// Represents the global settings for the Clonify tool.
///
/// These settings are loaded from `clonify_settings.yaml` and define
/// project-wide configuration including Firebase, Fastlane, default colors,
/// and assets to be cloned for each client.
///
/// Example:
/// ```dart
/// final yaml = loadYaml(File('clonify_settings.yaml').readAsStringSync());
/// final settings = ClonifySettings.fromYaml(yaml);
/// ```
class ClonifySettings {
  /// Whether Firebase integration is enabled for this project.
  final bool firebaseEnabled;

  /// Path to the Firebase settings file relative to project root.
  final String firebaseSettingsFilePath;

  /// Whether Fastlane integration is enabled for app deployment.
  final bool fastlaneEnabled;

  /// Path to the Fastlane settings file relative to project root.
  final String fastlaneSettingsFilePath;

  /// The company or organization name used across all clones.
  final String companyName;

  /// The default primary color in hex format (e.g., '#FF5733').
  final String defaultColor;

  /// Whether the app needs a launcher icon.
  final bool needsLauncherIcon;

  /// Whether the app needs a splash screen.
  final bool needsSplashScreen;

  /// Whether the app needs a logo asset.
  final bool needsLogo;

  /// List of custom fields that can be configured per clone.
  final List<CustomField> customFields;

  /// Creates a new [ClonifySettings] instance.
  ///
  /// Most parameters are required, with [splashScreenAsset] and [customFields]
  /// being optional.
  ClonifySettings({
    required this.firebaseEnabled,
    required this.firebaseSettingsFilePath,
    required this.fastlaneEnabled,
    required this.fastlaneSettingsFilePath,
    required this.companyName,
    required this.defaultColor,
    required this.needsLauncherIcon,
    required this.needsSplashScreen,
    required this.needsLogo,
    this.customFields = const [],
  });

  /// Creates a [ClonifySettings] instance from a YAML map.
  ///
  /// Parses the YAML configuration file and creates a settings object.
  /// Provides default values for missing optional fields.
  ///
  /// Example:
  /// ```dart
  /// final yaml = loadYaml('''
  /// firebase:
  ///   enabled: true
  ///   settings_file: firebase_settings.yaml
  /// company_name: My Company
  /// default_color: '#FF5733'
  /// ''');
  /// final settings = ClonifySettings.fromYaml(yaml);
  /// ```
  factory ClonifySettings.fromYaml(YamlMap yaml) {
    // Parse custom fields if they exist
    List<CustomField> customFields = [];
    if (yaml['custom_fields'] != null) {
      final fields = yaml['custom_fields'] as YamlList;
      customFields = fields
          .map((field) => CustomField.fromYaml(field as Map<dynamic, dynamic>))
          .toList();
    }

    return ClonifySettings(
      firebaseEnabled: yaml['firebase']['enabled'] ?? false,
      firebaseSettingsFilePath: yaml['firebase']['settings_file'] ?? '',
      fastlaneEnabled: yaml['fastlane']['enabled'] ?? false,
      fastlaneSettingsFilePath: yaml['fastlane']['settings_file'] ?? '',
      companyName: yaml['company_name'] ?? '',
      defaultColor: yaml['default_color'] ?? '#FFFFFF',
      needsLauncherIcon: yaml['needs_launcher_icon'] ?? false,
      needsSplashScreen: yaml['needs_splash_screen'] ?? false,
      needsLogo: yaml['needs_logo'] ?? false,
      customFields: customFields,
    );
  }
}

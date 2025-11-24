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

  /// Whether to update the Android info rename, splash screen and launcher icon.
  final bool updateAndroidInfo;

  /// Whether to update the iOS info rename, splash screen and launcher icon.
  final bool updateIOSInfo;

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
    required this.updateAndroidInfo,
    required this.updateIOSInfo,
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
    if (yaml[ClonifySettingsKeys.customFields] != null) {
      final fields = yaml[ClonifySettingsKeys.customFields] as YamlList;
      customFields = fields
          .map((field) => CustomField.fromYaml(field as Map<dynamic, dynamic>))
          .toList();
    }

    return ClonifySettings(
      firebaseEnabled:
          yaml[ClonifySettingsKeys.firebase][ClonifySettingsKeys.enabled] ??
          false,
      firebaseSettingsFilePath:
          yaml[ClonifySettingsKeys.firebase][ClonifySettingsKeys
              .settingsFile] ??
          '',
      fastlaneEnabled:
          yaml[ClonifySettingsKeys.fastlane][ClonifySettingsKeys.enabled] ??
          false,
      fastlaneSettingsFilePath:
          yaml[ClonifySettingsKeys.fastlane][ClonifySettingsKeys
              .settingsFile] ??
          '',
      companyName: yaml[ClonifySettingsKeys.companyName] ?? '',
      defaultColor: yaml[ClonifySettingsKeys.defaultColor] ?? '#FFFFFF',
      needsLauncherIcon: yaml[ClonifySettingsKeys.needsLauncherIcon] ?? false,
      needsSplashScreen: yaml[ClonifySettingsKeys.needsSplashScreen] ?? false,
      needsLogo: yaml[ClonifySettingsKeys.needsLogo] ?? false,
      updateAndroidInfo: yaml[ClonifySettingsKeys.updateAndroidInfo] ?? true,
      updateIOSInfo: yaml[ClonifySettingsKeys.updateIOSInfo] ?? true,
      customFields: customFields,
    );
  }
}

class ClonifySettingsKeys {
  static const String firebase = 'firebase';
  static const String enabled = 'enabled';
  static const String settingsFile = 'settings_file';
  static const String fastlane = 'fastlane';
  static const String companyName = 'company_name';
  static const String defaultColor = 'default_color';
  static const String needsLauncherIcon = 'needs_launcher_icon';
  static const String needsSplashScreen = 'needs_splash_screen';
  static const String needsLogo = 'needs_logo';
  static const String updateAndroidInfo = 'update_android_info';
  static const String updateIOSInfo = 'update_ios_info';
  static const String customFields = 'custom_fields';
}

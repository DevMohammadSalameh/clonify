import 'package:yaml/yaml.dart';
import 'package:clonify/models/custom_field_model.dart';

class ClonifySettings {
  final bool firebaseEnabled;
  final String firebaseSettingsFilePath;
  final bool fastlaneEnabled;
  final String fastlaneSettingsFilePath;
  final String companyName;
  final String defaultColor;
  final List<String> assets;
  final String launcherIconAsset;
  final String? splashScreenAsset;
  final List<CustomField> customFields;

  ClonifySettings({
    required this.firebaseEnabled,
    required this.firebaseSettingsFilePath,
    required this.fastlaneEnabled,
    required this.fastlaneSettingsFilePath,
    required this.companyName,
    required this.defaultColor,
    required this.assets,
    required this.launcherIconAsset,
    this.splashScreenAsset,
    this.customFields = const [],
  });

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
      assets: List<String>.from(yaml['clone_assets'] ?? []),
      launcherIconAsset: yaml['launcher_icon_asset'] ?? '',
      splashScreenAsset: yaml['splash_screen_asset'],
      customFields: customFields,
    );
  }
}

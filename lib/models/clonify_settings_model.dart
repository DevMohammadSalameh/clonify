import 'package:yaml/yaml.dart';

class ClonifySettings {
  final bool firebaseEnabled;
  final String firebaseSettingsFile;
  final bool fastlaneEnabled;
  final String fastlaneSettingsFile;
  final String companyName;
  final String defaultColor;

  ClonifySettings({
    required this.firebaseEnabled,
    required this.firebaseSettingsFile,
    required this.fastlaneEnabled,
    required this.fastlaneSettingsFile,
    required this.companyName,
    required this.defaultColor,
  });

  factory ClonifySettings.fromYaml(YamlMap yaml) {
    return ClonifySettings(
      firebaseEnabled: yaml['firebase']['enabled'] ?? false,
      firebaseSettingsFile: yaml['firebase']['settings_file'] ?? '',
      fastlaneEnabled: yaml['fastlane']['enabled'] ?? false,
      fastlaneSettingsFile: yaml['fastlane']['settings_file'] ?? '',
      companyName: yaml['company_name'] ?? '',
      defaultColor: yaml['default_color'] ?? '#FFFFFF',
    );
  }
}

abstract class Constants {
  static String ipaPath(String packageName) =>
      './build/ios/ipa/$packageName.ipa';
  static String aabPath = './build/app/outputs/bundle/release/app-release.aab';
  static const String toolName = 'clonify';
  static String clonifySettingsFilePath = './clonify/clonify_settings.yaml';
  static configFilePath(String clientId) =>
      './clonify/clones/$clientId/config.json';
  static const String pubspecFilePath = './pubspec.yaml';
}

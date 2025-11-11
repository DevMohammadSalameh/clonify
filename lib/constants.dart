abstract class Constants {
  static String ipaPath(String packageName) =>
      './build/ios/ipa/$packageName.ipa';
  static String aabPath = './build/app/outputs/bundle/release/app-release.aab';
  static const String toolName = 'clonify';
  static const String version = '0.1.0';
  static String clonifySettingsFilePath = './clonify/clonify_settings.yaml';
  static configFilePath(String clientId) =>
      './clonify/clones/$clientId/config.json';
  static const String pubspecFilePath = './pubspec.yaml';

  static const String flutterLauncherIconsYaml = '''
dev_dependencies:
  flutter_launcher_icons: "^0.13.1"

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  remove_alpha_ios: true
  image_path: ""
  adaptive_icon_background: "#ffffff"
  adaptive_icon_foreground: ""
  min_sdk_android: 21
''';

  static const String flutterNativeSplashYaml = '''
flutter_native_splash:
  color: "#FFFFFF"
  image: ""
  android_12:
    image: 
  web: false
  ios_content_mode: scaleToFill
  fullscreen: true
''';
}

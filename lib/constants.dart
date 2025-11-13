/// Core constants used throughout the Clonify CLI tool.
///
/// This class provides static constants and utility methods for accessing
/// file paths, configuration templates, and tool metadata.
abstract class Constants {
  // ! File Names
  // ? Root
  static const packageRenameConfigFileName = 'package_rename_config.yaml';
  static const pubspecFileName = 'pubspec.yaml';

  // ? Android
  static const androidManifestFileName = 'AndroidManifest.xml';
  static const buildGradleFileName = 'build.gradle';
  static const kotlinBuildGradleFileName = 'build.gradle.kts';

  // ? iOS
  static const infoPlistFileName = 'Info.plist';

  // ? Web
  static const indexHtmlFileName = 'index.html';
  static const manifestJsonFileName = 'manifest.json';

  // ? Linux
  static const myApplicationFileName = 'my_application.cc';

  // ? Windows
  static const mainCppFileName = 'main.cpp';
  static const runnerFileName = 'Runner.rc';

  // ? Linux & Windows
  static const cMakeListsFileName = 'CMakeLists.txt';

  // ? MacOS
  static const appInfoFileName = 'AppInfo.xcconfig';
  static const runnerXCSchemeFileName = 'Runner.xcscheme';

  // ? iOS & MacOS
  static const projectFileName = 'project.pbxproj';

  // ! Keys
  static const configKey = 'package_rename_config';
  static const appNameKey = 'app_name';
  static const shortAppNameKey = 'short_app_name';
  static const packageNameKey = 'package_name';
  static const bundleNameKey = 'bundle_name';
  static const descriptionKey = 'description';
  static const organizationKey = 'organization';
  static const copyrightKey = 'copyright_notice';
  static const languageKey = 'lang';
  static const executableKey = 'exe_name';
  static const overrideOldPackageKey = 'override_old_package';

  // ! Directory Paths
  // ? Android
  static const androidAppDirPath = 'android/app';
  static const androidSrcDirPath = '$androidAppDirPath/src';
  static const androidMainDirPath = '$androidSrcDirPath/$androidMainDirName';

  // ? iOS
  static const iosDirPath = 'ios';
  static const iosRunnerDirPath = '$iosDirPath/Runner';
  static const iosProjectDirPath = '$iosDirPath/Runner.xcodeproj';

  // ? Web
  static const webDirPath = 'web';

  // ? Linux
  static const linuxDirPath = 'linux';
  static const linuxRunnerDirPath = '$linuxDirPath/runner';

  // ? Windows
  static const windowsDirPath = 'windows';
  static const windowsRunnerDirPath = '$windowsDirPath/runner';

  // ? MacOS
  static const macOSDirPath = 'macos';
  static const macOSConfigDirPath = '$macOSDirPath/Runner/Configs';
  static const macOSProjectDirPath = '$macOSDirPath/Runner.xcodeproj';
  static const macOSXCSchemesDirPath =
      '$macOSProjectDirPath/xcshareddata/xcschemes';

  // ! Directory Names
  // ? Android
  static const androidMainDirName = 'main';
  static const androidDebugDirName = 'debug';
  static const androidProfileDirName = 'profile';

  // ! File Paths
  // ? Android
  static const androidMainManifestFilePath =
      '$androidSrcDirPath/$androidMainDirName/$androidManifestFileName';
  static const androidDebugManifestFilePath =
      '$androidSrcDirPath/$androidDebugDirName/$androidManifestFileName';
  static const androidProfileManifestFilePath =
      '$androidSrcDirPath/$androidProfileDirName/$androidManifestFileName';
  static const androidAppLevelBuildGradleFilePath =
      '$androidAppDirPath/$buildGradleFileName';
  static const androidAppLevelKotlinBuildGradleFilePath =
      '$androidAppDirPath/$kotlinBuildGradleFileName';

  // ? iOS
  static const iosInfoPlistFilePath = '$iosRunnerDirPath/$infoPlistFileName';
  static const iosProjectFilePath = '$iosProjectDirPath/$projectFileName';

  // ? Web
  static const webIndexFilePath = '$webDirPath/$indexHtmlFileName';
  static const webManifestFilePath = '$webDirPath/$manifestJsonFileName';

  // ? Linux
  static const linuxCMakeListsFilePath = '$linuxDirPath/$cMakeListsFileName';
  static const linuxMyApplicationFilePath =
      '$linuxDirPath/$myApplicationFileName';
  static const linuxRunnerMyApplicationFilePath =
      '$linuxRunnerDirPath/$myApplicationFileName';

  // ? Windows
  static const windowsCMakeListsFilePath =
      '$windowsDirPath/$cMakeListsFileName';
  static const windowsMainCppFilePath =
      '$windowsRunnerDirPath/$mainCppFileName';
  static const windowsRunnerFilePath = '$windowsRunnerDirPath/$runnerFileName';

  // ? MacOS
  static const macOSAppInfoFilePath = '$macOSConfigDirPath/$appInfoFileName';
  static const macOSRunnerXCSchemeFilePath =
      '$macOSXCSchemesDirPath/$runnerXCSchemeFileName';
  static const macOSProjectFilePath = '$macOSProjectDirPath/$projectFileName';

  // ! Decorations
  static const outputLength = 100;
  final minorTaskDoneLine = '┈' * outputLength;
  final majorTaskDoneLine = '━' * outputLength;

  // ! Templates
  static const androidKotlinMainActivityTemplate = '''
package {{packageName}}

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
''';

  static const androidJavaMainActivityTemplate = '''
package {{packageName}};

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
}
''';

  static const desktopBinaryNameTemplate = r'^[a-zA-Z0-9_-]+$';

  /// The path to the `flutter_launcher_icons.yaml` configuration file.
  static const String flutterLauncherIconsPath = 'flutter_launcher_icons.yaml';

  /// The path to the `flutter_native_splash.yaml` configuration file.
  static const String flutterNativeSplashPath = 'flutter_native_splash.yaml';

  /// Generates the expected path for the iOS IPA file.
  ///
  /// The path is constructed based on the standard Flutter build output
  /// and includes the provided [packageName].
  ///
  /// [packageName] The package name, which is typically used in the IPA filename.
  ///
  /// Returns a [String] representing the full path to the IPA file.
  static String ipaPath(String packageName) =>
      './build/ios/ipa/$packageName.ipa';

  /// The standard path for the Android App Bundle (AAB) file.
  ///
  /// This constant represents the typical output path for a release AAB
  /// generated by Flutter builds.
  static String aabPath = './build/app/outputs/bundle/release/app-release.aab';

  /// The official name of the Clonify CLI tool.
  static const String toolName = 'clonify';

  /// The current version of the Clonify CLI tool.
  /// Note: This is now read dynamically from pubspec.yaml via the --version flag.
  @Deprecated('Use --version flag to get the current version')
  static const String version = '0.3.0';

  /// The relative path to the main Clonify settings file.
  ///
  /// This file (`clonify_settings.yaml`) stores global configurations
  /// for the Clonify CLI tool.
  static String clonifySettingsFilePath = './clonify/clonify_settings.yaml';

  /// Generates the path to a client's configuration file.
  ///
  /// This method constructs the full path to the `config.json` file
  /// for a specific client, located within the `./clonify/clones/` directory.
  ///
  /// [clientId] The ID of the client for which to get the config file path.
  ///
  /// Returns a [String] representing the full path to the client's config file.
  static configFilePath(String clientId) =>
      './clonify/clones/$clientId/config.json';

  /// The relative path to the project's `pubspec.yaml` file.
  static const String pubspecFilePath = './pubspec.yaml';

  /// A template string for the `flutter_launcher_icons.yaml` configuration file.
  ///
  /// This template is used to generate the configuration for the `flutter_launcher_icons`
  /// package, which helps in creating adaptive launcher icons for Android and iOS.
  static const String flutterLauncherIconsYaml = '''
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  remove_alpha_ios: true
  image_path: ""
  adaptive_icon_background: "#ffffff"
  adaptive_icon_foreground: ""
  min_sdk_android: 21
''';

  /// A template string for the `flutter_native_splash.yaml` configuration file.
  ///
  /// This template is used to generate the configuration for the `flutter_native_splash`
  /// package, which helps in creating native splash screens for Flutter applications.
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

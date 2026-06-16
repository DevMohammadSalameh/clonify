part of '../package_rename_plus.dart';

const _packageRenameCommands = '''
╔═════════════════════════════════════╗
║       Package Rename Commands       ║
╚═════════════════════════════════════╝
''';

const _successMessage = '''
╔═════════════════════════════════════════════════════════════╗
║    🥳🥳🥳 Done! Now go ahead and build your app 🥳🥳🥳      ║
╚═════════════════════════════════════════════════════════════╝
''';

const _filesNotFoundMessage = '''
╔══════════════════════════════════════════════════════════════════════╗
║   Neither `pubspec.yaml` nor `package_rename_config.yaml` found!!!   ║
╚══════════════════════════════════════════════════════════════════════╝
''';

const _configNotFoundMessage = '''
╔══════════════════════════════════════════════════════╗
║   `package_rename_config` key not found or NULL!!!   ║
╚══════════════════════════════════════════════════════╝
''';

const _invalidConfigMessage = '''
╔══════════════════════════════╗
║   Invalid Configuration!!!   ║
╚══════════════════════════════╝
''';

const _invalidAndroidConfigMessage = '''
╔═══════════════════════════════════════╗
║   Invalid Android Configuration!!!.   ║
╚═══════════════════════════════════════╝
''';

const _invalidAppNameMessage = '''
╔═══════════════════════════════════════════╗
║   app_name (App Name) must be a String.   ║
╚═══════════════════════════════════════════╝
''';

const _invalidShortAppNameMessage = '''
╔═══════════════════════════════════════════════════════╗
║   short_app_name (Short App Name) must be a String.   ║
╚═══════════════════════════════════════════════════════╝
''';

const _androidMainManifestNotFoundMessage = '''
╔═══════════════════════════════════════════════════════════════╗
║   AndroidManifest.xml not found in `android/app/src/main/`.   ║
╚═══════════════════════════════════════════════════════════════╝
''';

const _invalidPackageNameMessage = '''
╔═══════════════════════════════════════════════════╗
║   package_name (Package Name) must be a String.   ║
╚═══════════════════════════════════════════════════╝
''';

const _invalidIOSConfigMessage = '''
╔═══════════════════════════════════╗
║   Invalid iOS Configuration!!!.   ║
╚═══════════════════════════════════╝
''';

const _iosInfoPlistNotFoundMessage = '''
╔════════════════════════════════════════════╗
║   Info.plist not found in `ios/Runner/`.   ║
╚════════════════════════════════════════════╝
''';

const _invalidBundleNameMessage = '''
╔═════════════════════════════════════════════════╗
║   bundle_name (Bundle Name) must be a String.   ║
╚═════════════════════════════════════════════════╝
''';

const _iosProjectFileNotFoundMessage = '''
╔═══════════════════════════════════════════════════════════╗
║   project.pbxproj not found in `ios/Runner.xcodeproj/`.   ║
╚═══════════════════════════════════════════════════════════╝
''';

const _invalidWebConfigMessage = '''
╔═══════════════════════════════════╗
║   Invalid Web Configuration!!!.   ║
╚═══════════════════════════════════╝
''';

const _webIndexNotFoundMessage = '''
╔═════════════════════════════════════╗
║   index.html not found in `web/`.   ║
╚═════════════════════════════════════╝
''';

const _invalidDescriptionMessage = '''
╔═════════════════════════════════════════════════╗
║   description (Description) must be a String.   ║
╚═════════════════════════════════════════════════╝
''';

const _invalidLinuxConfigMessage = '''
╔═════════════════════════════════════╗
║   Invalid Linux Configuration!!!.   ║
╚═════════════════════════════════════╝
''';

const _linuxCMakeListsNotFoundMessage = '''
╔═══════════════════════════════════════════╗
║   CMakeLists.txt not found in `linux/`.   ║
╚═══════════════════════════════════════════╝
''';

const _linuxMyApplicationNotFoundMessage = '''
╔══════════════════════════════════════════════════════════════════╗
║   my_application.cc not found in `linux/` and `linux/runner/`.   ║
╚══════════════════════════════════════════════════════════════════╝
''';

const _invalidWindowsConfigMessage = '''
╔═══════════════════════════════════════╗
║   Invalid Windows Configuration!!!.   ║
╚═══════════════════════════════════════╝
''';

const _windowsCMakeListsNotFoundMessage = '''
╔═════════════════════════════════════════════╗
║   CMakeLists.txt not found in `windows/`.   ║
╚═════════════════════════════════════════════╝
''';

const _windowsMainCppNotFoundMessage = '''
╔══════════════════════════════════════════════╗
║   main.cpp not found in `windows/runner/`.   ║
╚══════════════════════════════════════════════╝
''';

const _windowsRunnerNotFoundMessage = '''
╔═══════════════════════════════════════════════╗
║   Runner.rc not found in `windows/runner/`.   ║
╚═══════════════════════════════════════════════╝
''';

const _invalidOrganizationMessage = '''
╔═══════════════════════════════════════════════════╗
║   organization (Organization) must be a String.   ║
╚═══════════════════════════════════════════════════╝
''';

const _invalidCopyrightNoticeMessage = '''
╔═══════════════════════════════════════════════════════════╗
║   copyright_notice (Copyright Notice) must be a String.   ║
╚═══════════════════════════════════════════════════════════╝
''';

const _invalidMacOSConfigMessage = '''
╔═════════════════════════════════════╗
║   Invalid MacOS Configuration!!!.   ║
╚═════════════════════════════════════╝
''';

const _macOSAppInfoNotFoundMessage = '''
╔════════════════════════════════════════════════════════════╗
║   AppInfo.xcconfig not found in `macos/Runner/Configs/`.   ║
╚════════════════════════════════════════════════════════════╝
''';

// const _invalidLanguageTypeMessage = '''
// ╔═══════════════════════════════════════╗
// ║   lang (Language) must be a String.   ║
// ╚═══════════════════════════════════════╝
// ''';

// const _invalidAndroidLangValueMessage = '''
// ╔════════════════════════════════════════════════════════╗
// ║   lang (Language) must be either 'kotlin' or 'java'.   ║
// ╚════════════════════════════════════════════════════════╝
// ''';

const _invalidExecutableNameMessage = '''
╔══════════════════════════════════════════════════╗
║   exe_name (Executable Name) must be a String.   ║
╚══════════════════════════════════════════════════╝
''';

const _invalidExecutableNameValueMessage = '''
╔═══════════════════════════════════════════════════════════════════════════════╗
║   exe_name (Executable Name) must only contain (A-Z), (a-z), (0-9) and (_).   ║
╚═══════════════════════════════════════════════════════════════════════════════╝
''';

// const _androidOldDirectoryNotFoundMessage = '''
// ╔═════════════════════════════════════════════════╗
// ║   Old directory for MainActivity not found!!!   ║
// ╚═════════════════════════════════════════════════╝
// ''';

const _macOSRunnerXCSchemeNotFoundMessage = '''
╔════════════════════════════════════════════════════════════════════════════════════╗
║   Runner.xcscheme not found in `macos/Runner.xcodeproj/xcshareddata/xcschemes/`.   ║
╚════════════════════════════════════════════════════════════════════════════════════╝
''';

const _macOSProjectFileNotFoundMessage = '''
╔═════════════════════════════════════════════════════════════╗
║   project.pbxproj not found in `macos/Runner.xcodeproj/`.   ║
╚═════════════════════════════════════════════════════════════╝
''';

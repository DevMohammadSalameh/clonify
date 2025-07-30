/// [ClonifyCommands] is an enum representing different commands for clonify.
enum ClonifyCommands {
  create,
  init,
  which,
  configure,
  build,
  clean,
  upload,
  list,
}

/// [ClonifyCommandOptions] is an enum representing different options for clonify commands.
enum ClonifyCommandOptions { clientId }

/// [ClonifyCommandFlags] is an enum representing different flags for clonify commands.
enum ClonifyCommandFlags {
  skipAll,
  version,
  autoUpdate,
  isDebug,
  skipFirebaseConfigure,
  skipPubUpdate,
  skipVersionUpdate,
  buildAab,
  buildApk,
  buildIpa,
  skipBuildCheck,
  skipAndroidUploadCheck,
  skipIOSUploadCheck,
}

/// [ClonifyCommandExtension] is an extension on [ClonifyCommands] that provides
/// additional properties for command names and descriptions.
extension ClonifyCommandExtension on ClonifyCommands {
  String get name {
    switch (this) {
      case ClonifyCommands.create:
        return 'create';
      case ClonifyCommands.init:
        return 'init';
      case ClonifyCommands.which:
        return 'which';
      case ClonifyCommands.configure:
        return 'configure';
      case ClonifyCommands.build:
        return 'build';
      case ClonifyCommands.clean:
        return 'clean';
      case ClonifyCommands.upload:
        return 'upload';
      case ClonifyCommands.list:
        return 'list';
    }
  }

  String get description {
    switch (this) {
      case ClonifyCommands.create:
        return 'Create a new Flutter project clone';
      case ClonifyCommands.init:
        return 'Initialize a Flutter project clone';
      case ClonifyCommands.which:
        return 'Show the current client ID';
      case ClonifyCommands.configure:
        return 'Configure the app for the specified client ID';
      case ClonifyCommands.build:
        return 'Build the Flutter project clone';
      case ClonifyCommands.clean:
        return 'Clean the Flutter project clone';
      case ClonifyCommands.upload:
        return 'Upload the Flutter project clone';
      case ClonifyCommands.list:
        return 'List all available Flutter project clones';
    }
  }

  //aliases for commands
  List<String> get aliases {
    switch (this) {
      case ClonifyCommands.create:
        return ['create-clone'];
      case ClonifyCommands.init:
        return ['i', 'initialize'];
      case ClonifyCommands.which:
        return ['w', 'current', 'who'];
      case ClonifyCommands.configure:
        return ['con', 'config', 'c'];
      case ClonifyCommands.build:
        return ['b'];
      case ClonifyCommands.clean:
        return ['clear'];
      case ClonifyCommands.upload:
        return ['up', 'u'];
      case ClonifyCommands.list:
        return ['l', 'list-clones', 'ls'];
    }
  }
}

extension ClonifyCommandOptionsExtension on ClonifyCommandOptions {
  String get name {
    switch (this) {
      case ClonifyCommandOptions.clientId:
        return 'clientId';
    }
  }

  String get description {
    switch (this) {
      case ClonifyCommandOptions.clientId:
        return 'Specify the client ID for the command';
    }
  }

  List<String> get aliases {
    switch (this) {
      case ClonifyCommandOptions.clientId:
        return ['client-id', 'id'];
    }
  }
}

extension ClonifyCommandFlagsExtension on ClonifyCommandFlags {
  String get name {
    switch (this) {
      case ClonifyCommandFlags.skipAll:
        return 'skipAll';
      case ClonifyCommandFlags.version:
        return 'version';
      case ClonifyCommandFlags.autoUpdate:
        return 'autoUpdate';
      case ClonifyCommandFlags.isDebug:
        return 'isDebug';
      case ClonifyCommandFlags.skipFirebaseConfigure:
        return 'skipFirebaseConfigure';
      case ClonifyCommandFlags.skipPubUpdate:
        return 'skipPubUpdate';
      case ClonifyCommandFlags.skipVersionUpdate:
        return 'skipVersionUpdate';
      case ClonifyCommandFlags.buildAab:
        return 'buildAab';
      case ClonifyCommandFlags.buildApk:
        return 'buildApk';
      case ClonifyCommandFlags.buildIpa:
        return 'buildIpa';
      case ClonifyCommandFlags.skipBuildCheck:
        return 'skipBuildCheck';
      case ClonifyCommandFlags.skipAndroidUploadCheck:
        return 'skipAndroidUploadCheck';
      case ClonifyCommandFlags.skipIOSUploadCheck:
        return 'skipIOSUploadCheck';
    }
  }

  String get description {
    switch (this) {
      case ClonifyCommandFlags.skipAll:
        return 'Skip all user prompts';
      case ClonifyCommandFlags.version:
        return 'Show the version of the tool';
      case ClonifyCommandFlags.autoUpdate:
        return 'Automatically update the project dependencies';
      case ClonifyCommandFlags.isDebug:
        return 'Run the command in debug mode';
      case ClonifyCommandFlags.skipFirebaseConfigure:
        return 'Skip Firebase configuration';
      case ClonifyCommandFlags.skipPubUpdate:
        return 'Skip updating pubspec.yaml';
      case ClonifyCommandFlags.skipVersionUpdate:
        return 'Skip updating the version in pubspec.yaml';
      case ClonifyCommandFlags.buildAab:
        return 'Build Android App Bundle (AAB)';
      case ClonifyCommandFlags.buildApk:
        return 'Build Android APK';
      case ClonifyCommandFlags.buildIpa:
        return 'Build iOS IPA';
      case ClonifyCommandFlags.skipBuildCheck:
        return 'Skip build checks for Android and iOS';
      case ClonifyCommandFlags.skipAndroidUploadCheck:
        return 'Skip Android upload checks';
      case ClonifyCommandFlags.skipIOSUploadCheck:
        return 'Skip iOS upload checks';
    }
  }

  // String get abbr {
  //   switch (this) {
  //     case ClonifyCommandFlags.skipAll:
  //       return 'SA';
  //     case ClonifyCommandFlags.version:
  //       return 'v';
  //     case ClonifyCommandFlags.autoUpdate:
  //       return 'AU';
  //     case ClonifyCommandFlags.isDebug:
  //       return 'D';
  //     case ClonifyCommandFlags.skipFirebaseConfigure:
  //       return 'SFC';
  //     case ClonifyCommandFlags.skipPubUpdate:
  //       return 'SPU';
  //     case ClonifyCommandFlags.skipVersionUpdate:
  //       return 'SVU';
  //     case ClonifyCommandFlags.buildAab:
  //       return 'BAAB';
  //     case ClonifyCommandFlags.buildApk:
  //       return 'BAPK';
  //     case ClonifyCommandFlags.buildIpa:
  //       return 'BIPA';
  //     case ClonifyCommandFlags.skipBuildCheck:
  //       return 'SBC';
  //     case ClonifyCommandFlags.skipAndroidUploadCheck:
  //       return 'SAUC';
  //     case ClonifyCommandFlags.skipIOSUploadCheck:
  //       return 'SIUC';
  //   }
  // }

  String get help {
    switch (this) {
      case ClonifyCommandFlags.skipAll:
        return 'Skip all user prompts during command execution';
      case ClonifyCommandFlags.version:
        return 'Display the version of the clonify tool';
      case ClonifyCommandFlags.autoUpdate:
        return 'Automatically update project dependencies';
      case ClonifyCommandFlags.isDebug:
        return 'Run the command in debug mode for detailed output';
      case ClonifyCommandFlags.skipFirebaseConfigure:
        return 'Skip Firebase configuration during setup';
      case ClonifyCommandFlags.skipPubUpdate:
        return 'Skip updating the pubspec.yaml file';
      case ClonifyCommandFlags.skipVersionUpdate:
        return 'Skip updating the version in pubspec.yaml';
      case ClonifyCommandFlags.buildAab:
        return 'Build the Android App Bundle (AAB) for the project';
      case ClonifyCommandFlags.buildApk:
        return 'Build the Android APK for the project';
      case ClonifyCommandFlags.buildIpa:
        return 'Build the iOS IPA for the project';
      case ClonifyCommandFlags.skipBuildCheck:
        return 'Skip build checks for Android and iOS platforms';
      case ClonifyCommandFlags.skipAndroidUploadCheck:
        return 'Skip upload checks for Android apps';
      case ClonifyCommandFlags.skipIOSUploadCheck:
        return 'Skip upload checks for iOS apps';
    }
  }
}

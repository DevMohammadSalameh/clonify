import 'package:args/args.dart';

/// CLI subcommands for Clonify.
///
/// [name] comes from the enum value (`create`, `init`, …) — no hardcoding.
enum ClonifyCommands {
  create(
    description: 'Create a new Flutter project clone',
    aliases: ['create-clone'],
  ),
  init(
    description: 'Initialize a Flutter project clone',
    aliases: ['i', 'initialize'],
  ),
  which(
    description: 'Show the current client ID',
    aliases: ['w', 'current', 'who'],
  ),
  configure(
    description: 'Configure the app for the specified client ID',
    aliases: ['con', 'config', 'c'],
  ),
  shorebird(
    description: 'Configure a clone then run Shorebird (release/patch)',
    aliases: ['sb'],
  ),
  build(description: 'Build the Flutter project clone', aliases: ['b']),
  clean(description: 'Clean the Flutter project clone', aliases: ['clear']),
  upload(description: 'Upload the Flutter project clone', aliases: ['up', 'u']),
  list(
    description: 'List all available Flutter project clones',
    aliases: ['l', 'list-clones', 'ls'],
  );

  const ClonifyCommands({required this.description, this.aliases = const []});

  final String description;
  final List<String> aliases;
}

/// Shared CLI options.
enum ClonifyCommandOptions {
  clientId(
    description: 'Specify the client ID for the command',
    aliases: ['client-id', 'id'],
  );

  const ClonifyCommandOptions({
    required this.description,
    this.aliases = const [],
  });

  final String description;
  final List<String> aliases;
}

/// Shared CLI flags. Defaults live here so ArgParser and models stay in sync.
enum ClonifyCommandFlags {
  skipAll(
    help: 'Skip all user prompts during command execution',
    description: 'Skip all user prompts',
  ),
  version(
    help: 'Display the version of the clonify tool',
    description: 'Show the version of the tool',
  ),
  autoUpdate(
    help: 'Automatically update project dependencies',
    description: 'Automatically update the project dependencies',
  ),
  isDebug(
    help: 'Run the command in debug mode for detailed output',
    description: 'Run the command in debug mode',
  ),
  skipFirebaseConfigure(
    help: 'Skip Firebase configuration during setup',
    description: 'Skip Firebase configuration',
  ),
  skipShorebirdConfigure(
    help: 'Skip Shorebird app_id sync during setup',
    description: 'Skip Shorebird configuration',
  ),
  skipPubUpdate(
    help: 'Skip updating the pubspec.yaml file',
    description: 'Skip updating pubspec.yaml',
  ),
  skipVersionUpdate(
    help: 'Skip updating the version in pubspec.yaml',
    description: 'Skip updating the version in pubspec.yaml',
  ),
  buildAab(
    help: 'Build the Android App Bundle (AAB) for the project',
    description: 'Build Android App Bundle (AAB)',
    defaultsTo: true,
  ),
  buildApk(
    help: 'Build the Android APK for the project',
    description: 'Build Android APK',
  ),
  buildIpa(
    help: 'Build the iOS IPA for the project',
    description: 'Build iOS IPA',
    defaultsTo: true,
  ),
  skipBuildCheck(
    help: 'Skip build checks for Android and iOS platforms',
    description: 'Skip build checks for Android and iOS',
  ),
  skipAndroidUploadCheck(
    help: 'Skip upload checks for Android apps',
    description: 'Skip Android upload checks',
  ),
  skipIOSUploadCheck(
    help: 'Skip upload checks for iOS apps',
    description: 'Skip iOS upload checks',
  );

  const ClonifyCommandFlags({
    required this.help,
    required this.description,
    this.defaultsTo = false,
  });

  final String help;
  final String description;
  final bool defaultsTo;
}

/// Registers Clonify flags on an [ArgParser] without repeating name/help/default.
extension ClonifyArgParser on ArgParser {
  void addClonifyFlag(ClonifyCommandFlags flag, {bool? defaultsTo}) {
    addFlag(
      flag.name,
      help: flag.help,
      defaultsTo: defaultsTo ?? flag.defaultsTo,
    );
  }

  void addClonifyFlags(Iterable<ClonifyCommandFlags> flags) {
    for (final flag in flags) {
      addClonifyFlag(flag);
    }
  }

  void addClientIdOption({bool mandatory = true}) {
    addOption(
      ClonifyCommandOptions.clientId.name,
      aliases: ClonifyCommandOptions.clientId.aliases,
      help: ClonifyCommandOptions.clientId.description,
      mandatory: mandatory,
    );
  }
}

/// Typed readers for Clonify CLI args.
extension ClonifyArgResults on ArgResults {
  String? get clientId => this[ClonifyCommandOptions.clientId.name] as String?;

  bool clonifyFlag(ClonifyCommandFlags flag) =>
      this[flag.name] as bool? ?? flag.defaultsTo;
}

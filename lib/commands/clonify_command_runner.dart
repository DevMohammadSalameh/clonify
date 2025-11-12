/// File: clonify.dart
/// Project: clonify
/// Author: Mohammad Salameh
/// Created Date: 25.09.2024
/// Description: This file defines ClonifyCommandRunner for the rename project and its commands, options etc.
library;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clonify/constants.dart';
import 'package:clonify/enums.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/messages.dart';
import 'package:clonify/models/commands_calls_models/build_command_model.dart';
import 'package:clonify/models/commands_calls_models/configure_command_model.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/utils/build_manager.dart';
import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/upload_manager.dart';
import 'package:yaml/yaml.dart';

/// A [CommandRunner] for the Clonify CLI tool.
///
/// This class extends [CommandRunner] to provide a command-line interface
/// for managing Flutter project clones. It registers all available commands
/// and handles global flags like `--version`.
///
/// It also includes logic to conditionally validate Clonify settings
/// based on the command being executed.
class ClonifyCommandRunner extends CommandRunner<void> {
  /// Creates an instance of [ClonifyCommandRunner].
  ///
  /// Initializes the command runner with the tool's name and description,
  /// and registers all subcommands such as [InitializeCommand], [CreateCommand],
  /// [ConfigureCommand], [BuildCommand], [CleanCommand], [UploadCommand],
  /// [ListCommand], and [WhichCommand].
  ClonifyCommandRunner() : super(Constants.toolName, Messages.toolDescription) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Display the version of Clonify',
    );

    addCommand(InitializeCommand());
    addCommand(CreateCommand());
    addCommand(ConfigureCommand());
    addCommand(BuildCommand());
    addCommand(CleanCommand());
    addCommand(UploadCommand());
    addCommand(ListCommand());
    addCommand(WhichCommand());
  }

  /// Reads the version from clonify's own pubspec.yaml
  ///
  /// Attempts to locate and read the version from the clonify package's pubspec.yaml file.
  /// Searches relative to the executable location to ensure it reads clonify's version,
  /// not the Flutter project's version.
  String _getVersionFromPubspec() {
    try {
      // Get the script location (where the clonify executable is located)
      final scriptPath = Platform.script.toFilePath();
      final scriptDir = Directory(scriptPath).parent;

      // For compiled executable: script is in bin/, pubspec.yaml is in parent
      // For dart run: script is in bin/, pubspec.yaml is in parent
      File pubspecFile = File('${scriptDir.parent.path}/pubspec.yaml');

      // If not found, try relative to script directory (for development)
      if (!pubspecFile.existsSync()) {
        pubspecFile = File('${scriptDir.path}/pubspec.yaml');
      }

      if (!pubspecFile.existsSync()) {
        return 'unknown';
      }

      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as YamlMap;

      // Verify this is the clonify package by checking the name
      final packageName = pubspec['name']?.toString();
      if (packageName != 'clonify') {
        return 'unknown';
      }

      return pubspec['version']?.toString() ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Future<void> run(Iterable<String> args) async {
    // Parse arguments
    final argResults = parse(args);

    // Handle --version flag
    if (argResults['version'] == true) {
      final version = _getVersionFromPubspec();
      print('${Constants.toolName} version $version');
      return;
    }

    // Define commands that do not require Clonify settings validation.
    // These commands can run even if the clonify_settings.yaml file is not present or invalid.
    List<String> commandsToSkipValidation = [
      ClonifyCommands.init.name,
      ClonifyCommands.list.name,
    ];

    // Determine if validation should be skipped based on arguments.
    // Validation is skipped for empty arguments (shows help), --help, -h,
    // or specific commands like 'init' and 'list'.
    final shouldSkipValidation =
        args.isEmpty ||
        args.contains('--help') ||
        args.contains('-h') ||
        (args.isNotEmpty && commandsToSkipValidation.contains(args.first));

    if (!shouldSkipValidation) {
      // Validate clonify settings before running any other command.
      // If validation fails, a CustomException is thrown.
      if (!validatedClonifySettings(isSilent: true)) {
        throw CustomException('Validation Failed !');
      }
    }
    // Execute the command using the superclass's run method.
    return super.run(args);
  }
}

/// A command that initializes the Clonify environment.
///
/// This command creates the necessary `clonify/` directory and
/// `clonify_settings.yaml` file if they don't already exist.
class InitializeCommand extends Command {
  @override
  String get name => ClonifyCommands.init.name;

  @override
  String get description => ClonifyCommands.init.description;

  @override
  List<String> get aliases => ClonifyCommands.init.aliases;

  @override
  Future<void> run() async {
    await initClonify();
  }
}

/// A command that creates a new Flutter project clone.
///
/// This command guides the user through a series of prompts to define
/// the configuration for a new clone, including client ID, app name,
/// package name, and other settings. It then sets up the directory
/// structure and configuration files for the new clone.
class CreateCommand extends Command {
  @override
  String get name => ClonifyCommands.create.name;

  @override
  String get description => ClonifyCommands.create.description;

  @override
  List<String> get aliases => ClonifyCommands.create.aliases;

  @override
  Future<void> run() async {
    await createClone();
  }
}

/// A command that displays the currently active clone configuration.
///
/// This command retrieves and prints details about the Flutter project
/// clone that is currently configured or being worked on.
class WhichCommand extends Command {
  @override
  String get name => ClonifyCommands.which.name;

  @override
  String get description => ClonifyCommands.which.description;

  @override
  List<String> get aliases => ClonifyCommands.which.aliases;

  @override
  Future<void> run() async {
    await getCurrentCloneConfig();
  }
}

/// An abstract base class for Clonify commands that require a client ID option.
///
/// This class provides a common structure for commands that operate on
/// specific Flutter project clones, identified by a client ID. It automatically
/// adds the `--client-id` option to the command's argument parser.
abstract class ClientIdCommand extends Command {
  /// Creates a [ClientIdCommand] instance.
  ///
  /// The [mandatory] parameter determines if the `--client-id` option
  /// is required for the command. Defaults to `true`.
  ClientIdCommand({bool mandatory = true}) {
    argParser.addOption(
      ClonifyCommandOptions.clientId.name,
      aliases: ClonifyCommandOptions.clientId.aliases,
      help: 'Specify the client ID',
      mandatory: mandatory,
    );
  }
}

/// A command that configures a Flutter project clone.
///
/// This command applies a specific clone's configuration to the Flutter project.
/// It supports various options to skip prompts, auto-update versions,
/// and control Firebase configuration.
class ConfigureCommand extends ClientIdCommand {
  /// Creates a [ConfigureCommand] instance.
  ///
  /// Initializes the command and adds specific flags for configuration,
  /// such as `--skip-all`, `--auto-update`, `--is-debug`,
  /// `--skip-firebase-configure`, `--skip-pub-update`, and `--skip-version-update`.
  ConfigureCommand() : super(mandatory: false) {
    argParser.addFlag(
      ClonifyCommandFlags.skipAll.name,
      // abbr: ClonifyCommandFlags.skipAll.abbr,
      help: ClonifyCommandFlags.skipAll.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.autoUpdate.name,
      // abbr: ClonifyCommandFlags.autoUpdate.abbr,
      help: ClonifyCommandFlags.autoUpdate.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.isDebug.name,
      // abbr: ClonifyCommandFlags.isDebug.abbr,
      help: ClonifyCommandFlags.isDebug.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipFirebaseConfigure.name,
      // abbr: ClonifyCommandFlags.skipFirebaseConfigure.abbr,
      help: ClonifyCommandFlags.skipFirebaseConfigure.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipPubUpdate.name,
      // abbr: ClonifyCommandFlags.skipPubUpdate.abbr,
      help: ClonifyCommandFlags.skipPubUpdate.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipVersionUpdate.name,
      // abbr: ClonifyCommandFlags.skipVersionUpdate.abbr,
      help: ClonifyCommandFlags.skipVersionUpdate.help,
    );
  }
  @override
  String get name => ClonifyCommands.configure.name;
  @override
  String get description => ClonifyCommands.configure.description;
  @override
  List<String> get aliases => ClonifyCommands.configure.aliases;

  /// Executes the configure command.
  ///
  /// It parses the command-line arguments, retrieves the client ID,
  /// and then calls the [configureApp] function to apply the configuration.
  /// If no client ID is provided, it attempts to use the last configured
  /// client ID, prompting the user for confirmation.
  @override
  Future<void> run() async {
    final configureModel = ConfigureCommandModel.fromArgs(argResults!);

    if (configureModel.clientId == null) {
      final lastClientId = await getLastClientId();
      if (lastClientId != null && !(configureModel.skipAll)) {
        final answer = prompt(Messages.useLastClientIdMessage(lastClientId));
        if (answer.toLowerCase() == 'y') {
          configureModel.clientId = lastClientId;
          await configureApp(configureModel);
          return;
        }
      }
      throw CustomException(Messages.clientIdRequired);
    }
    await configureApp(configureModel);
  }
}

/// A command that builds the Flutter project clone apps.
///
/// This command compiles the configured Flutter project for various platforms
/// (e.g., Android AAB/APK, iOS IPA) based on the provided client ID and build options.
class BuildCommand extends ClientIdCommand {
  /// Creates a [BuildCommand] instance.
  ///
  /// Initializes the command and adds specific flags for building,
  /// such as `--skip-all`, `--build-aab`, `--build-apk`, `--build-ipa`,
  /// and `--skip-build-check`.
  BuildCommand() : super(mandatory: false) {
    argParser.addFlag(
      ClonifyCommandFlags.skipAll.name,
      // abbr: ClonifyCommandFlags.skipAll.abbr,
      help: ClonifyCommandFlags.skipAll.help,
      defaultsTo: false,
    );
    argParser.addFlag(
      ClonifyCommandFlags.buildAab.name,
      // abbr: ClonifyCommandFlags.buildAab.abbr,
      help: ClonifyCommandFlags.buildAab.help,
      defaultsTo: true,
    );
    argParser.addFlag(
      ClonifyCommandFlags.buildApk.name,
      // abbr: ClonifyCommandFlags.buildApk.abbr,
      help: ClonifyCommandFlags.buildApk.help,
      defaultsTo: false,
    );
    argParser.addFlag(
      ClonifyCommandFlags.buildIpa.name,
      // abbr: ClonifyCommandFlags.buildIpa.abbr,
      help: ClonifyCommandFlags.buildIpa.help,
      defaultsTo: true,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipBuildCheck.name,
      // abbr: ClonifyCommandFlags.skipBuildCheck.abbr,
      help: ClonifyCommandFlags.skipBuildCheck.help,
      defaultsTo: false,
    );
  }

  @override
  String get name => ClonifyCommands.build.name;

  @override
  String get description => ClonifyCommands.build.description;

  @override
  List<String> get aliases => ClonifyCommands.build.aliases;

  /// Executes the build command.
  ///
  /// It parses the command-line arguments, retrieves the client ID,
  /// and then calls the [buildApps] function to compile the application.
  /// If no client ID is provided, it attempts to use the last configured
  /// client ID, prompting the user for confirmation.
  @override
  Future<void> run() async {
    final BuildCommandModel buildModel = BuildCommandModel.fromArgs(
      argResults!,
    );

    if (buildModel.clientId == null) {
      final lastClientId = await getLastClientId();
      if (lastClientId != null && !(buildModel.skipAll)) {
        final answer = prompt(Messages.useLastClientIdMessage(lastClientId));
        if (answer.toLowerCase() == 'y') {
          buildModel.clientId = lastClientId;
          await buildApps(buildModel);
          return;
        }
      }
      throw CustomException(Messages.clientIdRequiredForBuilding);
    } else {
      await buildApps(buildModel);
      // throw CustomException(Messages.clientIdRequiredForBuilding);
    }
  }
}

/// A command that cleans up a partial or broken Flutter project clone.
///
/// This command removes the directory and associated files for a specified
/// client ID, helping to clear out incomplete or problematic clone setups.
class CleanCommand extends ClientIdCommand {
  /// Creates a [CleanCommand] instance.
  ///
  /// The `--client-id` option is mandatory for this command.
  CleanCommand() : super(mandatory: true);

  @override
  String get name => ClonifyCommands.clean.name;

  @override
  String get description => ClonifyCommands.clean.description;

  @override
  List<String> get aliases => ClonifyCommands.clean.aliases;

  /// Executes the clean command.
  ///
  /// It retrieves the client ID from the command-line arguments
  /// and then calls the [cleanupPartialClone] function to remove
  /// the associated clone files.
  @override
  Future<void> run() async {
    final clientId = argResults![ClonifyCommandOptions.clientId.name];

    try {
      await cleanupPartialClone(clientId);
    } catch (e) {
      throw CustomException(
        'Failed to clean up the clone for client ID "$clientId": $e',
      );
    }
  }
}

/// A command that uploads the Flutter project clone to app stores (e.g., Google Play, Apple App Store).
///
/// This command facilitates the deployment of a configured Flutter project
/// by handling the upload process, with options to skip various checks.
class UploadCommand extends ClientIdCommand {
  /// Creates an [UploadCommand] instance.
  ///
  /// Initializes the command and adds specific flags for controlling the
  /// upload process, such as `--skip-all`, `--skip-android-upload-check`,
  /// and `--skip-ios-upload-check`.
  UploadCommand() : super(mandatory: false) {
    argParser.addFlag(
      ClonifyCommandFlags.skipAll.name,
      // abbr: ClonifyCommandFlags.skipAll.abbr,
      help: ClonifyCommandFlags.skipAll.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipAndroidUploadCheck.name,
      // abbr: ClonifyCommandFlags.skipAndroidUploadCheck.abbr,
      help: ClonifyCommandFlags.skipAndroidUploadCheck.help,
    );
    argParser.addFlag(
      ClonifyCommandFlags.skipIOSUploadCheck.name,
      // abbr: ClonifyCommandFlags.skipIOSUploadCheck.abbr,
      help: ClonifyCommandFlags.skipIOSUploadCheck.help,
    );
  }

  @override
  String get name => ClonifyCommands.upload.name;

  @override
  String get description => ClonifyCommands.upload.description;

  @override
  List<String> get aliases => ClonifyCommands.upload.aliases;

  /// Executes the upload command.
  ///
  /// It parses the command-line arguments, retrieves the client ID and
  /// various skip flags, and then calls the [uploadApps] function to
  /// initiate the app upload process.
  @override
  Future<void> run() async {
    final clientId = argResults![ClonifyCommandOptions.clientId.name];
    final skipAll = argResults![ClonifyCommandFlags.skipAll.name];
    final skipAndroidUploadCheck =
        argResults![ClonifyCommandFlags.skipAndroidUploadCheck.name];
    final skipIOSUploadCheck =
        argResults![ClonifyCommandFlags.skipIOSUploadCheck.name];

    try {
      if (clientId != null) {
        await uploadApps(
          clientId,
          skipAll: skipAll,
          skipAndroidUploadCheck: skipAndroidUploadCheck,
          skipIOSUploadCheck: skipIOSUploadCheck,
        );
      }
    } catch (error) {
      throw CustomException(Messages.failedToUploadClone(clientId, error));
    }
  }
}

/// A command that lists all available Clonify project clones.
///
/// This command scans the `clonify/clones` directory and displays
/// a table of all configured client IDs along with their associated
/// app names, Firebase project IDs, and versions.
class ListCommand extends Command {
  @override
  String get name => ClonifyCommands.list.name;

  @override
  String get description => ClonifyCommands.list.description;

  @override
  List<String> get aliases => ClonifyCommands.list.aliases;

  /// Executes the list command.
  ///
  /// It calls the [listClients] function to retrieve and display
  /// information about all available clones.
  @override
  Future<void> run() async {
    listClients();
  }
}

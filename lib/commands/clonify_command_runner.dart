/// File: clonify.dart
/// Project: clonify
/// Author: Mohammad Salameh
/// Created Date: 25.09.2024
/// Description: This file defines ClonifyCommandRunner for the rename project and its commands, options etc.
library;

import 'dart:async';

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

/// [ClonifyCommandRunner] is responsible for running the clonify command in the CLI tool.
/// It extends the CommandRunner class and overrides some of its methods.
class ClonifyCommandRunner extends CommandRunner<void> {
  /// Constructor for [ClonifyCommandRunner].
  /// It initializes the super class with the name of the command and its description.
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

  @override
  Future<void> run(Iterable<String> args) async {
    // Parse arguments to check for version flag
    final argResults = parse(args);

    // Handle --version flag
    if (argResults['version'] == true) {
      print('${Constants.toolName} version ${Constants.version}');
      return;
    }

    List<String> commandsToSkipValidation = [
      ClonifyCommands.init.name,
      ClonifyCommands.list.name,
    ];

    final shouldSkipValidation =
        args.isEmpty ||
        args.contains('--help') ||
        args.contains('-h') ||
        (args.isNotEmpty && commandsToSkipValidation.contains(args.first));

    if (!shouldSkipValidation) {
      // Validate clonify settings before running any other command
      if (!validatedClonifySettings(isSilent: true)) {
        throw CustomException('Validation Failed !');
      }
    }
    return super.run(args);
  }
}

/// [InitializeCommand] is a class that extends the Command class.
/// It is responsible for initializing the clonify project.
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

/// [CreateCommand] is a class that extends the Command class.
/// It is responsible for creating a new Flutter project clone.
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

/// [WhichCommand] is a class that extends the Command class.
/// It is responsible for displaying the current clone configuration.
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

/// [ClientIdCommand] is an abstract class that extends the Command class.
/// It provides a base for commands that require a client ID option.
abstract class ClientIdCommand extends Command {
  ClientIdCommand({bool mandatory = true}) {
    argParser.addOption(
      ClonifyCommandOptions.clientId.name,
      aliases: ClonifyCommandOptions.clientId.aliases,
      help: 'Specify the client ID',
      mandatory: mandatory,
    );
  }
}

/// [ConfigureCommand] is a class that extends the [ClientIdCommand] class.
/// It is responsible for configuring the application with the provided client ID and options.
class ConfigureCommand extends ClientIdCommand {
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

/// [BuildCommand] is a class that extends the Command class.
/// It is responsible for building the Flutter project clone apps.
class BuildCommand extends ClientIdCommand {
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

/// [CleanCommand] is a class that extends the Command class.
/// It is responsible for cleaning up the Flutter project clone.
class CleanCommand extends ClientIdCommand {
  CleanCommand() : super(mandatory: true);

  @override
  String get name => ClonifyCommands.clean.name;

  @override
  String get description => ClonifyCommands.clean.description;

  @override
  List<String> get aliases => ClonifyCommands.clean.aliases;

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

/// [UploadCommand] is a class that extends the Command class.
/// It is responsible for uploading the Flutter project clone to the app store and Google Play.
class UploadCommand extends ClientIdCommand {
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

/// [ListCommand] is a class that extends the Command class.
/// It is responsible for listing all the available clones.
class ListCommand extends Command {
  @override
  String get name => ClonifyCommands.list.name;

  @override
  String get description => ClonifyCommands.list.description;

  @override
  List<String> get aliases => ClonifyCommands.list.aliases;

  @override
  Future<void> run() async {
    listClients();
  }
}

/// File: clonify.dart
/// Project: clonify
/// Author: Mohammad Salameh
/// Created Date: 25.09.2024
/// Description: This file defines ClonifyCommandRunner for the rename project and its commands, options etc.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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
import 'package:clonify/utils/shorebird_manager.dart';
import 'package:clonify/utils/upload_manager.dart';
import 'package:clonify/utils/tui_helpers.dart';
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
      ClonifyCommandFlags.version.name,
      abbr: 'v',
      negatable: false,
      help: ClonifyCommandFlags.version.help,
    );

    argParser.addFlag(
      'no-tui',
      negatable: false,
      help:
          'Disable TUI (Text User Interface) features and use basic text mode',
    );

    addCommand(InitializeCommand());
    addCommand(CreateCommand());
    addCommand(ConfigureCommand());
    addCommand(ShorebirdCommand());
    addCommand(BuildCommand());
    addCommand(CleanCommand());
    addCommand(UploadCommand());
    addCommand(ListCommand());
    addCommand(WhichCommand());
  }

  /// Reads the version from clonify's own pubspec.yaml when possible.
  ///
  /// Works for `dart run`, path activates, and `dart pub global activate`
  /// (including git installs / snapshots) via `package:clonify` resolution.
  /// Falls back to [Constants.packageVersion].
  Future<String> getVersionFromPubspec() async {
    try {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:clonify/constants.dart'),
      );
      if (packageUri != null && packageUri.isScheme('file')) {
        final libFile = File(packageUri.toFilePath());
        final packageRoot = libFile.parent.parent; // .../lib/constants.dart
        final pubspecFile = File('${packageRoot.path}/pubspec.yaml');
        final version = readClonifyVersionFromPubspec(pubspecFile);
        if (version != null) return version;
      }

      // Legacy fallbacks relative to Platform.script
      if (Platform.script.isScheme('file')) {
        final scriptDir = Directory(Platform.script.toFilePath()).parent;
        for (final candidate in [
          File('${scriptDir.parent.path}/pubspec.yaml'),
          File('${scriptDir.path}/pubspec.yaml'),
        ]) {
          final version = readClonifyVersionFromPubspec(candidate);
          if (version != null) return version;
        }
      }
    } catch (_) {
      // ignore and use const fallback
    }
    return Constants.packageVersion;
  }

  String? readClonifyVersionFromPubspec(File pubspecFile) {
    if (!pubspecFile.existsSync()) return null;
    final pubspec = loadYaml(pubspecFile.readAsStringSync());
    if (pubspec is! YamlMap) return null;
    if (pubspec['name']?.toString() != 'clonify') return null;
    return pubspec['version']?.toString();
  }

  @override
  Future<void> run(Iterable<String> args) async {
    // Parse arguments
    final argResults = parse(args);

    // Initialize TUI system with --no-tui flag consideration
    final noTui = argResults['no-tui'] == true;
    initializeTUI(noTui: noTui);

    if (argResults[ClonifyCommandFlags.version.name] == true) {
      final version = await getVersionFromPubspec();
      print('${Constants.toolName} version $version');
      return;
    }

    const skipValidation = {ClonifyCommands.init, ClonifyCommands.list};
    final firstArg = args.isEmpty ? null : args.first;
    final shouldSkipValidation =
        firstArg == null ||
        args.contains('--help') ||
        args.contains('-h') ||
        skipValidation.any((c) => c.name == firstArg);

    if (!shouldSkipValidation && !validatedClonifySettings(isSilent: true)) {
      throw CustomException('Validation Failed !');
    }

    return super.run(args);
  }
}

/// Base command wired to a [ClonifyCommands] enum value.
abstract class ClonifyBaseCommand extends Command<void> {
  ClonifyCommands get command;

  @override
  String get name => command.name;

  @override
  String get description => command.description;

  @override
  List<String> get aliases => command.aliases;
}

/// Resolves `--clientId`, falling back to the last used client when needed.
///
/// - [preferLastWithoutPrompt]: use last client silently (e.g. Shorebird).
/// - otherwise, when [skipAll] is false, ask before reusing last client.
Future<String> resolveClientIdOrThrow({
  String? provided,
  bool skipAll = false,
  bool preferLastWithoutPrompt = false,
  String? missingMessage,
}) async {
  if (provided != null && provided.isNotEmpty) return provided;

  final lastClientId = await getLastClientId();
  if (lastClientId == null || lastClientId.isEmpty) {
    throw CustomException(missingMessage ?? Messages.clientIdRequired);
  }

  if (preferLastWithoutPrompt) return lastClientId;

  if (!skipAll) {
    final answer = prompt(Messages.useLastClientIdMessage(lastClientId));
    if (answer.toLowerCase() == 'y') return lastClientId;
  }

  throw CustomException(missingMessage ?? Messages.clientIdRequired);
}

class InitializeCommand extends ClonifyBaseCommand {
  @override
  ClonifyCommands get command => ClonifyCommands.init;

  @override
  Future<void> run() => initClonify();
}

class CreateCommand extends ClonifyBaseCommand {
  @override
  ClonifyCommands get command => ClonifyCommands.create;

  @override
  Future<void> run() => createClone();
}

class WhichCommand extends ClonifyBaseCommand {
  @override
  ClonifyCommands get command => ClonifyCommands.which;

  @override
  Future<void> run() => getCurrentCloneConfig();
}

/// Commands that accept a `--clientId` option.
abstract class ClientIdCommand extends ClonifyBaseCommand {
  ClientIdCommand({bool mandatory = true}) {
    argParser.addClientIdOption(mandatory: mandatory);
  }
}

class ConfigureCommand extends ClientIdCommand {
  ConfigureCommand() : super(mandatory: false) {
    argParser.addClonifyFlags(const [
      ClonifyCommandFlags.skipAll,
      ClonifyCommandFlags.autoUpdate,
      ClonifyCommandFlags.isDebug,
      ClonifyCommandFlags.skipFirebaseConfigure,
      ClonifyCommandFlags.skipShorebirdConfigure,
      ClonifyCommandFlags.skipPubUpdate,
      ClonifyCommandFlags.skipVersionUpdate,
    ]);
  }

  @override
  ClonifyCommands get command => ClonifyCommands.configure;

  @override
  Future<void> run() async {
    final model = ConfigureCommandModel.fromArgs(argResults);
    model.clientId = await resolveClientIdOrThrow(
      provided: model.clientId,
      skipAll: model.skipAll,
    );
    await configureApp(model);
  }
}

/// Configures a clone then runs Shorebird (`release` / `patch`).
///
/// ```bash
/// clonify shorebird --clientId my_client -- release android
/// clonify shorebird --clientId my_client -- patch ios
/// ```
class ShorebirdCommand extends ClientIdCommand {
  ShorebirdCommand() : super(mandatory: false) {
    argParser.addClonifyFlag(
      ClonifyCommandFlags.skipFirebaseConfigure,
      defaultsTo: true,
    );
  }

  @override
  ClonifyCommands get command => ClonifyCommands.shorebird;

  @override
  Future<void> run() async {
    final clientId = await resolveClientIdOrThrow(
      provided: argResults?.clientId,
      preferLastWithoutPrompt: true,
    );

    final shorebirdArgs = argResults!.rest;
    if (shorebirdArgs.isEmpty) {
      throw CustomException(
        'Missing Shorebird args.\n'
        'Example: clonify shorebird --clientId $clientId -- release android\n'
        '         clonify shorebird --clientId $clientId -- patch ios',
      );
    }

    if (!clonifySettings.shorebirdEnabled) {
      throw CustomException(
        'Shorebird is disabled. Set shorebird.enabled: true in '
        'clonify/clonify_settings.yaml',
      );
    }

    final configFile = File(Constants.configFilePath(clientId));
    if (!configFile.existsSync()) {
      throw CustomException('Clone config not found: ${configFile.path}');
    }

    final configJson =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final packageName = (configJson['packageName'] as String?)?.trim() ?? '';
    final shorebirdAppId = resolveShorebirdAppId(configJson);

    if (packageName.isEmpty) {
      throw CustomException('packageName missing in ${configFile.path}');
    }
    if (shorebirdAppId.isEmpty) {
      throw CustomException('shorebirdAppId missing in ${configFile.path}');
    }

    final skipFirebase = argResults!.clonifyFlag(
      ClonifyCommandFlags.skipFirebaseConfigure,
    );

    logger.i('🚀 Configuring clone "$clientId" before Shorebird...');
    await configureApp(
      ConfigureCommandModel()
        ..clientId = clientId
        ..skipAll = true
        ..skipFirebaseConfigure = skipFirebase
        ..skipShorebirdConfigure = false,
    );

    assertBundleIdMatches(
      shorebirdArgs: shorebirdArgs,
      expectedPackageName: packageName,
    );
    assertShorebirdAppIdMatches(shorebirdAppId);

    logger.i(
      '🐦 Running shorebird ${shorebirdArgs.join(' ')} '
      '(app_id=$shorebirdAppId, package=$packageName, clientId=$clientId)',
    );
    await execShorebird(shorebirdArgs);
  }
}

class BuildCommand extends ClientIdCommand {
  BuildCommand() : super(mandatory: false) {
    argParser.addClonifyFlags(const [
      ClonifyCommandFlags.skipAll,
      ClonifyCommandFlags.buildAab,
      ClonifyCommandFlags.buildApk,
      ClonifyCommandFlags.buildIpa,
      ClonifyCommandFlags.skipBuildCheck,
    ]);
  }

  @override
  ClonifyCommands get command => ClonifyCommands.build;

  @override
  Future<void> run() async {
    final model = BuildCommandModel.fromArgs(argResults);
    model.clientId = await resolveClientIdOrThrow(
      provided: model.clientId,
      skipAll: model.skipAll,
      missingMessage: Messages.clientIdRequiredForBuilding,
    );
    await buildApps(model);
  }
}

class CleanCommand extends ClientIdCommand {
  CleanCommand() : super(mandatory: true);

  @override
  ClonifyCommands get command => ClonifyCommands.clean;

  @override
  Future<void> run() async {
    final clientId = await resolveClientIdOrThrow(
      provided: argResults?.clientId,
      preferLastWithoutPrompt: true,
    );
    try {
      await cleanupPartialClone(clientId);
    } catch (e) {
      throw CustomException(
        'Failed to clean up the clone for client ID "$clientId": $e',
      );
    }
  }
}

class UploadCommand extends ClientIdCommand {
  UploadCommand() : super(mandatory: false) {
    argParser.addClonifyFlags(const [
      ClonifyCommandFlags.skipAll,
      ClonifyCommandFlags.skipAndroidUploadCheck,
      ClonifyCommandFlags.skipIOSUploadCheck,
    ]);
  }

  @override
  ClonifyCommands get command => ClonifyCommands.upload;

  @override
  Future<void> run() async {
    final results = argResults!;
    final clientId = await resolveClientIdOrThrow(
      provided: results.clientId,
      skipAll: results.clonifyFlag(ClonifyCommandFlags.skipAll),
    );
    try {
      await uploadApps(
        clientId,
        skipAll: results.clonifyFlag(ClonifyCommandFlags.skipAll),
        skipAndroidUploadCheck: results.clonifyFlag(
          ClonifyCommandFlags.skipAndroidUploadCheck,
        ),
        skipIOSUploadCheck: results.clonifyFlag(
          ClonifyCommandFlags.skipIOSUploadCheck,
        ),
      );
    } catch (error) {
      throw CustomException(Messages.failedToUploadClone(clientId, error));
    }
  }
}

class ListCommand extends ClonifyBaseCommand {
  @override
  ClonifyCommands get command => ClonifyCommands.list;

  @override
  Future<void> run() async => listClients();
}

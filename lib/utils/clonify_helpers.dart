// ignore_for_file: unnecessary_string_interpolations, missing_whitespace_between_adjacent_strings, avoid_print

import 'dart:io';
import 'dart:convert';

import 'package:clonify/utils/clone_manager.dart';
import 'package:logger/logger.dart';

// Future<void> runParallelCommands(
//   List<Future<void> Function()> commands,
//   List<String> loadingMessages,
// ) async {
//   if (commands.length != loadingMessages.length) {
//     throw ArgumentError(
//         'Commands and loading messages must have the same length.');
//   }
//   // Create progress indicators for all commands
//   final tasks = List.generate(commands.length, (index) {
//     final stopwatch = Stopwatch()..start();
//     final progress =
//         Stream.periodic(const Duration(milliseconds: 100), (count) {
//       return "🛠 ${loadingMessages[index]} [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]";
//     });
//     final progressSubscription = progress.listen((message) {
//       stdout.write('\r$message');
//     });
//     // Run the command
//     return commands[index]().whenComplete(() {
//       progressSubscription.cancel();
//       stdout.write('\r'); // Clear the line
//       logger.i(
//           "✅ ${loadingMessages[index]} completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.");
//       stopwatch.stop();
//     });
//   });
//   await Future.wait(tasks); // Wait for all commands to finish
// }

final Logger logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
);

/// Sanitizes a command argument to prevent command injection.
/// Only allows alphanumeric, dash, underscore, dot, and slash.
String sanitizeArg(String arg) {
  final safe = RegExp(r'^[\w\-.\/]+$');
  if (!safe.hasMatch(arg)) {
    throw ArgumentError('Unsafe argument detected: $arg');
  }
  return arg;
}

Future<void> runCommand(
  String command,
  List<String> args, {
  String? successMessage,
  bool showLoading = true,
  String? loadingMessage,
  String? workingDirectory,
}) async {
  // Sanitize command and arguments
  final sanitizedCommand = sanitizeArg(command);
  final sanitizedArgs = args.map(sanitizeArg).toList();
  final sanitizedWorkingDirectory = workingDirectory != null
      ? sanitizeArg(workingDirectory)
      : null;

  if (showLoading) {
    final stopwatch = Stopwatch()..start();
    String fullCommand = '$sanitizedCommand ${sanitizedArgs.join(" ")}';
    if (fullCommand.length > 50) {
      fullCommand =
          '$sanitizedCommand ${sanitizedArgs.join(" ").substring(0, 50)}...';
    }
    final progress = Stream.periodic(const Duration(milliseconds: 100), (
      count,
    ) {
      return loadingMessage != null
          ? "🛠 $loadingMessage [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]"
          : "🛠 Running $fullCommand [${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]";
    });

    // Print progress indicator in a loop
    final progressSubscription = progress.listen((message) {
      stdout.write('\r$message'); // Overwrite the same line in the terminal
    });

    try {
      final result = await Process.run(
        sanitizedCommand,
        sanitizedArgs,
        runInShell: true,
        workingDirectory: sanitizedWorkingDirectory,
      );
      progressSubscription.cancel(); // Stop the progress indicator
      stdout.write('\r'); // Clear the line

      if (result.exitCode == 0) {
        stopwatch.stop();
        logger.i(
          successMessage != null
              ? "$successMessage ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s"
              : '✅ Command completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.',
        );
      } else {
        throw Exception(
          '❌ Command failed: $sanitizedCommand ${sanitizedArgs.join(" ")}\nError: ${result.stderr}',
        );
      }
    } catch (e) {
      progressSubscription.cancel();
      stdout.write('\r'); // Clear the line
      logger.e(e);
    }
  } else {
    try {
      final result = await Process.run(
        sanitizedCommand,
        sanitizedArgs,
        runInShell: true,
        workingDirectory: sanitizedWorkingDirectory,
      );

      if (result.exitCode == 0) {
        logger.i('\r${successMessage ?? '✅ Command completed successfully.'}');
      } else {
        throw Exception(
          '❌ Command failed: $sanitizedCommand ${sanitizedArgs.join(" ")}\nError: ${result.stderr}',
        );
      }
    } catch (e) {
      logger.e(e);
    }
  }
}

String toTitleCase(String text) {
  return text[0].toUpperCase() + text.substring(1);
}

String prompt(String message, {String? skipValue, bool? skip}) {
  logger.i('$message ');
  if (skip == true) {
    logger.i('>>| Skipping with (${skipValue ?? ''})...');
    return skipValue!;
  }
  return stdin.readLineSync() ?? '';
}

String promptUser(
  String promptMessage,
  String defaultValue, {
  bool Function(String)? validator,
  bool? skip,
  String? skipValue,
}) {
  if (skip == true) {
    logger.i(
      '$promptMessage (Default: $defaultValue) >>| Skipping with (${skipValue ?? defaultValue})...',
    );

    return skipValue ?? defaultValue;
  }
  final answer = prompt(
    '$promptMessage (Default: $defaultValue) [Enter for default]:',
  );
  if (answer.isEmpty) {
    return defaultValue;
  }
  if (validator != null && !validator(answer)) {
    logger.e('❌ Invalid input. Please try again.');
    return promptUser(promptMessage, defaultValue, validator: validator);
  }
  return answer;
}

String getArgValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1 || index + 1 >= args.length) {
    throw ArgumentError('Missing value for $key');
  }
  return args[index + 1];
}

String newLineArrow([int tabs = 3]) {
  return '\n${'\t' * tabs}└─-➜';
}

void printUsage() {
  logger.i('Clonify CLI - A tool for managing Flutter app clones');
  logger.i('');
  logger.i('Usage: clonify <command> [options]');
  logger.i('');

  logger.i('Commands:');
  logger.i(
    '  create                                              Create a new clone.',
  );
  logger.i(
    '  configure | con | config | c [--clientId <id>]      Configure the app for the specified client ID.',
  );
  logger.i(
    '  clean | clear [--clientId <id>]                     Clean up a partial clone for the specified client ID.',
  );
  logger.i(
    '  build | b [--clientId <id>]                         Build the clone for the specified client ID.',
  );
  logger.i(
    '  upload | up | u [--clientId <id>]                   Upload the clone for the specified client ID.',
  );
  logger.i(
    '  list | ls                                           List all available clones.',
  );
  logger.i(
    '  which | current | who                               Get the current clone configuration.',
  );
  logger.i(
    '  help | -h | --help                                  Print this help message.',
  );
  logger.i('');

  logger.i('Options:');
  logger.i('  The following options can be used with specific commands:');
  logger.i('');

  logger.i('  For "configure" command:');
  logger.i(
    '    --clientId | -id <id>                             Specify the client ID for the command.',
  );
  logger.i(
    '    --skip-all | -SA                                  Skip all user prompts.',
  );
  logger.i(
    '    --auto-update | -AU                               Auto update the clone version.',
  );
  logger.i(
    '    --skip-firebase-configure | -SF                   Skip the Firebase configuration.',
  );
  logger.i(
    '    --skip-version | -SV                              Skip config file empty version check.',
  );
  logger.i(
    '    --skip-pub-update | -SPU                          Auto update pub version.',
  );
  logger.i(
    '    --skip-version-update | -SVU                      Skip the config version update prompt unless --auto-update is used.',
  );
  logger.i('');

  logger.i('  For "build" command:');
  logger.i(
    '    --clientId | -id <id>                             Specify the client ID for the command.',
  );
  logger.i(
    '    --skip-all | -SA                                  Skip all user prompts and build both Android and iOS clones.',
  );
  logger.i(
    '    --skip-build-check | -SBC                         Skip the confirmation check before building.',
  );
  logger.i(
    '    --upload-all | -UALL                              Build and upload both Android and iOS clones.',
  );
  logger.i(
    '    --upload-android | -UA                            Upload the Android clone after building.',
  );
  logger.i(
    '    --upload-ios | -UI                                Upload the iOS clone after building.',
  );
  logger.i('');

  logger.i('Note:');
  logger.i(
    '  - For commands that accept --clientId, if it is not provided, the last configured client ID will be used if available.',
  );
  logger.i(
    '  - Options can be combined, but some may conflict (e.g., --skip-all and --upload-all).',
  );
  logger.i('');

  logger.i('Examples:');
  logger.i('  clonify create');
  logger.i('  clonify configure --clientId <id> --skip-all');
  logger.i('  clonify clean --clientId <id>');
  logger.i('  clonify build --clientId <id> --skip-build-check');
  logger.i('  clonify upload --clientId <id> --upload-all');
  logger.i('  clonify list');
  logger.i('  clonify which');
}

String? getArgumentValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1 || index + 1 >= args.length) {
    // throw ArgumentError('Missing value for argument: $key');
    return null;
  }
  return args[index + 1];
}

Future<void> saveLastClientId(String clientId) async {
  final file = File('./clonify/last_client.txt');
  await file.writeAsString(clientId);
}

Future<String?> getLastClientId([
  String lastClientFilePath = './clonify/last_client.txt',
]) async {
  final file = File(lastClientFilePath);
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  return null;
}

Future<Map<String, dynamic>?> getLastConfig() async {
  final file = File('./clonify/last_config.json');
  if (file.existsSync()) {
    return jsonDecode(await file.readAsString());
  }
  return null;
}

String versionNumberIncrementor(String version) {
  final versionParts = version.split('+');
  final versionNumbers = versionParts[0].split('.');
  final buildNumber = int.parse(versionParts.last) + 1;
  versionNumbers[versionNumbers.length - 1] =
      (int.parse(versionNumbers.last) + 1).toString();
  final unifiedNumber = int.parse(versionNumbers.last) > buildNumber
      ? int.parse(versionNumbers.last)
      : buildNumber;
  versionNumbers[versionNumbers.length - 1] = unifiedNumber.toString();
  final newVersion = '${versionNumbers.join('.')}+$unifiedNumber';
  return newVersion;
}

Future<String> getAppBundleId(String clientId) async {
  final Map<String, dynamic> configJson = await parseConfigFile(clientId);
  return configJson['packageName'] ?? '';
}

// ✅ Get version from config.json
Future<String> getVersionFromConfig(String clientId) async {
  final configFilePath = './clonify/clones/$clientId/config.json';
  try {
    final configFile = File(configFilePath);
    if (!configFile.existsSync()) {
      logger.e('❌ Config file not found.');
      return '';
    }

    final configJson = await parseConfigFile('config');
    if (configJson['version'] == null) {
      // If version is not found, update the version in config.json
      logger.e('❌ Version not found in config.json.');
      final newVersion = promptUser('Enter the version number:', '1.0.0+1');
      configJson['version'] = newVersion;
      configFile.writeAsStringSync(jsonEncode(configJson));
    }
    return configJson['version'] ?? '';
  } catch (e) {
    logger.e('❌ Failed to read or parse config.json: $e');
    return '';
  }
}

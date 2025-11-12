// ignore_for_file: unnecessary_string_interpolations, missing_whitespace_between_adjacent_strings, avoid_print

import 'dart:io';
import 'dart:convert';

import 'package:clonify/models/clonify_settings_model.dart';
import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/tui_helpers.dart';
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

final ClonifySettings clonifySettings = getClonifySettings();

/// Sanitizes a command-line argument to prevent command injection vulnerabilities.
///
/// This function ensures that an argument only contains safe characters
/// (alphanumeric, dash, underscore, dot, and slash). Arguments matching
/// a predefined list of known safe commands are skipped from sanitization.
///
/// Throws an [ArgumentError] if an unsafe argument is detected and not skipped.
///
/// Returns the sanitized or skipped argument string.
String sanitizeArg(String arg) {
  //⛔ ❌ Error during build commands: Invalid argument(s): Unsafe argument detected: flutter_native_splash:create
  final List<String> skipSanitization = [
    'flutter_native_splash:create',
    'flutter_launcher_icons:generate',
    'flutter_launcher_icons',
    'intl_utils:generate',
  ];
  if (skipSanitization.contains(arg)) {
    return arg;
  }
  final safe = RegExp(r'^[\w\-.\/]+$');
  if (!safe.hasMatch(arg)) {
    throw ArgumentError('Unsafe argument detected: $arg');
  }
  return arg;
}

/// Executes a shell command with optional loading indicators and error handling.
///
/// This function sanitizes the [command] and [args] to prevent command injection.
/// It can display a progress indicator while the command is running and
/// logs success or error messages upon completion.
///
/// [command] The executable command to run (e.g., 'flutter', 'dart').
/// [args] A list of string arguments to pass to the command.
/// [successMessage] An optional message to display on successful command execution.
/// [showLoading] If `true`, a loading indicator with elapsed time will be shown. Defaults to `true`.
/// [loadingMessage] An optional custom message to display during loading.
/// [workingDirectory] The directory in which to run the command. If `null`, the current
///                    working directory of the process is used.
///
/// Throws an [Exception] if the command fails (returns a non-zero exit code).
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

/// Converts the first character of a given string to uppercase.
///
/// This function takes a [text] string and returns a new string where
/// the first character is converted to uppercase, and the rest of the
/// string remains unchanged.
///
/// Returns the string with its first character in uppercase.
String toTitleCase(String text) {
  return text[0].toUpperCase() + text.substring(1);
}

/// Displays a message to the user and waits for their input.
///
/// This function prints the [message] to the console and reads a line
/// of input from `stdin`. If [skip] is `true`, it will use [skipValue]
/// (or an empty string if [skipValue] is `null`) and log that it's skipping
/// the prompt, without waiting for user input.
///
/// [message] The message to display to the user.
/// [skipValue] An optional value to return if [skip] is `true`.
/// [skip] A boolean indicating whether to skip the prompt and use [skipValue].
///
/// Returns the user's input or [skipValue] if the prompt is skipped.
String prompt(String message, {String? skipValue, bool? skip}) {
  logger.i('$message ');
  if (skip == true) {
    logger.i('>>| Skipping with (${skipValue ?? ''})...');
    return skipValue!;
  }
  return stdin.readLineSync() ?? '';
}

/// Prompts the user for input with a default value and optional validation.
///
/// This function displays a [promptMessage] to the user, optionally showing
/// a [defaultValue]. It reads user input and, if the input is empty,
/// uses the [defaultValue]. The input can be validated using a [validator]
/// function, and the user will be re-prompted on invalid input.
///
/// If [skip] is `true`, the function will return [skipValue] (or [defaultValue]
/// if [skipValue] is `null`) without prompting the user.
///
/// [promptMessage] The message to display to the user.
/// [defaultValue] The default value to use if the user provides no input.
/// [validator] An optional function to validate the user's input.
/// [skip] A boolean indicating whether to skip the prompt.
/// [skipValue] An optional value to return if [skip] is `true`.
///
/// Returns the validated user input or the default/skip value.
String promptUser(
  String promptMessage,
  String defaultValue, {
  bool Function(String)? validator,
  bool? skip,
  String? skipValue,
}) {
  if (skip == true) {
    logger.i(
      '$promptMessage >>| Skipping with (${skipValue ?? defaultValue})...',
    );

    return skipValue ?? defaultValue;
  }
  final answer = prompt(
    '$promptMessage ${defaultValue.isNotEmpty ? '(Default: $defaultValue) [Enter for default]' : ''}:',
  );
  if (answer.isEmpty && defaultValue.isNotEmpty) {
    return defaultValue;
  }
  if (validator != null && !validator(answer)) {
    logger.e('❌ Invalid input. Please try again.');
    return promptUser(promptMessage, defaultValue, validator: validator);
  }
  return answer;
}

// ============================================================================
// TUI-Enhanced Prompt Functions
// ============================================================================

/// TUI-enhanced version of [promptUser] with better interactive experience.
///
/// Uses mason_logger for enhanced prompting when TUI is enabled.
/// Falls back to basic [promptUser] when TUI is disabled or --skipAll is used.
///
/// [promptMessage] The message to display to the user.
/// [defaultValue] The default value to use if the user provides no input.
/// [validator] An optional function to validate the user's input.
/// [skip] A boolean indicating whether to skip the prompt.
/// [skipValue] An optional value to return if [skip] is `true`.
///
/// Returns the validated user input or the default/skip value.
String promptUserTUI(
  String promptMessage,
  String defaultValue, {
  bool Function(String)? validator,
  bool? skip,
  String? skipValue,
}) {
  // Use basic prompt if skipping or TUI is disabled
  if (skip == true || !isTUIEnabled()) {
    return promptUser(
      promptMessage,
      defaultValue,
      validator: validator,
      skip: skip,
      skipValue: skipValue,
    );
  }

  // Use TUI-enhanced prompt
  while (true) {
    final answer = promptWithTUI(
      promptMessage,
      defaultValue: defaultValue.isNotEmpty ? defaultValue : null,
    );

    final value = answer.isEmpty ? defaultValue : answer;

    // Validate if validator is provided
    if (validator != null && !validator(value)) {
      errorMessage('Invalid input. Please try again.');
      continue;
    }

    return value;
  }
}

/// TUI-enhanced confirmation prompt.
///
/// Uses mason_logger for yes/no confirmations with better UX.
/// Falls back to basic stdin when TUI is disabled.
///
/// [message] The confirmation message to display.
/// [defaultValue] The default value if user just presses Enter.
/// [skip] A boolean indicating whether to skip the prompt.
///
/// Returns true if user confirms, false otherwise.
bool confirmTUI(
  String message, {
  bool defaultValue = false,
  bool? skip,
}) {
  if (skip == true) {
    logger.i('$message >>| Skipping with ($defaultValue)...');
    return defaultValue;
  }

  if (!isTUIEnabled()) {
    // Fallback to basic confirmation
    final answer = promptUser(
      message,
      defaultValue ? 'y' : 'n',
      validator: (input) {
        final normalized = input.toLowerCase();
        return normalized == 'y' || normalized == 'n' ||
               normalized == 'yes' || normalized == 'no';
      },
    );
    return answer.toLowerCase() == 'y' || answer.toLowerCase() == 'yes';
  }

  return confirmWithTUI(message, defaultValue: defaultValue);
}

/// TUI-enhanced single-choice selection.
///
/// Uses mason_logger for arrow-key navigation when TUI is enabled.
/// Falls back to numbered list selection when TUI is disabled.
///
/// [message] The selection prompt message.
/// [choices] List of options to choose from.
/// [defaultValue] The default selection.
///
/// Returns the selected option or null if cancelled.
String? selectOneTUI(
  String message,
  List<String> choices, {
  String? defaultValue,
}) {
  if (choices.isEmpty) {
    errorMessage('No choices available');
    return null;
  }

  return chooseOneWithTUI(message, choices, defaultValue: defaultValue);
}

/// TUI-enhanced multi-choice selection.
///
/// Uses mason_logger for checkbox-based selection when TUI is enabled.
/// Falls back to numbered list with comma-separated input when TUI is disabled.
///
/// [message] The selection prompt message.
/// [choices] List of options to choose from.
/// [defaultValues] The default selections.
///
/// Returns the list of selected options.
List<String> selectManyTUI(
  String message,
  List<String> choices, {
  List<String>? defaultValues,
}) {
  if (choices.isEmpty) {
    errorMessage('No choices available');
    return [];
  }

  return chooseAnyWithTUI(message, choices, defaultValues: defaultValues);
}

/// Retrieves the value associated with a specific command-line argument key.
///
/// This function searches the [args] list for the given [key] (e.g., '--clientId').
/// If the key is found, it returns the value immediately following it in the list.
///
/// [args] The list of command-line arguments.
/// [key] The argument key to search for.
///
/// Throws an [ArgumentError] if the [key] is found but no value is provided
/// after it.
///
/// Returns the string value associated with the argument key.
String getArgValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1 || index + 1 >= args.length) {
    throw ArgumentError('Missing value for $key');
  }
  return args[index + 1];
}

/// Generates a formatted string with a newline, indentation, and an arrow symbol.
///
/// This utility function creates a string that starts with a newline character,
/// followed by a specified number of tab characters for indentation, and
/// then an arrow symbol `└─-➜`. It's typically used for formatting CLI output.
///
/// [tabs] The number of tab characters to use for indentation. Defaults to 3.
///
/// Returns a formatted string for CLI output.
String newLineArrow([int tabs = 3]) {
  return '\n${'\t' * tabs}└─-➜';
}

/// Prints the usage information and available commands for the Clonify CLI tool.
///
/// This function outputs a formatted help message to the console, detailing
/// the general usage, a list of all available commands with their descriptions
/// and aliases, and specific options that can be used with the `configure`
/// and `build` commands. It also includes notes and examples for common use cases.
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

/// Retrieves the value associated with a specific command-line argument key.
///
/// This function searches the [args] list for the given [key] (e.g., '--clientId').
/// If the key is found and a value is present immediately after it, that value is returned.
/// Unlike `getArgValue` which throws an error, this function returns `null`
/// if the key is not found or if no value is associated with it.
///
/// [args] The list of command-line arguments.
/// [key] The argument key to search for.
///
/// Returns the string value associated with the argument key, or `null` if
/// the key is not found or its value is missing.
String? getArgumentValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1 || index + 1 >= args.length) {
    // throw ArgumentError('Missing value for argument: $key');
    return null;
  }
  return args[index + 1];
}

/// Saves the last used client ID to a file.
///
/// This function writes the provided [clientId] to the `last_client.txt` file
/// located in the `./clonify/` directory. This allows the CLI to remember
/// the last active client for convenience.
///
/// Note: This function is duplicated in `clonify_core.dart`. Consider refactoring.
///
/// Throws a [FileSystemException] if the file cannot be written.
Future<void> saveLastClientId(String clientId) async {
  final file = File('./clonify/last_client.txt');
  await file.writeAsString(clientId);
}

/// Retrieves the last used client ID from a file.
///
/// This function reads the `last_client.txt` file from the `./clonify/`
/// directory to retrieve the last active client ID.
///
/// [lastClientFilePath] The path to the file storing the last client ID.
/// Defaults to `./clonify/last_client.txt`.
///
/// Note: This function is duplicated in `clonify_core.dart`. Consider refactoring.
///
/// Returns a `Future<String?>` which is the last saved client ID, or `null`
/// if the file does not exist.
///
/// Throws a [FileSystemException] if the file exists but cannot be read.
Future<String?> getLastClientId([
  String lastClientFilePath = './clonify/last_client.txt',
]) async {
  final file = File(lastClientFilePath);
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  return null;
}

/// Retrieves the last saved configuration map from a JSON file.
///
/// This function reads the `last_config.json` file from the `./clonify/`
/// directory, decodes its JSON content, and returns it as a map.
///
/// Note: This function is duplicated in `clonify_core.dart`. Consider refactoring.
///
/// Returns a `Future<Map<String, dynamic>?>` which is the last saved
/// configuration, or `null` if the file does not exist.
///
/// Throws a [FileSystemException] if the file exists but cannot be read,
/// or a [FormatException] if the file content is not valid JSON.
Future<Map<String, dynamic>?> getLastConfig() async {
  final file = File('./clonify/last_config.json');
  if (file.existsSync()) {
    return jsonDecode(await file.readAsString());
  }
  return null;
}

/// Increments the patch version and build number of a semantic version string.
///
/// This function takes a semantic version string (e.g., "1.0.0+1") and
/// increments its patch version number and build number. If the new patch
/// version is greater than the new build number, the patch version is used
/// as the unified number; otherwise, the build number is used.
///
/// [version] The semantic version string to increment.
///
/// Returns a new semantic version string with the incremented numbers.
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

/// Retrieves the application bundle ID (package name) for a given client ID.
///
/// This function reads the configuration file for the specified [clientId],
/// parses it, and extracts the `packageName` field, which represents the
/// application's bundle ID.
///
/// [clientId] The ID of the client for which to retrieve the bundle ID.
///
/// Throws a [FileSystemException] if the config file for the client is not found.
/// Throws a [FormatException] if the config file content is not valid JSON.
///
/// Returns a `Future<String>` representing the application's bundle ID.
Future<String> getAppBundleId(String clientId) async {
  final Map<String, dynamic> configJson = await parseConfigFile(clientId);
  return configJson['packageName'] ?? '';
}

/// Retrieves the version number from a client's configuration file.
///
/// This function reads the `config.json` file for the specified [clientId].
/// If the 'version' field is missing, it prompts the user to enter a new
/// version and updates the configuration file.
///
/// [clientId] The ID of the client for which to retrieve the version.
///
/// Throws a [FileSystemException] if the config file for the client is not found.
/// Throws a [FormatException] if the config file content is not valid JSON.
///
/// Returns a `Future<String>` representing the version number.
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

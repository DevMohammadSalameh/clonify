// ignore_for_file: unnecessary_string_interpolations, missing_whitespace_between_adjacent_strings, avoid_print

import 'dart:io';
import 'dart:convert';

import 'package:clonify/utils/clone_manager.dart';

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
//       print(
//           "✅ ${loadingMessages[index]} completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.");
//       stopwatch.stop();
//     });
//   });
//   await Future.wait(tasks); // Wait for all commands to finish
// }

Future<void> runCommand(
  String command,
  List<String> args, {
  String? successMessage,
  bool showLoading = true,
  String? loadingMessage,
  String? workingDirectory,
}) async {
  if (showLoading) {
    final stopwatch = Stopwatch()..start();
    String fullCommand = '$command ${args.join(" ")}';
    if (fullCommand.length > 50) {
      fullCommand = '$command ${args.join(" ").substring(0, 50)}...';
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
        command,
        args,
        runInShell: true,
        workingDirectory: workingDirectory,
      );
      progressSubscription.cancel(); // Stop the progress indicator
      stdout.write('\r'); // Clear the line

      if (result.exitCode == 0) {
        stopwatch.stop();
        print(
          successMessage != null
              ? "$successMessage ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s"
              : '✅ Command completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s.',
        );
      } else {
        throw Exception(
          '❌ Command failed: $command ${args.join(" ")}\nError: ${result.stderr}',
        );
      }
    } catch (e) {
      progressSubscription.cancel();
      stdout.write('\r'); // Clear the line
      print(e);
    }
  } else {
    try {
      final result = await Process.run(
        command,
        args,
        runInShell: true,
        workingDirectory: workingDirectory,
      );

      if (result.exitCode == 0) {
        print('\r${successMessage ?? '✅ Command completed successfully.'}');
      } else {
        throw Exception(
          '❌ Command failed: $command ${args.join(" ")}\nError: ${result.stderr}',
        );
      }
    } catch (e) {
      print(e);
    }
  }
}

String toTitleCase(String text) {
  return text[0].toUpperCase() + text.substring(1);
}

String prompt(String message, {String? skipValue, bool? skip}) {
  stdout.write('$message ');
  if (skip == true) {
    print('>>| Skipping with (${skipValue ?? ''})...');
    return skipValue ?? '';
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
    print(
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
    print('❌ Invalid input. Please try again.');
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
  print('Clonify CLI - A tool for managing Flutter app clones');
  print('');
  print('Usage: clonify <command> [options]');
  print('');

  print('Commands:');
  print(
    '  create                                              Create a new clone.',
  );
  print(
    '  configure | con | config | c [--clientId <id>]      Configure the app for the specified client ID.',
  );
  print(
    '  clean | clear [--clientId <id>]                     Clean up a partial clone for the specified client ID.',
  );
  print(
    '  build | b [--clientId <id>]                         Build the clone for the specified client ID.',
  );
  print(
    '  upload | up | u [--clientId <id>]                   Upload the clone for the specified client ID.',
  );
  print(
    '  list | ls                                           List all available clones.',
  );
  print(
    '  which | current | who                               Get the current clone configuration.',
  );
  print(
    '  help | -h | --help                                  Print this help message.',
  );
  print('');

  print('Options:');
  print('  The following options can be used with specific commands:');
  print('');

  print('  For "configure" command:');
  print(
    '    --clientId | -id <id>                             Specify the client ID for the command.',
  );
  print(
    '    --skip-all | -SA                                  Skip all user prompts.',
  );
  print(
    '    --auto-update | -AU                               Auto update the clone version.',
  );
  print(
    '    --skip-firebase-configure | -SF                   Skip the Firebase configuration.',
  );
  print(
    '    --skip-version | -SV                              Skip config file empty version check.',
  );
  print(
    '    --skip-pub-update | -SPU                          Auto update pub version.',
  );
  print(
    '    --skip-version-update | -SVU                      Skip the config version update prompt unless --auto-update is used.',
  );
  print('');

  print('  For "build" command:');
  print(
    '    --clientId | -id <id>                             Specify the client ID for the command.',
  );
  print(
    '    --skip-all | -SA                                  Skip all user prompts and build both Android and iOS clones.',
  );
  print(
    '    --skip-build-check | -SBC                         Skip the confirmation check before building.',
  );
  print(
    '    --upload-all | -UALL                              Build and upload both Android and iOS clones.',
  );
  print(
    '    --upload-android | -UA                            Upload the Android clone after building.',
  );
  print(
    '    --upload-ios | -UI                                Upload the iOS clone after building.',
  );
  print('');

  print('Note:');
  print(
    '  - For commands that accept --clientId, if it is not provided, the last configured client ID will be used if available.',
  );
  print(
    '  - Options can be combined, but some may conflict (e.g., --skip-all and --upload-all).',
  );
  print('');

  print('Examples:');
  print('  clonify create');
  print('  clonify configure --clientId <id> --skip-all');
  print('  clonify clean --clientId <id>');
  print('  clonify build --clientId <id> --skip-build-check');
  print('  clonify upload --clientId <id> --upload-all');
  print('  clonify list');
  print('  clonify which');
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

Future<String?> getLastClientId() async {
  final file = File('./clonify/last_client.txt');
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
      print('❌ Config file not found.');
      return '';
    }

    final configJson = await parseConfigFile('config');
    if (configJson['version'] == null) {
      // If version is not found, update the version in config.json
      print('❌ Version not found in config.json.');
      final newVersion = promptUser('Enter the version number:', '1.0.0+1');
      configJson['version'] = newVersion;
      configFile.writeAsStringSync(jsonEncode(configJson));
    }
    return configJson['version'] ?? '';
  } catch (e) {
    print('❌ Failed to read or parse config.json: $e');
    return '';
  }
}

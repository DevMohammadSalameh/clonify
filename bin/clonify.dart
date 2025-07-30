/// File: clonify.dart
/// Project: clonify
/// Author: Mohammad Salameh
/// Created Date: 25.09.2024
/// Description: Entry point of the clonify project for the command line.
library;

import 'dart:io';
import 'package:clonify/commands/clonify_command_runner.dart';
import 'package:clonify/custom_exceptions.dart';

/// This function is responsible for running the clonify command with the provided arguments.
/// It handles any custom exceptions that may occur during the execution of the command.
/// In case of a custom exception, the exit code is set to 1.
/// For any other exceptions, the exit code is set to 64 indicating a command line usage error.
///
/// Parameters:
/// - `arguments`: List of command line arguments passed to the application.
Future<void> main(List<String> arguments) async {
  try {
    final clonifyCommandRunner = ClonifyCommandRunner();
    await clonifyCommandRunner.run(arguments);
  } on CustomException catch (err) {
    print(err.toString());
    exitCode = 1;
  } catch (e) {
    print(e);
    exitCode = 64; // Command-line usage error
  }
}

/// File: tui_helpers.dart
/// Project: clonify
/// Author: Mohammad Salameh
/// Created Date: 12.11.2024
/// Description: TUI (Text User Interface) helper functions and wrappers
/// for enhanced interactive command-line experience using mason_logger.
library;

import 'dart:io';

import 'package:chalkdart/chalk.dart';
import 'package:mason_logger/mason_logger.dart';

/// Global TUI-enabled logger instance
late Logger tuiLogger;

/// Whether TUI features are enabled globally
bool _tuiEnabled = true;

/// Initialize the TUI system with a logger instance
///
/// This should be called once at application startup.
/// The [noTui] parameter can be used to disable TUI features globally.
void initializeTUI({bool noTui = false}) {
  _tuiEnabled = !noTui && _isTTY();

  tuiLogger = Logger(
    level: _tuiEnabled ? Level.info : Level.info,
    theme: _getLoggerTheme(),
  );
}

/// Check if TUI features are currently enabled
bool isTUIEnabled() => _tuiEnabled;

/// Check if the current environment supports TTY (terminal) features
bool _isTTY() {
  try {
    return stdin.hasTerminal && stdout.hasTerminal;
  } catch (e) {
    return false;
  }
}

/// Get a custom logger theme with enhanced styling
LogTheme _getLoggerTheme() {
  return LogTheme(
    success: (message) => chalk.green(message),
    info: (message) => chalk.blue(message),
    warn: (message) => chalk.yellow(message),
    err: (message) => chalk.red(message),
    detail: (message) => chalk.gray(message),
  );
}

/// Enhanced prompt with TUI support
///
/// Falls back to basic stdin prompt if TUI is disabled.
/// The [defaultValue] is shown in brackets and used if user presses Enter.
String promptWithTUI(
  String message, {
  String? defaultValue,
  bool hidden = false,
}) {
  if (!_tuiEnabled || !_isTTY()) {
    return _basicPrompt(message, defaultValue: defaultValue, hidden: hidden);
  }

  return tuiLogger.prompt(message, defaultValue: defaultValue, hidden: hidden);
}

/// Enhanced confirmation prompt with TUI support
///
/// Returns true if user confirms (y/yes), false otherwise.
/// Falls back to basic confirmation if TUI is disabled.
bool confirmWithTUI(String message, {bool defaultValue = false}) {
  if (!_tuiEnabled || !_isTTY()) {
    return _basicConfirm(message, defaultValue: defaultValue);
  }

  return tuiLogger.confirm(message, defaultValue: defaultValue);
}

/// Enhanced single-choice selection with TUI support
///
/// Displays a list of options and allows user to select one using arrow keys.
/// Falls back to numbered list selection if TUI is disabled.
/// Returns the selected option or null if cancelled.
String? chooseOneWithTUI(
  String message,
  List<String> choices, {
  String? defaultValue,
}) {
  if (!_tuiEnabled || !_isTTY() || choices.isEmpty) {
    return _basicChooseOne(message, choices, defaultValue: defaultValue);
  }

  return tuiLogger.chooseOne(
    message,
    choices: choices,
    defaultValue: defaultValue,
  );
}

/// Enhanced multi-choice selection with TUI support
///
/// Displays a list of options with checkboxes and allows selecting multiple.
/// Falls back to numbered list with comma-separated input if TUI is disabled.
/// Returns the list of selected options.
List<String> chooseAnyWithTUI(
  String message,
  List<String> choices, {
  List<String>? defaultValues,
}) {
  if (!_tuiEnabled || !_isTTY() || choices.isEmpty) {
    return _basicChooseAny(message, choices, defaultValues: defaultValues);
  }

  return tuiLogger.chooseAny(
    message,
    choices: choices,
    defaultValues: defaultValues,
  );
}

/// Create a progress indicator for long-running operations
///
/// Returns a Progress object that can be updated with status messages.
/// Falls back to simple text output if TUI is disabled.
Progress? progressWithTUI(String message) {
  if (!_tuiEnabled || !_isTTY()) {
    stdout.writeln(message);
    return null;
  }

  return tuiLogger.progress(message);
}

/// Display a success message with styling
void successMessage(String message) {
  if (_tuiEnabled) {
    tuiLogger.success(message);
  } else {
    stdout.writeln('✅ $message');
  }
}

/// Display an error message with styling
void errorMessage(String message) {
  if (_tuiEnabled) {
    tuiLogger.err(message);
  } else {
    stderr.writeln('❌ $message');
  }
}

/// Display a warning message with styling
void warningMessage(String message) {
  if (_tuiEnabled) {
    tuiLogger.warn(message);
  } else {
    stdout.writeln('⚠️ $message');
  }
}

/// Display an info message with styling
void infoMessage(String message) {
  if (_tuiEnabled) {
    tuiLogger.info(message);
  } else {
    stdout.writeln('ℹ️ $message');
  }
}

/// Display a detail/debug message with styling
void detailMessage(String message) {
  if (_tuiEnabled) {
    tuiLogger.detail(message);
  } else {
    stdout.writeln(message);
  }
}

// ============================================================================
// Fallback Functions (used when TUI is disabled)
// ============================================================================

/// Basic prompt without TUI features
String _basicPrompt(
  String message, {
  String? defaultValue,
  bool hidden = false,
}) {
  final prompt = defaultValue != null
      ? '$message [$defaultValue]: '
      : '$message: ';

  stdout.write(prompt);

  String? input;
  if (hidden) {
    stdin.echoMode = false;
    input = stdin.readLineSync();
    stdin.echoMode = true;
    stdout.writeln();
  } else {
    input = stdin.readLineSync();
  }

  if (input == null || input.trim().isEmpty) {
    return defaultValue ?? '';
  }

  return input.trim();
}

/// Basic confirmation without TUI features
bool _basicConfirm(String message, {bool defaultValue = false}) {
  final defaultText = defaultValue ? 'Y/n' : 'y/N';
  stdout.write('$message ($defaultText): ');

  final input = stdin.readLineSync()?.trim().toLowerCase();

  if (input == null || input.isEmpty) {
    return defaultValue;
  }

  return input == 'y' || input == 'yes';
}

/// Basic single choice without TUI features
String? _basicChooseOne(
  String message,
  List<String> choices, {
  String? defaultValue,
}) {
  stdout.writeln(message);

  for (var i = 0; i < choices.length; i++) {
    final prefix = choices[i] == defaultValue ? '❯' : ' ';
    stdout.writeln('$prefix ${i + 1}) ${choices[i]}');
  }

  final defaultIndex = defaultValue != null
      ? choices.indexOf(defaultValue) + 1
      : null;

  final prompt = defaultIndex != null
      ? 'Select (1-${choices.length}) [$defaultIndex]: '
      : 'Select (1-${choices.length}): ';

  stdout.write(prompt);
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.isEmpty) {
    return defaultValue;
  }

  final index = int.tryParse(input);
  if (index == null || index < 1 || index > choices.length) {
    return null;
  }

  return choices[index - 1];
}

/// Basic multi-choice without TUI features
List<String> _basicChooseAny(
  String message,
  List<String> choices, {
  List<String>? defaultValues,
}) {
  stdout.writeln(message);

  for (var i = 0; i < choices.length; i++) {
    final checked = defaultValues?.contains(choices[i]) ?? false;
    final prefix = checked ? '☑' : '☐';
    stdout.writeln('$prefix ${i + 1}) ${choices[i]}');
  }

  stdout.writeln('Enter numbers separated by commas (e.g., 1,3,5): ');
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.isEmpty) {
    return defaultValues ?? [];
  }

  final selected = <String>[];
  final indices = input.split(',').map((s) => int.tryParse(s.trim()));

  for (final index in indices) {
    if (index != null && index >= 1 && index <= choices.length) {
      selected.add(choices[index - 1]);
    }
  }

  return selected.isEmpty ? (defaultValues ?? []) : selected;
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Clonify is a Dart command-line tool for managing Flutter project clones. It enables creating multiple white-labeled versions of a Flutter app with different branding, configurations, and Firebase projects for different clients.

## Development Commands

### Setup & Dependencies
- **Install dependencies**: `dart pub get`
- **Build executable**: `dart compile exe bin/clonify.dart`

### Code Quality
- **Run linter**: `dart analyze`
- **Format code**: `dart format .`
- **Run all tests**: `dart test`
- **Run single test**: `dart test test/clonify_test.dart --name "<test_description>"`

### Code Style Guidelines
- **Formatting**: Use `dart format .` - strict adherence required
- **Linting**: Follow `package:lints/recommended.yaml` rules from `analysis_options.yaml`
- **Naming conventions**:
  - Classes, Enums, Type Definitions: `PascalCase`
  - Functions, Variables, Parameters: `camelCase`
  - Files: `snake_case`
- **Imports**: Organize into three groups (dart:, package:, relative) separated by blank lines
- **Typing**: Use explicit type declarations
- **Error handling**: Use try-catch blocks; throw custom exceptions for specific recoverable errors

## Architecture Overview

### Core Workflow

Clonify manages a multi-stage workflow for creating and managing client-specific Flutter app clones:

1. **Initialization** (`init` command): Sets up `./clonify/clonify_settings.yaml` with global configuration (company name, default color, Firebase/Fastlane settings, assets to clone)

2. **Clone Creation** (`create` command): Creates client-specific directory structure in `./clonify/clones/<clientId>/` containing:
   - Client-specific configuration JSON
   - Assets directory with client-specific images
   - Configuration data for colors, gradients, URLs, etc.

3. **Configuration** (`configure` command): Applies client-specific settings to the Flutter project:
   - Updates `pubspec.yaml` with client app name and version
   - Renames package using `package_rename_plus`
   - Updates launcher icons and splash screens
   - Configures Firebase (if enabled)
   - Generates `lib/generated/clone_configs.dart` with compile-time constants

4. **Build** (`build` command): Builds platform-specific artifacts (AAB, APK, IPA)

5. **Upload** (`upload` command): Uploads builds to app stores using Fastlane

### Key Architectural Patterns

**Command Pattern**: All commands extend `Command` class from `package:args`. See `lib/commands/clonify_command_runner.dart` for command registration and routing.

**Settings Validation**: `validatedClonifySettings()` in `lib/src/clonify_core.dart` validates YAML settings before command execution. Most commands (except `init`, `list`) require valid settings.

**Client ID Management**:
- Client ID is the primary identifier for all clone operations
- Stored in `./clonify/last_client.txt` for convenience
- Commands prompt to reuse last client ID if not explicitly provided
- Configuration saved to `./clonify/last_config.json`

**Generated Code Pattern**: Configuration generates `lib/generated/clone_configs.dart` with:
- Color constants (0xFF format)
- LinearGradient definitions
- Base URL, client ID, version as compile-time constants
- This allows Flutter code to reference `CloneConfigs.primaryColor`, `CloneConfigs.baseUrl`, etc.

**Manager Pattern**: Utility classes in `lib/utils/` encapsulate domain logic:
- `clone_manager.dart`: Clone creation, configuration application
- `firebase_manager.dart`: Firebase project creation and app registration
- `asset_manager.dart`: Asset copying and launcher icon/splash screen generation
- `build_manager.dart`: Platform build orchestration
- `upload_manager.dart`: Fastlane upload orchestration
- `package_rename_plus_manager.dart`: Package renaming via external tool

### Directory Structure

```
clonify/
├── bin/clonify.dart           # CLI entry point
├── lib/
│   ├── commands/              # Command implementations
│   │   └── clonify_command_runner.dart
│   ├── models/                # Data models
│   │   ├── config_model.dart  # Client clone configuration
│   │   ├── clonify_settings_model.dart
│   │   ├── color_model.dart
│   │   ├── gradient_color_model.dart
│   │   └── commands_calls_models/  # Command argument models
│   ├── utils/                 # Business logic managers
│   ├── src/                   # Core functionality
│   │   └── clonify_core.dart  # Settings validation, initialization
│   ├── enums.dart             # Command/flag/option enums with extensions
│   ├── custom_exceptions.dart # Custom exception types
│   ├── messages.dart          # User-facing message strings
│   └── constants.dart         # App constants
└── test/
    └── clonify_test.dart
```

### Runtime State & Files

- `./clonify/clonify_settings.yaml`: Global project settings (created by `init`)
- `./clonify/clones/<clientId>/config.json`: Per-client configuration
- `./clonify/clones/<clientId>/assets/`: Per-client assets
- `./clonify/last_client.txt`: Last used client ID
- `./clonify/last_config.json`: Last applied configuration
- `./lib/generated/clone_configs.dart`: Generated constants (auto-created during `configure`)

### Important Behaviors

**Cleanup on Cancellation**: Initialization and clone creation track created files/directories in `_createdPaths` and `_createdClonePaths` lists. On error or cancellation, cleanup functions remove these paths in reverse order.

**Interactive Prompts**: Commands use `prompt()` and `promptUser()` helpers for user input. The `--skipAll` flag bypasses interactive prompts where possible.

**Command Flags**: See `lib/enums.dart` for all available flags. Key flags:
- `--skipAll`: Skip all interactive prompts
- `--skipFirebaseConfigure`: Skip Firebase configuration
- `--skipPubUpdate`: Skip pubspec.yaml updates
- `--buildAab/Apk/Ipa`: Control which platforms to build
- `--skipBuildCheck`: Skip build validation

**Asset Selection**: During initialization, users select which assets from `./assets/images/` to clone for each client, designating one as launcher icon and optionally one as splash screen.

## Testing Notes

- Tests are located in `test/clonify_test.dart`
- Use `dart test` to run all tests
- Use `dart test <path> --name "<description>"` to run specific tests

## Dependencies

Key external dependencies:
- `args`: CLI argument parsing
- `logger`: Logging framework
- `yaml` and `yaml_edit`: YAML file manipulation
- `package_rename_plus`: Package renaming
- `flutter_launcher_icons`: Launcher icon generation
- `flutter_native_splash`: Splash screen generation
- `intl_utils`: Internationalization utilities

External tools required:
- Firebase CLI (for Firebase operations)
- Fastlane (for upload operations)
- Flutter SDK (for building apps)

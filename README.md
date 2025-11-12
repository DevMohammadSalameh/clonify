# Clonify

![GitHub issues](https://img.shields.io/github/issues/DevMohammadSalameh/clonify)
![GitHub pull requests](https://img.shields.io/github/issues-pr/DevMohammadSalameh/clonify)
![GitHub contributors](https://img.shields.io/github/contributors/DevMohammadSalameh/clonify)
![GitHub](https://img.shields.io/github/license/DevMohammadSalameh/clonify)

## About

A powerful command-line tool for managing multiple Flutter project clones with different configurations, branding, and Firebase projects. Perfect for white-label applications or managing multiple client-specific versions of the same Flutter app.

## Features

- 🎨 Manage multiple app variants from a single codebase
- 🔥 Optional Firebase integration per clone
- 📱 Auto-generate launcher icons and splash screens
- 📦 Rename packages and app names per clone
- 🏗️ Build multiple platforms (Android APK/AAB, iOS IPA)
- 🚀 Optional Fastlane integration for app store uploads
- 💾 Configuration persistence for easy switching between clones
- ✨ **Modern TUI (Text User Interface)** with interactive prompts and progress indicators

## Installation

### Prerequisites

- Dart SDK (^3.8.1)
- Flutter SDK (for building apps)
- Firebase CLI (optional, for Firebase features)
- Fastlane (optional, for upload features)

### Important: Required Dev Dependencies

Clonify relies on the following packages to automate asset generation and package renaming. **Add these to your Flutter project's `dev_dependencies`** for full functionality:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # Automated launcher icon generation
  flutter_native_splash: ^2.3.1     # Splash screen creation
  package_rename_plus: ^1.7.2       # Smart package renaming
  intl_utils: ^2.8.7                # Internationalization (optional)
```

**Why these are needed:**
- Clonify calls these tools as external commands to generate icons, splash screens, and rename packages
- The tool will check for their presence and warn you if they're missing
- You don't need to import them in your code - Clonify uses them automatically

### Install Globally

Install clonify globally to use it from anywhere:

```bash
# From pub.dev (once published)
dart pub global activate clonify

# Or install from source
git clone https://github.com/DevMohammadSalameh/clonify.git
cd clonify
dart pub global activate --source path .
```

Make sure your PATH includes the Dart global bin directory:
- macOS/Linux: `~/.pub-cache/bin`
- Windows: `%LOCALAPPDATA%\Pub\Cache\bin`

Verify installation:
```bash
clonify --version  # or clonify -v
clonify --help
```

## User Interface

Clonify features a modern **Text User Interface (TUI)** that enhances your development experience with:

### Interactive Prompts
- 🎯 **Arrow-key navigation** for selecting options (type selection, multiple choices)
- ✅ **Smart validation** with immediate feedback for inputs (colors, URLs, package names, versions)
- 🎨 **Color-coded messages** for success (green), errors (red), warnings (yellow), and info (blue)
- 📋 **Configuration summaries** showing all settings before applying
- 🔄 **Confirmation prompts** with sensible defaults for quick workflows

### Progress Indicators
- 📦 **Package renaming** with real-time progress feedback
- 🔥 **Firebase configuration** progress tracking
- 🎨 **Asset replacement** progress updates
- 🚀 **Launcher icon generation** with completion status
- 💦 **Splash screen creation** progress
- 🌍 **Internationalization file generation** progress
- 🛠️ **Build operations** with unified progress tracking for APK/AAB/IPA

### Enhanced Commands
- **`init`** - Interactive wizard with emoji indicators and type selection
- **`create`** - Guided clone creation with validation and configuration summary
- **`list`** - Colored tables with active client highlighting and emoji column headers
- **`configure`** - Progress indicators for all long-running operations
- **`build`** - Unified build progress with elapsed time tracking

### Accessibility
- 🔌 **TTY detection** - Automatically detects terminal capabilities
- 🎛️ **Fallback mode** - Works in CI/CD and non-interactive environments
- 🚫 **`--no-tui` flag** - Disable TUI features for basic text mode
- 🎨 **`NO_COLOR` support** - Respects environment variable for color-blind accessibility
- ⏭️ **`--skipAll` flag** - Skip all interactive prompts for automation

### Examples

```bash
# Use TUI features (default)
clonify create

# Disable TUI for CI/CD environments
clonify create --no-tui

# Skip all prompts for automation
clonify configure --skipAll
```

## Quick Start

### 1. Initialize Clonify

Set up your project with global configuration:

```bash
clonify init
```

This will prompt you for:
- Firebase configuration (optional)
- Fastlane configuration (optional)
- Company name
- Default app color
- Assets selection (launcher icon, splash screen, logo)
- Custom configuration fields (optional) - define custom fields that will be required for each clone

Creates: `./clonify/clonify_settings.yaml`

### 2. Create Your First Clone

Create a new client-specific configuration:

```bash
clonify create
```

This will prompt you for:
- Client ID (unique identifier)
- Base URL for API
- Primary color
- Package name (e.g., `com.company.clienta`)
- App name
- Version
- Firebase project ID (if Firebase enabled)
- Custom field values (if custom fields were defined during init)

Creates: `./clonify/clones/{clientId}/config.json` and assets directory

### 3. Configure Your Flutter Project

Apply a clone's configuration to your Flutter project:

```bash
clonify configure --clientId your_client_id

# Or use the last configured client
clonify configure
```

This will:
- Rename app and package
- Configure Firebase (if enabled)
- Update launcher icons and splash screens
- Sync versions
- Generate compile-time configuration class

Generates: `lib/generated/clone_configs.dart`
this class can be used in your project for accessing clone specific attributes. 

### 4. Build Your App

Build platform-specific artifacts:

```bash
# Build Android AAB and iOS IPA (default)
clonify build --clientId your_client_id

# Build specific platforms
clonify build --clientId your_client_id --buildApk --no-buildAab

# Use last client ID
clonify build
```

### 5. List All Clones

View all configured clones:

```bash
clonify list
```

## Commands

### Global Options

Available for all commands:
- `--no-tui` - Disable TUI (Text User Interface) features and use basic text mode
- `--help` - Display help information for any command

### `clonify init`
Initialize Clonify environment with global settings.

**Aliases:** `i`, `initialize`

### `clonify create`
Create a new Flutter project clone configuration.

**Aliases:** `create-clone`

### `clonify configure [options]`
Configure the Flutter project for a specific client.

**Aliases:** `con`, `config`, `c`

**Options:**
- `--clientId <id>` - Client ID to configure (or use last)
- `--skipAll` - Skip all user prompts
- `--autoUpdate` - Automatically increment version
- `--isDebug` - Run in debug mode
- `--skipFirebaseConfigure` - Skip Firebase configuration
- `--skipPubUpdate` - Skip pubspec.yaml updates
- `--skipVersionUpdate` - Skip version updates

### `clonify build [options]`
Build the Flutter project clone.

**Aliases:** `b`

**Options:**
- `--clientId <id>` - Client ID to build (or use last)
- `--skipAll` - Skip all user prompts
- `--buildAab` - Build Android App Bundle (default: true)
- `--buildApk` - Build Android APK (default: false)
- `--buildIpa` - Build iOS IPA (default: true)
- `--skipBuildCheck` - Skip pre-build checks

### `clonify upload [options]`
Upload builds to app stores via Fastlane.

**Aliases:** `up`, `u`

**Options:**
- `--clientId <id>` - Client ID to upload
- `--skipAll` - Skip all prompts
- `--skipAndroidUploadCheck` - Skip Android upload verification
- `--skipIOSUploadCheck` - Skip iOS upload verification

### `clonify list`
List all configured clones.

**Aliases:** `l`, `list-clones`, `ls`

### `clonify which`
Display the current clone configuration.

**Aliases:** `w`, `current`, `who`

### `clonify clean [options]`
Clean up a partial or broken clone.

**Aliases:** `clear`

**Options:**
- `--clientId <id>` - Client ID to clean (required)

## Configuration Files

### Global Settings: `./clonify/clonify_settings.yaml`

```yaml
firebase:
  enabled: true
  settings_file: "path/to/firebase.json"

fastlane:
  enabled: false
  settings_file: ""

company_name: "Your Company"
default_color: "#FFFFFF"

clone_assets:
  - icon.png
  - splash.png
  - logo.png

launcher_icon_asset: "icon.png"
splash_screen_asset: "splash.png"

# Optional: Custom configuration fields
custom_fields:
  - name: "socketUrl"
    type: "string"
  - name: "maxRetries"
    type: "int"
  - name: "enableDebug"
    type: "bool"
```

### Per-Clone Config: `./clonify/clones/{clientId}/config.json`

```json
{
  "clientId": "client_a",
  "packageName": "com.company.clienta",
  "appName": "Client A App",
  "baseUrl": "https://api.client-a.com",
  "primaryColor": "0xFF6200EE",
  "firebaseProjectId": "firebase-client-a",
  "version": "1.0.0+1",
  "socketUrl": "wss://socket.client-a.com",
  "maxRetries": "5",
  "enableDebug": "false",
  "colors": [
    {
      "name": "primaryBlue",
      "color": "6200EE"
    }
  ],
  "linearGradients": [
    {
      "name": "primaryGradient",
      "colors": ["6200EE", "03DAC6"],
      "begin": "topLeft",
      "end": "bottomRight",
      "transform": "0"
    }
  ]
}
```

### Generated Config: `lib/generated/clone_configs.dart`

```dart
abstract class CloneConfigs {
  static const String clientId = "client_a";
  static const String baseUrl = "https://api.client-a.com";
  static const String version = "1.0.0+1";
  static const String primaryColor = "0xFF6200EE";
  static const String socketUrl = "wss://socket.client-a.com";
  static const int maxRetries = 5;
  static const bool enableDebug = false;
  static const primaryBlue = Color(0xFF6200EE);
  static const primaryGradient = LinearGradient(...);
}
```

Use in your Flutter app:
```dart
import 'package:your_app/generated/clone_configs.dart';

// Access configuration
final baseUrl = CloneConfigs.baseUrl;
final clientId = CloneConfigs.clientId;
final primaryColor = CloneConfigs.primaryBlue;

// Access custom fields
final socketUrl = CloneConfigs.socketUrl;
final maxRetries = CloneConfigs.maxRetries;
final isDebugEnabled = CloneConfigs.enableDebug;
```

## Workflow Example

### Managing Multiple Clients

```bash
# Initial setup (one time)
clonify init

# Create client A
clonify create
# Enter: client_a, com.company.clienta, etc.

# Create client B
clonify create
# Enter: client_b, com.company.clientb, etc.

# Work on client A
clonify configure --clientId client_a
clonify build --clientId client_a

# Switch to client B
clonify configure --clientId client_b
clonify build --clientId client_b

# List all clients
clonify list
```

## Optional Features

### Firebase Integration

Firebase is **optional**. To use Firebase:

1. Enable during `clonify init`
2. Provide path to `firebase.json`
3. During clone creation, provide Firebase project ID
4. Clonify will create Firebase project and configure Flutterfire

To skip Firebase:
- Set `firebase.enabled: false` in settings
- Use `--skipFirebaseConfigure` flag

### Fastlane Integration

Fastlane is **optional**. To use Fastlane:

1. Enable during `clonify init`
2. Provide path to Fastlane settings
3. Use `clonify upload` to deploy to stores

## Development

### Run Tests

```bash
dart test
```

### Run Linter

```bash
dart analyze
```

### Format Code

```bash
dart format .
```

### Build Executable

```bash
dart compile exe bin/clonify.dart
```

## Requirements

- Dart SDK ^3.8.1
- Flutter SDK (for building apps)
- Firebase CLI (optional, if using Firebase features)
- Fastlane (optional, if using upload features)
- Xcode (for iOS builds on macOS)
- Android SDK (for Android builds)

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## Changelog

For all notable changes to this project, refer to the CHANGELOG.

## Support 

For any issues or suggestions, please open an issue. Your feedback is highly appreciated.

## Version

This is a pre-release version. The API may change in future releases. Feedback and bug reports are welcome!

## License

**GPL v3** (GNU General Public License v3.0) - see [LICENSE](LICENSE) file for details.

Copyright (c) 2024 Mohammad Salameh

**What this means:**
- ✅ Free to use for any purpose (including commercial projects)
- ✅ Free to modify and study the code
- ✅ Can sell applications built WITH this tool
- ❌ Cannot sell this tool itself as closed-source software
- ⚠️ If you distribute modified versions, you MUST share the source code under GPL v3

Full license: https://www.gnu.org/licenses/gpl-3.0.txt

## Author

**Mohammad Salameh**

- GitHub: [@DevMohammadSalameh](https://github.com/DevMohammadSalameh)
- Repository: https://github.com/DevMohammadSalameh/clonify
- Issues: https://github.com/DevMohammadSalameh/clonify/issues

## Acknowledgments

Built with ❤️ for the Flutter community, inspired by the need for efficient white-label app management.

### Special Thanks to Open Source Contributors

Clonify leverages these excellent community packages:

**Core TUI Libraries:**
- [mason_logger](https://pub.dev/packages/mason_logger) - Interactive CLI prompts and progress indicators
- [chalkdart](https://pub.dev/packages/chalkdart) - Terminal string styling and colors

**Asset Generation Tools (Called by Clonify):**
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) - Automated launcher icon generation
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) - Splash screen creation
- [package_rename_plus](https://pub.dev/packages/package_rename_plus) - Smart package and app renaming

**Architecture Inspiration:**
- Inspired by the architecture of the `rename` package for Flutter project management

A huge thank you to all the maintainers and contributors of these projects! 🙏

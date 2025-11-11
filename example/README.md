# Clonify Example

This example demonstrates how to use Clonify to manage multiple Flutter app clones with different branding and configurations.

## Prerequisites

1. Flutter SDK installed and configured
2. A Flutter project
3. Clonify CLI tool installed globally

## Installation

```bash
dart pub global activate clonify
```

Or install from source:

```bash
git clone https://github.com/DevMohammadSalameh/clonify.git
cd clonify
dart pub global activate --source path .
```

## Complete Workflow Example

### Step 1: Initialize Clonify in Your Flutter Project

Navigate to your Flutter project directory and run:

```bash
cd /path/to/your/flutter/project
clonify init
```

This command will:
- Create a `./clonify/clonify_settings.yaml` file
- Prompt you for configuration:
  - Company name
  - Default primary color
  - Firebase settings (optional)
  - Fastlane settings (optional)
  - Assets to clone for each client
  - Launcher icon asset
  - Splash screen asset (optional)

Example `clonify_settings.yaml`:

```yaml
company_name: My Company
default_color: '#2196F3'
firebase:
  enabled: true
  settings_file: firebase_settings.yaml
fastlane:
  enabled: false
  settings_file: fastlane_settings.yaml
clone_assets:
  - assets/images/logo.png
  - assets/images/background.png
launcher_icon_asset: assets/images/logo.png
splash_screen_asset: assets/images/splash.png
custom_fields:
  - name: apiTimeout
    type: int
  - name: enableDarkMode
    type: bool
```

### Step 2: Create a New Client Clone

Create a client-specific configuration:

```bash
clonify create client-abc
```

Or use aliases:

```bash
clonify create-clone client-abc
```

This will:
- Create `./clonify/clones/client-abc/` directory
- Generate `config.json` with client-specific settings
- Create an `assets/` directory for client assets
- Prompt for:
  - App name
  - Package name (e.g., com.example.clientabc)
  - Primary color
  - Base URL
  - Custom colors
  - Custom gradient colors
  - Custom field values

Example interaction:

```
Enter the app name: Client ABC App
Enter the package name: com.mycompany.clientabc
Enter the primary color (hex, e.g., #FF5733): #FF5733
Enter the base URL: https://api.clientabc.com
Do you want to add custom colors? (y/n): y
  Color name: Secondary
  Color value: #FFC300
Do you want to add gradient colors? (y/n): y
  Gradient name: Primary Gradient
  Number of colors: 2
  Color 1: #FF5733
  Color 2: #FFC300
  Begin alignment: topLeft
  End alignment: bottomRight
```

### Step 3: Configure Your Flutter Project for a Client

Apply the client configuration to your Flutter project:

```bash
clonify configure client-abc
```

Or use aliases:

```bash
clonify con client-abc
clonify config client-abc
clonify c client-abc
```

This command will:
- Update `pubspec.yaml` with client app name and version
- Rename the package using `package_rename_plus`
- Update launcher icons using `flutter_launcher_icons`
- Update splash screens using `flutter_native_splash`
- Configure Firebase (if enabled)
- Generate `lib/generated/clone_configs.dart` with compile-time constants

Available flags:
- `--skipFirebaseConfigure`: Skip Firebase configuration
- `--skipPubUpdate`: Skip updating pubspec.yaml
- `--skipVersionUpdate`: Skip version updates

Example:

```bash
clonify configure client-abc --skipFirebaseConfigure
```

### Step 4: Use Generated Configuration in Your Flutter Code

After running `configure`, you can use the generated constants in your Flutter code:

```dart
import 'package:your_app/generated/clone_configs.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: CloneConfigs.appName,
      theme: ThemeData(
        primaryColor: CloneConfigs.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: CloneConfigs.primaryColor,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class ApiService {
  static const String baseUrl = CloneConfigs.baseUrl;

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/data'));
    // Handle response
  }
}

class CustomGradientWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CloneConfigs.primaryGradient,
      ),
      child: Text('Gradient Background'),
    );
  }
}
```

### Step 5: Build Your App

Build platform-specific artifacts:

```bash
clonify build client-abc
```

Or use alias:

```bash
clonify b client-abc
```

Available flags:
- `--buildAab`: Build Android App Bundle (AAB)
- `--buildApk`: Build Android APK
- `--buildIpa`: Build iOS IPA
- `--skipBuildCheck`: Skip build validation

Build specific platforms:

```bash
# Build only AAB
clonify build client-abc --buildAab

# Build AAB and APK
clonify build client-abc --buildAab --buildApk

# Build all platforms
clonify build client-abc --buildAab --buildApk --buildIpa
```

### Step 6: Upload to App Stores (Optional)

If Fastlane is configured, upload builds:

```bash
clonify upload client-abc
```

Or use aliases:

```bash
clonify up client-abc
clonify u client-abc
```

Available flags:
- `--skipAndroidUploadCheck`: Skip Android upload checks
- `--skipIOSUploadCheck`: Skip iOS upload checks

## Managing Multiple Clients

### List All Clones

View all available client configurations:

```bash
clonify list
```

Or use aliases:

```bash
clonify l
clonify list-clones
clonify ls
```

### Check Current Client

Display the currently configured client:

```bash
clonify which
```

Or use aliases:

```bash
clonify w
clonify current
clonify who
```

### Switch Between Clients

Simply run `configure` with a different client ID:

```bash
clonify configure client-xyz
```

The tool will remember the last configured client for convenience.

## Advanced Usage

### Skip Interactive Prompts

Use the `--skipAll` flag to skip all prompts (uses defaults or previous values):

```bash
clonify create client-new --skipAll
clonify configure client-new --skipAll
clonify build client-new --skipAll
```

### Clean Build Artifacts

Clean Flutter build artifacts:

```bash
clonify clean
```

Or use alias:

```bash
clonify clear
```

### Custom Fields

Define custom fields in `clonify_settings.yaml`:

```yaml
custom_fields:
  - name: apiTimeout
    type: int
  - name: enableAnalytics
    type: bool
  - name: maxRetries
    type: int
  - name: appVersion
    type: string
```

During `clonify create`, you'll be prompted for values:

```
Enter value for apiTimeout (int): 30
Enter value for enableAnalytics (bool): true
Enter value for maxRetries (int): 3
Enter value for appVersion (string): 1.0.0
```

Access in your Flutter code:

```dart
import 'package:your_app/generated/clone_configs.dart';

// Custom fields are available as static constants
final int timeout = CloneConfigs.apiTimeout;
final bool analyticsEnabled = CloneConfigs.enableAnalytics;
```

## Typical Workflow for Multiple Clients

```bash
# 1. Initialize once in your Flutter project
cd /path/to/flutter/project
clonify init

# 2. Create configurations for multiple clients
clonify create client-a
clonify create client-b
clonify create client-c

# 3. Switch between clients and build
clonify configure client-a
flutter test
clonify build client-a --buildAab --buildApk

clonify configure client-b
flutter test
clonify build client-b --buildAab --buildApk

clonify configure client-c
flutter test
clonify build client-c --buildAab --buildApk

# 4. List all configurations
clonify list

# 5. Check current configuration
clonify which
```

## Best Practices

1. **Version Control**: Add `./clonify/clones/*/config.json` to `.gitignore` if it contains sensitive data
2. **Asset Management**: Keep client assets organized in their respective directories
3. **Testing**: Always test after running `configure` before building
4. **Firebase**: Keep Firebase configuration files secure and out of version control
5. **Naming Convention**: Use consistent client ID naming (e.g., lowercase with hyphens)
6. **Documentation**: Document client-specific configurations in your team wiki

## Troubleshooting

### Config Not Found

```bash
❌ Config file not found for client ID: client-abc
```

Solution: Run `clonify create client-abc` first.

### Settings File Not Found

```bash
❌ clonify_settings.yaml not found. Please run "clonify init".
```

Solution: Run `clonify init` in your Flutter project root.

### Build Failures

If builds fail:
1. Run `flutter clean`
2. Run `clonify clean`
3. Run `flutter pub get`
4. Try building again with `clonify build <client-id>`

## Getting Help

```bash
# View tool version
clonify --version

# Get help for specific commands
clonify create --help
clonify configure --help
clonify build --help
```

## Repository Structure After Setup

```
your-flutter-project/
├── clonify/
│   ├── clonify_settings.yaml
│   ├── last_client.txt
│   ├── last_config.json
│   └── clones/
│       ├── client-a/
│       │   ├── config.json
│       │   └── assets/
│       ├── client-b/
│       │   ├── config.json
│       │   └── assets/
│       └── client-c/
│           ├── config.json
│           └── assets/
├── lib/
│   └── generated/
│       └── clone_configs.dart  # Auto-generated
├── pubspec.yaml
└── ... (other Flutter files)
```

## Support

For issues, feature requests, or contributions:
- GitHub: https://github.com/DevMohammadSalameh/clonify
- Issues: https://github.com/DevMohammadSalameh/clonify/issues

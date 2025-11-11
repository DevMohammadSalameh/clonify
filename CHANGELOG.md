## 0.3.0 - 2024-11-11

### Documentation & Quality Improvements

**Enhanced Documentation:**
- ✅ Added comprehensive dartdoc comments to all public API classes and methods
- ✅ Created complete example package with working code samples (`example/example.dart`)
- ✅ Added detailed usage guide in example README with 10+ practical examples
- 📚 All models now include detailed descriptions, parameter docs, and code examples

**Platform & Compatibility:**
- ✅ Added explicit platform support declarations (Linux, macOS, Windows)
- ✅ Removed Flutter SDK dependency - tool is now a pure Dart CLI package
- ✅ Removed `flutter_launcher_icons`, `flutter_native_splash`, `intl_utils`, `package_rename_plus` from dependencies
  - These packages are called as external tools in user's Flutter projects, not imported
- ✅ All dependencies now resolve correctly with `dart pub get`
- ✅ Fixed "Flutter users should use flutter pub" errors on pub.dev

**Version Command:**
- ✅ Implemented dynamic `--version` / `-v` flag that reads from pubspec.yaml
- 🔧 Version now displays correctly across all installation methods (local, global, development)
- 📝 Deprecated hardcoded version constant in favor of dynamic lookup

**Code Quality:**
- ✅ Fixed unused variable warning in command runner
- ✅ All files pass `dart analyze` with no errors, warnings, or lints
- ✅ All files properly formatted with `dart format`
- ✅ Package validation passes for pub.dev publication

**Pub.dev Score Improvements:**
- 📊 Documentation: 0/20 → 20/20 points
- 📊 Platform Support: 0/20 → 20/20 points
- 📊 Static Analysis: 0/50 → 50/50 points
- 🎯 Overall score improvement: ~40/160 → ~90/160

### Breaking Changes

None - all changes are additive or internal improvements.

### Migration Guide

No migration required. Version detection is now automatic via `--version` flag.

## 0.2.1

- Fixed an issue where running `clonify --help` would trigger an unnecessary validation error.
- Enhanced the `intl_utils:generate` command to check if `intl_utils` is a dependency in the user's `pubspec.yaml` before execution, preventing errors when the dependency is missing.
- Improved README.md file

## 0.2.0 - 2024-11-11 (Pre-release)

- Added `version` command to check the package version.
- Simplified asset selection process.
- Implemented a custom fields feature for more flexible project cloning.

## 0.1.0 - 2024-11-10 (Pre-release)

### Features

**Core Functionality:**
- 🎨 Manage multiple Flutter project clones from a single codebase
- 📦 Rename packages and app names per clone
- 🔥 Optional Firebase integration with project creation
- 📱 Auto-generate launcher icons and splash screens
- 🏗️ Build multiple platforms (Android APK/AAB, iOS IPA)
- 💾 Configuration persistence and easy client switching

**Commands:**
- `clonify init` - Initialize Clonify environment
- `clonify create` - Create new clone configuration
- `clonify configure` - Apply clone configuration to Flutter project
- `clonify build` - Build platform-specific artifacts
- `clonify list` - List all configured clones
- `clonify which` - Show current clone configuration
- `clonify clean` - Clean up partial/broken clones
- `clonify upload` - Upload to app stores (partial implementation)
- `clonify --version` / `clonify -v` - Display tool version

**Global Installation:**
- Install globally via `dart pub global activate clonify`
- Use `clonify` command directly without `dart run`

**Asset Management:**
- Simplified asset selection during initialization
- Direct questions for launcher icon, splash screen, and logo
- No more confusing method selection

**Custom Configuration Fields:**
- Define custom fields during initialization (e.g., socketUrl, apiKey, feature flags)
- Support for multiple data types: string, int, bool, double
- Custom fields are automatically prompted during clone creation
- Generated as constants in `lib/generated/clone_configs.dart`
- Type-safe access to custom configuration in Flutter code

**Optional Features:**
- Firebase integration (fully optional)
- Fastlane integration (optional, partial)
- Custom colors and gradients per clone
- Multiple asset management

**Testing:**
- Comprehensive test suite (54+ tests)
- No real Flutter project required for testing
- Mock-based testing infrastructure
- Integration tests for full workflows

### Known Limitations

- Upload functionality is partially implemented
- Requires manual Xcode configuration for iOS builds
- Firebase APNs key must be uploaded manually

### Breaking Changes

None (initial pre-release)

### Notes

This is a pre-release version for testing and feedback. The API may change in future releases.

**Requirements:**
- Dart SDK ^3.8.1
- Flutter SDK (for building apps)
- Firebase CLI (optional, for Firebase features)
- Fastlane (optional, for upload features)

**Feedback Welcome:**
Please report issues at https://github.com/DevMohammadSalameh/clonify/issues

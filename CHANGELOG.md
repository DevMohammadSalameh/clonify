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

**Global Installation:**
- Install globally via `dart pub global activate clonify`
- Use `clonify` command directly without `dart run`

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

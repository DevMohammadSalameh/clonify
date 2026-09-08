import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:path/path.dart' as p;

const androidKeystoreConfigKey = 'androidKeystore';
const androidKeyPropertiesConfigKey = 'androidKeyProperties';
const defaultAndroidKeystoreFileName = 'upload-keystore.jks';
const defaultAndroidKeyPropertiesFileName = 'key.properties';

const androidKeyPropertiesStorePasswordKey = 'storePassword';
const androidKeyPropertiesKeyPasswordKey = 'keyPassword';
const androidKeyPropertiesKeyAliasKey = 'keyAlias';
const androidKeyPropertiesStoreFileKey = 'storeFile';

const requiredAndroidKeyPropertyKeys = <String>[
  androidKeyPropertiesStorePasswordKey,
  androidKeyPropertiesKeyPasswordKey,
  androidKeyPropertiesKeyAliasKey,
];

const jksMagicBytes = <int>[0xFE, 0xED, 0xFE, 0xED];

const androidKeyPropertiesExample = '''
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
''';

const kotlinKeystoreImports = '''
import java.io.FileInputStream
import java.util.Properties
''';

const kotlinKeystoreLoader = '''
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
''';

const kotlinSigningConfigsBlock = '''
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
''';

const groovyKeystoreLoader = '''
def keystoreProperties = new java.util.Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new java.io.FileInputStream(keystorePropertiesFile))
}
''';

const groovySigningConfigsBlock = '''
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile rootProject.file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
''';

/// Directory that holds a clone's Android signing files.
String cloneAndroidSigningDir(String clientId) =>
    p.join('clonify', 'clones', clientId, 'android');

String resolveAndroidKeystoreFileName(Map<String, dynamic> configJson) {
  return trimmedSigningString(configJson[androidKeystoreConfigKey]) ??
      defaultAndroidKeystoreFileName;
}

String resolveAndroidKeyPropertiesFileName(Map<String, dynamic> configJson) {
  return trimmedSigningString(configJson[androidKeyPropertiesConfigKey]) ??
      defaultAndroidKeyPropertiesFileName;
}

String? trimmedSigningString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

/// Clone signing files must live in `clonify/clones/{id}/android/`, never
/// a relative path that could write outside the project.
void assertSafeAndroidSigningFileName(String name, String field) {
  final trimmed = name.trim();
  if (trimmed.isEmpty ||
      trimmed.contains('/') ||
      trimmed.contains('\\') ||
      trimmed == '.' ||
      trimmed == '..') {
    throw CustomException(
      '$field must be a file name in the clone android folder, not a path: $name',
    );
  }
}

bool androidSigningIsConfigured(Map<String, dynamic> configJson) {
  return trimmedSigningString(configJson[androidKeystoreConfigKey]) != null ||
      configJson.containsKey(androidKeystoreConfigKey) ||
      trimmedSigningString(configJson[androidKeyPropertiesConfigKey]) != null ||
      configJson.containsKey(androidKeyPropertiesConfigKey);
}

bool androidSigningSourceExists(
  String clientId,
  Map<String, dynamic> configJson,
) {
  final dir = cloneAndroidSigningDir(clientId);
  final keystore = File(
    p.join(dir, resolveAndroidKeystoreFileName(configJson)),
  );
  final properties = File(
    p.join(dir, resolveAndroidKeyPropertiesFileName(configJson)),
  );
  return keystore.existsSync() || properties.existsSync();
}

bool androidSigningIsRequired(
  String clientId,
  Map<String, dynamic> configJson,
) {
  return androidSigningIsConfigured(configJson) ||
      androidSigningSourceExists(clientId, configJson);
}

/// Creates `clonify/clones/{clientId}/android/key.properties.example`.
void createCloneAndroidSigningDirectory(String clientId) {
  final dir = Directory(cloneAndroidSigningDir(clientId));
  dir.createSync(recursive: true);
  final example = File(
    p.join(dir.path, '$defaultAndroidKeyPropertiesFileName.example'),
  );
  if (!example.existsSync()) {
    example.writeAsStringSync(androidKeyPropertiesExample);
  }
}

/// Copies the clone keystore + `key.properties` into `android/` and wires
/// release signing in `build.gradle` / `build.gradle.kts` when needed.
///
/// Expected clone files:
/// `clonify/clones/{clientId}/android/upload-keystore.jks`
/// `clonify/clones/{clientId}/android/key.properties`
Future<void> applyAndroidReleaseSigning(
  String clientId,
  Map<String, dynamic> configJson,
) async {
  if (!androidSigningIsRequired(clientId, configJson)) {
    removeLeftoverAndroidKeyProperties();
    logger.i(
      'ℹ️  No Android signing files at ${cloneAndroidSigningDir(clientId)}; skipped.',
    );
    return;
  }

  final keystoreName = resolveAndroidKeystoreFileName(configJson);
  final propertiesName = resolveAndroidKeyPropertiesFileName(configJson);
  assertSafeAndroidSigningFileName(keystoreName, androidKeystoreConfigKey);
  assertSafeAndroidSigningFileName(
    propertiesName,
    androidKeyPropertiesConfigKey,
  );
  final sourceDir = cloneAndroidSigningDir(clientId);
  final sourceKeystore = File(p.join(sourceDir, keystoreName));
  final sourceProperties = File(p.join(sourceDir, propertiesName));

  if (!sourceKeystore.existsSync()) {
    throw CustomException(
      'Missing $androidKeystoreConfigKey at ${sourceKeystore.path}',
    );
  }
  if (!sourceProperties.existsSync()) {
    throw CustomException(
      'Missing $androidKeyPropertiesConfigKey at ${sourceProperties.path}',
    );
  }

  final properties = parseAndroidKeyProperties(
    await sourceProperties.readAsString(),
  );
  assertAndroidKeyPropertiesComplete(properties, sourceProperties.path);

  final keystoreBytes = sourceKeystore.readAsBytesSync();
  assertAndroidKeystoreBytes(keystoreBytes, sourceKeystore.path);

  final androidDir = Directory(Constants.androidDirPath);
  if (!androidDir.existsSync()) {
    throw CustomException(
      '${androidDir.path} not found; cannot sync Android release signing.',
    );
  }

  final targetKeystore = File(p.join(Constants.androidDirPath, keystoreName));
  sourceKeystore.copySync(targetKeystore.path);

  final targetProperties = File(Constants.androidKeyPropertiesFilePath);
  await targetProperties.writeAsString(
    serializeAndroidKeyProperties(properties, storeFile: keystoreName),
  );

  logger.i('✅ Android release signing synced from $sourceDir ($keystoreName)');

  await ensureProjectGradleReleaseSigning();
}

Future<void> ensureProjectGradleReleaseSigning() async {
  final kts = File(Constants.androidAppLevelKotlinBuildGradleFilePath);
  final groovy = File(Constants.androidAppLevelBuildGradleFilePath);

  if (kts.existsSync()) {
    final original = await kts.readAsString();
    final updated = ensureAndroidGradleReleaseSigning(
      original,
      isKotlinDsl: true,
    );
    if (updated != original) {
      await kts.writeAsString(updated);
      logger.i(
        '✅ Android Kotlin Gradle release signing wired to key.properties',
      );
    }
    return;
  }

  if (groovy.existsSync()) {
    final original = await groovy.readAsString();
    final updated = ensureAndroidGradleReleaseSigning(
      original,
      isKotlinDsl: false,
    );
    if (updated != original) {
      await groovy.writeAsString(updated);
      logger.i(
        '✅ Android Groovy Gradle release signing wired to key.properties',
      );
    }
    return;
  }

  throw CustomException(
    'No ${Constants.kotlinBuildGradleFileName} or ${Constants.buildGradleFileName} under ${Constants.androidAppDirPath}',
  );
}

void removeLeftoverAndroidKeyProperties() {
  final leftover = File(Constants.androidKeyPropertiesFilePath);
  if (!leftover.existsSync()) return;
  leftover.deleteSync();
  logger.w(
    '⚠️  Removed leftover ${leftover.path} so the previous clone\'s keystore is not reused.',
  );
}

Map<String, String> parseAndroidKeyProperties(String content) {
  var text = content;
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  final values = <String, String>{};
  for (final rawLine in text.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#') || !line.contains('=')) {
      continue;
    }
    final separator = line.indexOf('=');
    final key = line.substring(0, separator).trim();
    var value = line.substring(separator + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isEmpty) continue;
    values[key] = value;
  }
  return values;
}

void assertAndroidKeyPropertiesComplete(
  Map<String, String> properties,
  String path,
) {
  for (final key in requiredAndroidKeyPropertyKeys) {
    final value = properties[key]?.trim();
    if (value == null || value.isEmpty) {
      throw CustomException('$path is missing $key');
    }
  }
}

void assertAndroidKeystoreBytes(List<int> bytes, String path) {
  if (bytes.isEmpty) {
    throw CustomException('Android keystore at $path is empty');
  }
  if (!hasJavaKeystoreSignature(bytes)) {
    throw CustomException(
      'Android keystore at $path is not a JKS or PKCS#12 file',
    );
  }
}

bool hasJavaKeystoreSignature(List<int> bytes) {
  if (bytes.length >= jksMagicBytes.length) {
    var isJks = true;
    for (var i = 0; i < jksMagicBytes.length; i++) {
      if (bytes[i] != jksMagicBytes[i]) {
        isJks = false;
        break;
      }
    }
    if (isJks) return true;
  }
  return bytes.length >= 4 && bytes.first == 0x30;
}

String serializeAndroidKeyProperties(
  Map<String, String> properties, {
  required String storeFile,
}) {
  final keys = <String>[
    androidKeyPropertiesStorePasswordKey,
    androidKeyPropertiesKeyPasswordKey,
    androidKeyPropertiesKeyAliasKey,
    androidKeyPropertiesStoreFileKey,
    ...properties.keys.where(
      (key) =>
          key != androidKeyPropertiesStorePasswordKey &&
          key != androidKeyPropertiesKeyPasswordKey &&
          key != androidKeyPropertiesKeyAliasKey &&
          key != androidKeyPropertiesStoreFileKey,
    ),
  ];
  final buffer = StringBuffer();
  for (final key in keys) {
    final value = key == androidKeyPropertiesStoreFileKey
        ? storeFile
        : properties[key];
    if (value == null) continue;
    buffer.writeln('$key=$value');
  }
  return buffer.toString();
}

/// Injects Flutter-standard `key.properties` release signing into Gradle.
String ensureAndroidGradleReleaseSigning(
  String content, {
  required bool isKotlinDsl,
}) {
  var updated = content;
  if (isKotlinDsl) {
    updated = ensureKotlinKeystoreImports(updated);
    if (!updated.contains('keystorePropertiesFile')) {
      updated = insertAfterPluginsBlock(updated, kotlinKeystoreLoader);
    }
    if (!RegExp(r'signingConfigs\s*\{').hasMatch(updated)) {
      updated = insertBeforeBuildTypes(updated, kotlinSigningConfigsBlock);
    }
    updated = replaceKotlinDebugReleaseSigning(updated);
    return updated;
  }

  if (!updated.contains('keystorePropertiesFile')) {
    updated = insertAfterPluginsBlock(updated, groovyKeystoreLoader);
  }
  if (!RegExp(r'signingConfigs\s*\{').hasMatch(updated)) {
    updated = insertBeforeBuildTypes(updated, groovySigningConfigsBlock);
  }
  updated = replaceGroovyDebugReleaseSigning(updated);
  return updated;
}

String ensureKotlinKeystoreImports(String content) {
  var updated = content;
  if (!updated.contains('import java.io.FileInputStream')) {
    updated = 'import java.io.FileInputStream\n$updated';
  }
  if (!updated.contains('import java.util.Properties')) {
    updated = 'import java.util.Properties\n$updated';
  }
  return updated;
}

String insertAfterPluginsBlock(String content, String snippet) {
  final plugins = RegExp(r'plugins\s*\{[\s\S]*?\n\}', multiLine: true);
  final match = plugins.firstMatch(content);
  if (match == null) {
    return '$snippet\n$content';
  }
  final insertAt = match.end;
  return '${content.substring(0, insertAt)}\n$snippet${content.substring(insertAt)}';
}

String insertBeforeBuildTypes(String content, String snippet) {
  final buildTypes = RegExp(r'\n(\s*)buildTypes\s*\{');
  final match = buildTypes.firstMatch(content);
  if (match == null) {
    throw CustomException(
      'Could not find buildTypes in Android Gradle file; cannot wire release signing',
    );
  }
  return '${content.substring(0, match.start)}\n$snippet${content.substring(match.start)}';
}

String replaceKotlinDebugReleaseSigning(String content) {
  if (content.contains('keystorePropertiesFile.exists()') &&
      content.contains('signingConfigs.getByName("release")')) {
    return content;
  }
  const replacement = '''
signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }''';
  final debugInRelease = RegExp(
    r'(release\s*\{[\s\S]*?)signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
  );
  if (debugInRelease.hasMatch(content)) {
    return content.replaceFirstMapped(
      debugInRelease,
      (match) => '${match[1]}$replacement',
    );
  }
  final releaseOpen = RegExp(r'release\s*\{');
  final match = releaseOpen.firstMatch(content);
  if (match == null) {
    throw CustomException(
      'Could not find release buildType in Android Gradle file',
    );
  }
  return '${content.substring(0, match.end)}\n            $replacement${content.substring(match.end)}';
}

String replaceGroovyDebugReleaseSigning(String content) {
  if (content.contains('keystorePropertiesFile.exists()') &&
      (content.contains('signingConfigs.release') ||
          content.contains("signingConfigs.getByName('release')") ||
          content.contains('signingConfigs.getByName("release")'))) {
    return content;
  }
  const replacement =
      'signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug';
  final debugInRelease = RegExp(
    r'(release\s*\{[\s\S]*?)signingConfig\s*=?\s*signingConfigs\.debug',
  );
  if (debugInRelease.hasMatch(content)) {
    return content.replaceFirstMapped(
      debugInRelease,
      (match) => '${match[1]}$replacement',
    );
  }
  final releaseOpen = RegExp(r'release\s*\{');
  final match = releaseOpen.firstMatch(content);
  if (match == null) {
    throw CustomException(
      'Could not find release buildType in Android Gradle file',
    );
  }
  return '${content.substring(0, match.end)}\n            $replacement${content.substring(match.end)}';
}

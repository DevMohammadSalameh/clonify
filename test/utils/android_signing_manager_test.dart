import 'dart:io';

import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/android_signing_manager.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('parseAndroidKeyProperties', () {
    test('reads Flutter key.properties keys', () {
      final values = parseAndroidKeyProperties('''
storePassword=store-secret
keyPassword=key-secret
keyAlias=upload
storeFile=../old-upload-keystore.jks
''');
      expect(values[androidKeyPropertiesStorePasswordKey], 'store-secret');
      expect(values[androidKeyPropertiesKeyPasswordKey], 'key-secret');
      expect(values[androidKeyPropertiesKeyAliasKey], 'upload');
      expect(
        values[androidKeyPropertiesStoreFileKey],
        '../old-upload-keystore.jks',
      );
    });

    test('ignores comments, blanks, and quoted values', () {
      final values = parseAndroidKeyProperties('''
# comment
storePassword="quoted"

keyAlias='upload'
''');
      expect(values[androidKeyPropertiesStorePasswordKey], 'quoted');
      expect(values[androidKeyPropertiesKeyAliasKey], 'upload');
    });
  });

  group('serializeAndroidKeyProperties', () {
    test('rewrites storeFile to the copied keystore name', () {
      final text = serializeAndroidKeyProperties({
        androidKeyPropertiesStorePasswordKey: 'store-secret',
        androidKeyPropertiesKeyPasswordKey: 'key-secret',
        androidKeyPropertiesKeyAliasKey: 'upload',
        androidKeyPropertiesStoreFileKey: '/Users/me/old.jks',
      }, storeFile: 'upload-keystore.jks');
      expect(text, contains('storeFile=upload-keystore.jks'));
      expect(text, isNot(contains('/Users/me/old.jks')));
    });
  });

  group('hasJavaKeystoreSignature', () {
    test('accepts JKS magic', () {
      expect(hasJavaKeystoreSignature(fakeJksBytes()), isTrue);
    });

    test('accepts PKCS#12 prefix', () {
      expect(hasJavaKeystoreSignature(const [0x30, 0x82, 0x01]), isTrue);
    });

    test('rejects empty and random bytes', () {
      expect(hasJavaKeystoreSignature(const []), isFalse);
      expect(hasJavaKeystoreSignature(const [0x00, 0x01]), isFalse);
    });
  });

  group('ensureAndroidGradleReleaseSigning', () {
    test('wires Kotlin DSL debug release signing to key.properties', () {
      const original = '''
plugins {
    id("com.android.application")
}

android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
''';
      final updated = ensureAndroidGradleReleaseSigning(
        original,
        isKotlinDsl: true,
      );
      expect(updated, contains('import java.util.Properties'));
      expect(updated, contains('keystorePropertiesFile'));
      expect(updated, contains('signingConfigs'));
      expect(updated, contains('create("release")'));
      expect(updated, contains('signingConfigs.getByName("release")'));
      expect(
        updated,
        contains('rootProject.file(keystoreProperties["storeFile"] as String)'),
      );
    });

    test('is idempotent when Kotlin signing is already wired', () {
      final first = ensureAndroidGradleReleaseSigning('''
plugins {
    id("com.android.application")
}

android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
''', isKotlinDsl: true);
      final second = ensureAndroidGradleReleaseSigning(
        first,
        isKotlinDsl: true,
      );
      expect(second, first);
    });

    test('is idempotent for Groovy when already wired', () {
      final first = ensureAndroidGradleReleaseSigning('''
plugins {
    id "com.android.application"
}

android {
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
''', isKotlinDsl: false);
      final second = ensureAndroidGradleReleaseSigning(
        first,
        isKotlinDsl: false,
      );
      expect(second, first);
    });

    test('throws when Kotlin Gradle has no release buildType', () {
      expect(
        () => ensureAndroidGradleReleaseSigning('''
plugins {
    id("com.android.application")
}

android {
    defaultConfig {
        applicationId = "com.app"
    }
}
''', isKotlinDsl: true),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('buildTypes'),
          ),
        ),
      );
    });

    test('wires Groovy debug release signing to key.properties', () {
      const original = '''
plugins {
    id "com.android.application"
}

android {
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
''';
      final updated = ensureAndroidGradleReleaseSigning(
        original,
        isKotlinDsl: false,
      );
      expect(updated, contains('keystorePropertiesFile'));
      expect(updated, contains('signingConfigs {'));
      expect(updated, contains('signingConfigs.release'));
      expect(
        updated,
        contains('rootProject.file(keystoreProperties[\'storeFile\'])'),
      );
    });
  });

  group('applyAndroidReleaseSigning', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() {
      originalDir = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('clonify_signing_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('skips when no clone signing files exist', () async {
      await applyAndroidReleaseSigning('client_a', {});
      expect(File('android/key.properties').existsSync(), isFalse);
    });

    test('throws when androidKeystore is configured but missing', () async {
      expect(
        () => applyAndroidReleaseSigning('client_a', {
          androidKeystoreConfigKey: 'upload-keystore.jks',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('Missing androidKeystore'),
          ),
        ),
      );
    });

    test('copies keystore and key.properties then wires Gradle', () async {
      writeCloneSigningFiles();
      writeKotlinGradleWithDebugReleaseSigning();

      await applyAndroidReleaseSigning('client_a', {});

      expect(File('android/upload-keystore.jks').existsSync(), isTrue);
      final properties = File('android/key.properties').readAsStringSync();
      expect(properties, contains('storeFile=upload-keystore.jks'));
      expect(properties, contains('keyAlias=upload'));
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('signingConfigs.getByName("release")'));
    });

    test('throws when key.properties is missing a password', () async {
      writeCloneSigningFiles(
        properties: 'keyAlias=upload\nstorePassword=secret\n',
      );
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('keyPassword'),
          ),
        ),
      );
    });

    test('throws when key.properties file is missing', () async {
      writeCloneSigningFiles();
      File('clonify/clones/client_a/android/key.properties').deleteSync();
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('androidKeyProperties'),
          ),
        ),
      );
    });

    test('throws when the keystore is empty', () async {
      writeCloneSigningFiles();
      File(
        'clonify/clones/client_a/android/upload-keystore.jks',
      ).writeAsBytesSync(const []);
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });

    test('throws when the keystore is not JKS or PKCS#12', () async {
      writeCloneSigningFiles();
      File(
        'clonify/clones/client_a/android/upload-keystore.jks',
      ).writeAsStringSync('not-a-keystore');
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('JKS or PKCS#12'),
          ),
        ),
      );
    });

    test('copies a custom keystore filename', () async {
      Directory('clonify/clones/client_a/android').createSync(recursive: true);
      File(
        'clonify/clones/client_a/android/staff.keystore',
      ).writeAsBytesSync(fakeJksBytes());
      File('clonify/clones/client_a/android/key.properties').writeAsStringSync(
        'storePassword=s\nkeyPassword=k\nkeyAlias=upload\nstoreFile=old.jks\n',
      );
      writeKotlinGradleWithDebugReleaseSigning();

      await applyAndroidReleaseSigning('client_a', {
        androidKeystoreConfigKey: 'staff.keystore',
      });

      expect(File('android/staff.keystore').existsSync(), isTrue);
      expect(
        File('android/key.properties').readAsStringSync(),
        contains('storeFile=staff.keystore'),
      );
    });

    test('accepts a PKCS#12 keystore', () async {
      Directory('clonify/clones/client_a/android').createSync(recursive: true);
      File(
        'clonify/clones/client_a/android/upload-keystore.jks',
      ).writeAsBytesSync(const [0x30, 0x82, 0x01, 0x00]);
      File('clonify/clones/client_a/android/key.properties').writeAsStringSync(
        'storePassword=s\nkeyPassword=k\nkeyAlias=upload\nstoreFile=upload-keystore.jks\n',
      );
      writeKotlinGradleWithDebugReleaseSigning();

      await applyAndroidReleaseSigning('client_a', {});
      expect(File('android/upload-keystore.jks').existsSync(), isTrue);
    });

    test('keeps extra key.properties entries', () async {
      writeCloneSigningFiles(
        properties:
            'storePassword=s\nkeyPassword=k\nkeyAlias=upload\nstoreFile=old.jks\nextra=keep\n',
      );
      writeKotlinGradleWithDebugReleaseSigning();
      await applyAndroidReleaseSigning('client_a', {});
      expect(
        File('android/key.properties').readAsStringSync(),
        contains('extra=keep'),
      );
    });

    test('throws when android/ is missing', () async {
      writeCloneSigningFiles();
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('android not found'),
          ),
        ),
      );
    });

    test('throws when Gradle has no buildTypes', () async {
      writeCloneSigningFiles();
      File('android/app/build.gradle.kts')
        ..createSync(recursive: true)
        ..writeAsStringSync('plugins { id("com.android.application") }\n');
      expect(
        () => applyAndroidReleaseSigning('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('buildTypes'),
          ),
        ),
      );
    });

    test('wires Groovy Gradle when only build.gradle exists', () async {
      writeCloneSigningFiles();
      File('android/app/build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
plugins {
    id "com.android.application"
}
android {
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
''');
      await applyAndroidReleaseSigning('client_a', {});
      expect(
        File('android/app/build.gradle').readAsStringSync(),
        contains('signingConfigs.release'),
      );
    });
  });

  group('createCloneAndroidSigningDirectory', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() {
      originalDir = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('clonify_signing_create_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes key.properties.example', () {
      createCloneAndroidSigningDirectory('client_a');
      final example = File(
        'clonify/clones/client_a/android/key.properties.example',
      );
      expect(example.existsSync(), isTrue);
      expect(
        example.readAsStringSync(),
        contains('storeFile=upload-keystore.jks'),
      );
    });
  });
}

List<int> fakeJksBytes() => [...jksMagicBytes, 0x00, 0x01, 0x02];

void writeCloneSigningFiles({String? properties}) {
  Directory('clonify/clones/client_a/android').createSync(recursive: true);
  File(
    'clonify/clones/client_a/android/upload-keystore.jks',
  ).writeAsBytesSync(fakeJksBytes());
  File('clonify/clones/client_a/android/key.properties').writeAsStringSync(
    properties ??
        '''
storePassword=store-secret
keyPassword=key-secret
keyAlias=upload
storeFile=/tmp/old.jks
''',
  );
}

void writeKotlinGradleWithDebugReleaseSigning() {
  File('android/app/build.gradle.kts')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
plugins {
    id("com.android.application")
}

android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
''');
}

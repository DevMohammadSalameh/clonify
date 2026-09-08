import 'dart:io';

import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/android_signing_manager.dart';
import 'package:clonify/utils/background_geolocation_license_manager.dart';
import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/file_tree_checkpoint.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_edge_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('applyCloneNativeConfig rollback', () {
    test('restores iOS after licenses write when Android signing fails', () async {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '<plist><dict><key>CFBundleName</key><string>OLD</string></dict></plist>',
        );
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '<manifest><application></application></manifest>',
        );

      await expectLater(
        runConfigureTransaction(() async {
          await applyCloneNativeConfig('client_a', {
            backgroundGeolocationLicenseAndroidKey: 'NEW_ANDROID_LICENSE',
            backgroundGeolocationLicenseIosKey: 'NEW_IOS_LICENSE',
            androidKeystoreConfigKey: 'upload-keystore.jks',
          });
        }),
        throwsA(
          isA<ConfigureRolledBackException>().having(
            (error) => error.message,
            'message',
            contains('Missing androidKeystore'),
          ),
        ),
      );

      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('OLD'),
      );
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        isNot(contains('NEW_IOS_LICENSE')),
      );
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        isNot(contains('NEW_ANDROID_LICENSE')),
      );
    });

    test('restores iOS when signing files exist but Gradle is incomplete', () async {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '<plist><dict><key>CFBundleName</key><string>OLD</string></dict></plist>',
        );
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '<manifest><application></application></manifest>',
        );
      Directory('clonify/clones/client_a/android').createSync(recursive: true);
      File(
        'clonify/clones/client_a/android/upload-keystore.jks',
      ).writeAsBytesSync([...jksMagicBytes, 0x00]);
      File('clonify/clones/client_a/android/key.properties').writeAsStringSync(
        'storePassword=s\nkeyPassword=k\nkeyAlias=upload\nstoreFile=upload-keystore.jks\n',
      );
      File('android/app/build.gradle.kts')
        ..createSync(recursive: true)
        ..writeAsStringSync('plugins { id("com.android.application") }\n');

      await expectLater(
        runConfigureTransaction(() async {
          await applyCloneNativeConfig('client_a', {});
        }),
        throwsA(isA<ConfigureRolledBackException>()),
      );

      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('OLD'),
      );
      expect(File('android/key.properties').existsSync(), isFalse);
    });
  });

  group('runConfigureTransaction large switch', () {
    test('restores every default root after a late failure', () async {
      File('pubspec.yaml').writeAsStringSync('version: 1.0.0+1');
      File('package_rename_config.yaml').writeAsStringSync('OLD_RENAME');
      File('flutter_launcher_icons.yaml').writeAsStringSync('OLD_ICONS');
      File('flutter_native_splash.yaml').writeAsStringSync('OLD_SPLASH');
      File('firebase.json').writeAsStringSync('{"old":true}');
      File('.firebaserc').writeAsStringSync('{"projects":{"default":"old"}}');
      File('shorebird.yaml').writeAsStringSync('app_id: old');
      File('lib/firebase_options.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_FIREBASE');
      File('lib/generated/clone_configs.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_GENERATED');
      File('assets/images/logo.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(const [1, 2, 3]);
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_IOS');
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_ANDROID');
      File('macos/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_MAC');
      File('web/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_WEB');
      File('linux/CMakeLists.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_LINUX');
      File('windows/CMakeLists.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_WINDOWS');
      File('clonify/clones/client/config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"version":"1.0.0+1"}');

      await expectLater(
        runConfigureTransaction(() async {
          File('pubspec.yaml').writeAsStringSync('version: 9.0.0+9');
          File('package_rename_config.yaml').writeAsStringSync('NEW_RENAME');
          File('flutter_launcher_icons.yaml').writeAsStringSync('NEW_ICONS');
          File('flutter_native_splash.yaml').writeAsStringSync('NEW_SPLASH');
          File('firebase.json').writeAsStringSync('{"old":false}');
          File('.firebaserc').writeAsStringSync('{"projects":{"default":"new"}}');
          File('shorebird.yaml').writeAsStringSync('app_id: new');
          File('lib/firebase_options.dart').writeAsStringSync('NEW_FIREBASE');
          File(
            'lib/generated/clone_configs.dart',
          ).writeAsStringSync('NEW_GENERATED');
          File('assets/images/logo.png').writeAsBytesSync(const [9, 9, 9]);
          File('ios/Runner/Info.plist').writeAsStringSync('NEW_IOS');
          File(
            'android/app/src/main/AndroidManifest.xml',
          ).writeAsStringSync('NEW_ANDROID');
          File('macos/Runner/Info.plist').writeAsStringSync('NEW_MAC');
          File('web/index.html').writeAsStringSync('NEW_WEB');
          File('linux/CMakeLists.txt').writeAsStringSync('NEW_LINUX');
          File('windows/CMakeLists.txt').writeAsStringSync('NEW_WINDOWS');
          File(
            'clonify/clones/client/config.json',
          ).writeAsStringSync('{"version":"9.0.0+9"}');
          throw CustomException('late configure failure');
        }),
        throwsA(isA<ConfigureRolledBackException>()),
      );

      expect(File('pubspec.yaml').readAsStringSync(), 'version: 1.0.0+1');
      expect(File('package_rename_config.yaml').readAsStringSync(), 'OLD_RENAME');
      expect(File('flutter_launcher_icons.yaml').readAsStringSync(), 'OLD_ICONS');
      expect(File('flutter_native_splash.yaml').readAsStringSync(), 'OLD_SPLASH');
      expect(File('firebase.json').readAsStringSync(), '{"old":true}');
      expect(
        File('.firebaserc').readAsStringSync(),
        '{"projects":{"default":"old"}}',
      );
      expect(File('shorebird.yaml').readAsStringSync(), 'app_id: old');
      expect(File('lib/firebase_options.dart').readAsStringSync(), 'OLD_FIREBASE');
      expect(
        File('lib/generated/clone_configs.dart').readAsStringSync(),
        'OLD_GENERATED',
      );
      expect(File('assets/images/logo.png').readAsBytesSync(), const [1, 2, 3]);
      expect(File('ios/Runner/Info.plist').readAsStringSync(), 'OLD_IOS');
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        'OLD_ANDROID',
      );
      expect(File('macos/Runner/Info.plist').readAsStringSync(), 'OLD_MAC');
      expect(File('web/index.html').readAsStringSync(), 'OLD_WEB');
      expect(File('linux/CMakeLists.txt').readAsStringSync(), 'OLD_LINUX');
      expect(File('windows/CMakeLists.txt').readAsStringSync(), 'OLD_WINDOWS');
      expect(
        File('clonify/clones/client/config.json').readAsStringSync(),
        '{"version":"1.0.0+1"}',
      );
    });
  });
}

import 'dart:io';

import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/file_tree_checkpoint.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_checkpoint_test_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('FileTreeCheckpoint', () {
    test('restores edited files', () {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_IOS');
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_ANDROID');

      final checkpoint = FileTreeCheckpoint.capture(const ['ios', 'android']);
      File('ios/Runner/Info.plist').writeAsStringSync('NEW_IOS');
      File(
        'android/app/src/main/AndroidManifest.xml',
      ).writeAsStringSync('NEW_ANDROID');
      checkpoint.restore();

      expect(File('ios/Runner/Info.plist').readAsStringSync(), 'OLD_IOS');
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        'OLD_ANDROID',
      );
    });

    test('deletes files created after capture', () {
      Directory('ios').createSync();
      File('ios/old.txt').writeAsStringSync('old');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      File('ios/new.txt').writeAsStringSync('new');
      checkpoint.restore();

      expect(File('ios/old.txt').existsSync(), isTrue);
      expect(File('ios/new.txt').existsSync(), isFalse);
    });

    test('removes a tree that did not exist at capture', () {
      final checkpoint = FileTreeCheckpoint.capture(const ['macos']);
      File('macos/new.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('new');
      checkpoint.restore();
      expect(Directory('macos').existsSync(), isFalse);
    });

    test('keeps writes after discard', () {
      File('ios/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('old');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      File('ios/a.txt').writeAsStringSync('new');
      checkpoint.discard();
      expect(File('ios/a.txt').readAsStringSync(), 'new');
    });

    test('does not snapshot skipped Gradle cache dirs', () {
      File('android/.gradle/cache.bin')
        ..createSync(recursive: true)
        ..writeAsStringSync('CACHE');
      File('android/app/build.gradle.kts')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const ['android']);
      File('android/app/build.gradle.kts').writeAsStringSync('NEW');
      File('android/.gradle/cache.bin').writeAsStringSync('CACHE2');
      checkpoint.restore();
      expect(File('android/app/build.gradle.kts').readAsStringSync(), 'OLD');
      expect(File('android/.gradle/cache.bin').readAsStringSync(), 'CACHE2');
    });
  });

  group('runConfigureTransaction', () {
    test('restores iOS when a later Android step fails', () async {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_IOS');
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_ANDROID');

      await expectLater(
        runConfigureTransaction(() async {
          File('ios/Runner/Info.plist').writeAsStringSync('NEW_IOS');
          File(
            'android/app/src/main/AndroidManifest.xml',
          ).writeAsStringSync('NEW_ANDROID');
          throw CustomException('Android signing failed');
        }),
        throwsA(
          isA<ConfigureRolledBackException>().having(
            (error) => error.message,
            'message',
            contains('Android signing failed'),
          ),
        ),
      );

      expect(File('ios/Runner/Info.plist').readAsStringSync(), 'OLD_IOS');
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        'OLD_ANDROID',
      );
    });

    test('keeps writes when the transaction succeeds', () async {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_IOS');

      final value = await runConfigureTransaction(() async {
        File('ios/Runner/Info.plist').writeAsStringSync('NEW_IOS');
        return 7;
      });

      expect(value, 7);
      expect(File('ios/Runner/Info.plist').readAsStringSync(), 'NEW_IOS');
    });

    test(
      'restores version, clone config, Shorebird, Firebase, iOS, Android',
      () async {
        File('pubspec.yaml').writeAsStringSync('version: 1.0.0+1');
        File('shorebird.yaml').writeAsStringSync('app_id: old-shorebird');
        File('lib/firebase_options.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('OLD_FIREBASE');
        File('.firebaserc').writeAsStringSync('{"projects":{"default":"old"}}');
        File('clonify/clones/client/config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"version":"1.0.0+1"}');
        File('ios/Runner/Info.plist')
          ..createSync(recursive: true)
          ..writeAsStringSync('OLD_IOS');
        File('android/app/src/main/AndroidManifest.xml')
          ..createSync(recursive: true)
          ..writeAsStringSync('OLD_ANDROID');

        await expectLater(
          runConfigureTransaction(() async {
            File('pubspec.yaml').writeAsStringSync('version: 9.0.0+9');
            File('shorebird.yaml').writeAsStringSync('app_id: new-shorebird');
            File('lib/firebase_options.dart').writeAsStringSync('NEW_FIREBASE');
            File(
              '.firebaserc',
            ).writeAsStringSync('{"projects":{"default":"new"}}');
            File(
              'clonify/clones/client/config.json',
            ).writeAsStringSync('{"version":"9.0.0+9"}');
            File('ios/Runner/Info.plist').writeAsStringSync('NEW_IOS');
            File(
              'android/app/src/main/AndroidManifest.xml',
            ).writeAsStringSync('NEW_ANDROID');
            throw CustomException('configure failed after all writes');
          }),
          throwsA(isA<ConfigureRolledBackException>()),
        );

        expect(File('pubspec.yaml').readAsStringSync(), 'version: 1.0.0+1');
        expect(
          File('shorebird.yaml').readAsStringSync(),
          'app_id: old-shorebird',
        );
        expect(
          File('lib/firebase_options.dart').readAsStringSync(),
          'OLD_FIREBASE',
        );
        expect(
          File('.firebaserc').readAsStringSync(),
          '{"projects":{"default":"old"}}',
        );
        expect(
          File('clonify/clones/client/config.json').readAsStringSync(),
          '{"version":"1.0.0+1"}',
        );
        expect(File('ios/Runner/Info.plist').readAsStringSync(), 'OLD_IOS');
        expect(
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
          'OLD_ANDROID',
        );
      },
    );
  });
}

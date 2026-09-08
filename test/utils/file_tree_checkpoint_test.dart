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

    test('does not snapshot build, .cxx, or captures dirs', () {
      File('android/app/build/out.bin')
        ..createSync(recursive: true)
        ..writeAsStringSync('BUILD');
      File('android/.cxx/abi.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('CXX');
      File('android/captures/shot.png')
        ..createSync(recursive: true)
        ..writeAsStringSync('CAP');
      File('android/app/src/main/AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const ['android']);
      File('android/app/src/main/AndroidManifest.xml').writeAsStringSync('NEW');
      File('android/app/build/out.bin').writeAsStringSync('BUILD2');
      checkpoint.restore();
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        'OLD',
      );
      expect(File('android/app/build/out.bin').readAsStringSync(), 'BUILD2');
      expect(File('android/.cxx/abi.txt').readAsStringSync(), 'CXX');
      expect(File('android/captures/shot.png').readAsStringSync(), 'CAP');
    });

    test('keeps a .gradle dir created during the transaction', () {
      File('android/app/build.gradle.kts')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const ['android']);
      File('android/.gradle/new-cache.bin')
        ..createSync(recursive: true)
        ..writeAsStringSync('CACHE');
      File('android/app/build.gradle.kts').writeAsStringSync('NEW');
      checkpoint.restore();
      expect(File('android/app/build.gradle.kts').readAsStringSync(), 'OLD');
      expect(File('android/.gradle/new-cache.bin').readAsStringSync(), 'CACHE');
    });

    test('restores empty files and nested unicode names', () {
      File('ios/Runner/café.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('');
      File('ios/Runner/empty.bin').writeAsBytesSync(const []);
      File('ios/Runner/key.jks').writeAsBytesSync(const [0xFE, 0xED, 0xFE, 0xED]);
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      File('ios/Runner/café.txt').writeAsStringSync('changed');
      File('ios/Runner/key.jks').writeAsBytesSync(const [0x00]);
      checkpoint.restore();
      expect(File('ios/Runner/café.txt').readAsStringSync(), '');
      expect(File('ios/Runner/empty.bin').readAsBytesSync(), isEmpty);
      expect(
        File('ios/Runner/key.jks').readAsBytesSync(),
        const [0xFE, 0xED, 0xFE, 0xED],
      );
    });

    test('recreates a tree deleted after capture', () {
      File('ios/Runner/Info.plist')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      Directory('ios').deleteSync(recursive: true);
      checkpoint.restore();
      expect(File('ios/Runner/Info.plist').readAsStringSync(), 'OLD');
    });

    test('restores a file that was replaced by a directory', () {
      File('lib/firebase_options.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const [
        'lib/firebase_options.dart',
      ]);
      File('lib/firebase_options.dart').deleteSync();
      File('lib/firebase_options.dart/nested.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('oops');
      checkpoint.restore();
      expect(File('lib/firebase_options.dart').readAsStringSync(), 'OLD');
    });

    test('restores a directory that was replaced by a file', () {
      File('ios/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      Directory('ios').deleteSync(recursive: true);
      File('ios').writeAsStringSync('I am a file');
      checkpoint.restore();
      expect(File('ios/a.txt').readAsStringSync(), 'OLD');
    });

    test('clears an empty captured directory of new files', () {
      Directory('macos').createSync();
      final checkpoint = FileTreeCheckpoint.capture(const ['macos']);
      File('macos/new.txt').writeAsStringSync('new');
      checkpoint.restore();
      expect(File('macos/new.txt').existsSync(), isFalse);
      expect(Directory('macos').existsSync(), isTrue);
    });

    test('does not wipe live files if that root backup is gone', () {
      File('ios/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_IOS');
      File('android/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD_ANDROID');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios', 'android']);
      File('ios/a.txt').writeAsStringSync('NEW_IOS');
      File('android/a.txt').writeAsStringSync('NEW_ANDROID');
      Directory('${checkpoint.backupDir.path}/0').deleteSync(recursive: true);
      expect(() => checkpoint.restore(), throwsA(isA<StateError>()));
      expect(File('ios/a.txt').readAsStringSync(), 'NEW_IOS');
      expect(File('android/a.txt').readAsStringSync(), 'OLD_ANDROID');
    });

    test('discard is safe to call twice', () {
      File('ios/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('old');
      final checkpoint = FileTreeCheckpoint.capture(const ['ios']);
      checkpoint.discard();
      checkpoint.discard();
      expect(checkpoint.backupDir.existsSync(), isFalse);
    });

    test('captures an empty root list', () {
      final checkpoint = FileTreeCheckpoint.capture(const []);
      expect(checkpoint.entries, isEmpty);
      checkpoint.restore();
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

    test('leaves files unchanged when the body throws before writes', () async {
      File('pubspec.yaml').writeAsStringSync('version: 1.0.0+1');
      await expectLater(
        runConfigureTransaction(() async {
          throw const FormatException('bad yaml');
        }),
        throwsA(
          isA<ConfigureRolledBackException>().having(
            (error) => error.message,
            'message',
            contains('bad yaml'),
          ),
        ),
      );
      expect(File('pubspec.yaml').readAsStringSync(), 'version: 1.0.0+1');
    });

    test('deletes files that did not exist before configure', () async {
      await expectLater(
        runConfigureTransaction(() async {
          File('.firebaserc').writeAsStringSync('{"projects":{"default":"new"}}');
          File('shorebird.yaml').writeAsStringSync('app_id: new');
          File('clonify/clones/client/config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync('{"version":"9.0.0+9"}');
          throw CustomException('failed after creating files');
        }),
        throwsA(isA<ConfigureRolledBackException>()),
      );
      expect(File('.firebaserc').existsSync(), isFalse);
      expect(File('shorebird.yaml').existsSync(), isFalse);
      expect(Directory('clonify').existsSync(), isFalse);
    });

    test('reports both errors when restore cannot find the backup', () async {
      File('ios/a.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('OLD');
      final before = Directory.systemTemp
          .listSync()
          .whereType<Directory>()
          .map((dir) => dir.path)
          .toSet();

      await expectLater(
        runConfigureTransaction(() async {
          for (final dir in Directory.systemTemp.listSync().whereType<Directory>()) {
            final name = dir.path.split(Platform.pathSeparator).last;
            if (!name.startsWith('clonify_checkpoint_')) continue;
            if (before.contains(dir.path)) continue;
            dir.deleteSync(recursive: true);
          }
          File('ios/a.txt').writeAsStringSync('NEW');
          throw CustomException('signing failed');
        }),
        throwsA(
          isA<ConfigureRolledBackException>()
              .having(
                (error) => error.message,
                'message',
                contains('signing failed'),
              )
              .having(
                (error) => error.restoreError,
                'restoreError',
                isNotNull,
              ),
        ),
      );
      expect(File('ios/a.txt').readAsStringSync(), 'NEW');
    });
  });

  test('configureMutableRoots covers every local switch surface', () {
    expect(
      configureMutableRoots,
      containsAll([
        'android',
        'ios',
        'macos',
        'web',
        'linux',
        'windows',
        'assets/images',
        'lib/generated',
        'lib/firebase_options.dart',
        'shorebird.yaml',
        'pubspec.yaml',
        'package_rename_config.yaml',
        'flutter_launcher_icons.yaml',
        'flutter_native_splash.yaml',
        'firebase.json',
        '.firebaserc',
        'clonify',
      ]),
    );
  });
}

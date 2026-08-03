import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/shorebird_manager.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_shorebird_assert_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('configureShorebirdAppId edge cases', () {
    test('skips empty shorebirdAppId without writing', () async {
      File(defaultShorebirdYamlPath).writeAsStringSync('app_id: keep\n');
      await configureShorebirdAppId(shorebirdAppId: '   ');
      expect(
        File(defaultShorebirdYamlPath).readAsStringSync(),
        contains('app_id: keep'),
      );
    });

    test('no-ops when shorebird.yaml is missing', () async {
      expect(File(defaultShorebirdYamlPath).existsSync(), isFalse);
      await configureShorebirdAppId(shorebirdAppId: 'new-id');
      expect(File(defaultShorebirdYamlPath).existsSync(), isFalse);
    });
  });

  group('assertShorebirdAppIdMatches', () {
    test('passes when ids match', () {
      File(defaultShorebirdYamlPath).writeAsStringSync('app_id: expected-id\n');
      expect(() => assertShorebirdAppIdMatches('expected-id'), returnsNormally);
    });

    test('throws CustomException when ids differ', () {
      File(defaultShorebirdYamlPath).writeAsStringSync('app_id: other-id\n');
      expect(
        () => assertShorebirdAppIdMatches('expected-id'),
        throwsA(
          isA<CustomException>().having(
            (e) => e.message,
            'message',
            contains('expected-id'),
          ),
        ),
      );
    });

    test('throws when shorebird.yaml is missing', () {
      expect(
        () => assertShorebirdAppIdMatches('expected-id'),
        throwsA(isA<CustomException>()),
      );
    });
  });

  group('assertBundleIdMatches', () {
    test('skips checks when platform is not in args', () {
      expect(
        () => assertBundleIdMatches(
          shorebirdArgs: ['release'],
          expectedPackageName: 'com.example.app',
        ),
        returnsNormally,
      );
    });

    test('throws when Android applicationId mismatches', () {
      File(Constants.androidAppLevelBuildGradleFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync("applicationId 'com.wrong.app'");

      expect(
        () => assertBundleIdMatches(
          shorebirdArgs: ['release', 'android'],
          expectedPackageName: 'com.example.app',
        ),
        throwsA(
          isA<CustomException>().having(
            (e) => e.message,
            'message',
            contains('Android applicationId'),
          ),
        ),
      );
    });

    test('passes when Android applicationId matches', () {
      File(Constants.androidAppLevelKotlinBuildGradleFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('applicationId = "com.example.app"');

      expect(
        () => assertBundleIdMatches(
          shorebirdArgs: ['release', 'android'],
          expectedPackageName: 'com.example.app',
        ),
        returnsNormally,
      );
    });

    test('throws when iOS bundle id mismatches', () {
      File(Constants.iosProjectFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('PRODUCT_BUNDLE_IDENTIFIER = com.wrong.app;');

      expect(
        () => assertBundleIdMatches(
          shorebirdArgs: ['patch', 'ios'],
          expectedPackageName: 'com.example.app',
        ),
        throwsA(
          isA<CustomException>().having(
            (e) => e.message,
            'message',
            contains('iOS bundle id'),
          ),
        ),
      );
    });
  });

  group('resolveShorebirdAppId', () {
    test('returns empty for non-string values', () {
      expect(resolveShorebirdAppId({'shorebirdAppId': 123}), '');
      expect(resolveShorebirdAppId({'shorebirdAppId': null}), '');
    });
  });
}

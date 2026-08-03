import 'package:clonify/utils/clonify_helpers.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('sanitizeArg', () {
    test('allows common flutter/firebase style args', () {
      const safe = [
        'flutter',
        'build',
        'appbundle',
        '--release',
        'com.company.app',
        '--platforms=android,ios',
        'projects:create',
        './build/out.aab',
        'path/to/file.yaml',
      ];
      for (final arg in safe) {
        expect(sanitizeArg(arg), arg, reason: arg);
      }
    });

    test('allows known dart-run package entrypoints', () {
      expect(sanitizeArg('flutter_native_splash:create'), isNotEmpty);
      expect(sanitizeArg('flutter_launcher_icons:generate'), isNotEmpty);
      expect(sanitizeArg('intl_utils:generate'), isNotEmpty);
    });

    test('rejects shell metacharacters that enable injection', () {
      const unsafe = [
        'rm -rf /',
        'foo;bar',
        'foo&&bar',
        'foo|bar',
        '\$HOME',
        '`id`',
        'a > b',
        "o'hara",
        'say "hi"',
        'a(b)',
      ];
      for (final arg in unsafe) {
        expect(
          () => sanitizeArg(arg),
          throwsA(isA<ArgumentError>()),
          reason: arg,
        );
      }
    });
  });

  group('versionNumberIncrementor', () {
    test('increments patch and build together', () {
      expect(versionNumberIncrementor('1.0.0+1'), '1.0.2+2');
      expect(versionNumberIncrementor('2.3.4+10'), '2.3.11+11');
    });

    test('throws on malformed version strings', () {
      expect(() => versionNumberIncrementor('1.0.0'), throwsFormatException);
      expect(
        () => versionNumberIncrementor('not-a-version'),
        throwsA(anything),
      );
    });
  });

  group('toTitleCase', () {
    test('capitalizes first character', () {
      expect(toTitleCase('hello'), 'Hello');
      expect(toTitleCase('A'), 'A');
    });
  });
}

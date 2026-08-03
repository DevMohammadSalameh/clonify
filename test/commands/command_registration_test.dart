import 'dart:io';

import 'package:clonify/commands/clonify_command_runner.dart';
import 'package:clonify/constants.dart';
import 'package:clonify/enums.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('ClonifyCommandRunner registration', () {
    late ClonifyCommandRunner runner;

    setUp(() {
      runner = ClonifyCommandRunner();
    });

    test('registers every ClonifyCommands value', () {
      final registered = runner.commands.keys.toSet();
      for (final command in ClonifyCommands.values) {
        expect(
          registered,
          contains(command.name),
          reason: 'Missing command ${command.name}',
        );
        expect(runner.commands[command.name], isNotNull);
      }
    });

    test('each command exposes non-empty description', () {
      for (final entry in runner.commands.entries) {
        expect(entry.value.description, isNotEmpty, reason: entry.key);
      }
    });

    test('aliases resolve to the same command', () {
      expect(runner.commands['c'], same(runner.commands['configure']));
      expect(runner.commands['b'], same(runner.commands['build']));
      expect(runner.commands['sb'], same(runner.commands['shorebird']));
      expect(runner.commands['ls'], same(runner.commands['list']));
    });

    test('build command accepts expected flags without parse errors', () {
      final build = runner.commands['build']!;
      final results = build.argParser.parse([
        '--clientId',
        'demo',
        '--buildApk',
        '--no-buildAab',
        '--no-buildIpa',
        '--skipBuildCheck',
        '--skipAll',
      ]);
      expect(results['clientId'], 'demo');
      expect(results['buildApk'], isTrue);
      expect(results['buildAab'], isFalse);
      expect(results['buildIpa'], isFalse);
      expect(results['skipBuildCheck'], isTrue);
      expect(results['skipAll'], isTrue);
    });

    test('configure command accepts skip flags', () {
      final configure = runner.commands['configure']!;
      final results = configure.argParser.parse([
        '--clientId',
        'demo',
        '--skipFirebaseConfigure',
        '--skipShorebirdConfigure',
      ]);
      expect(results['skipFirebaseConfigure'], isTrue);
      expect(results['skipShorebirdConfigure'], isTrue);
    });

    test('shorebird command defaults skipFirebaseConfigure to true', () {
      final shorebird = runner.commands['shorebird']!;
      final results = shorebird.argParser.parse([]);
      expect(results['skipFirebaseConfigure'], isTrue);
    });
  });

  group('package version consistency', () {
    test('Constants.packageVersion matches pubspec.yaml', () {
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      expect(pubspec['name'], 'clonify');
      expect(
        Constants.packageVersion,
        equals(pubspec['version']?.toString()),
        reason:
            'Keep Constants.packageVersion in sync with pubspec.yaml '
            '(or rely only on dynamic --version).',
      );
    });

    test('getVersionFromPubspec reads live pubspec version', () async {
      final runner = ClonifyCommandRunner();
      final version = await runner.getVersionFromPubspec();
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      expect(version, equals(pubspec['version']?.toString()));
    });
  });
}

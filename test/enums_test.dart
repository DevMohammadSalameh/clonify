import 'package:args/args.dart';
import 'package:clonify/enums.dart';
import 'package:test/test.dart';

import 'silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('ClonifyCommands', () {
    test('names are unique and match enum identifiers', () {
      final names = ClonifyCommands.values.map((c) => c.name).toList();
      expect(names.toSet(), hasLength(names.length));
      for (final command in ClonifyCommands.values) {
        expect(command.name, isNotEmpty);
        expect(command.description, isNotEmpty);
      }
    });

    test('aliases do not collide across commands', () {
      final seen = <String>{};
      for (final command in ClonifyCommands.values) {
        expect(seen.contains(command.name), isFalse);
        seen.add(command.name);
        for (final alias in command.aliases) {
          expect(
            seen.contains(alias),
            isFalse,
            reason: 'Duplicate alias "$alias" on ${command.name}',
          );
          seen.add(alias);
        }
      }
    });
  });

  group('ClonifyCommandFlags', () {
    test('build defaults match product expectations', () {
      expect(ClonifyCommandFlags.buildAab.defaultsTo, isTrue);
      expect(ClonifyCommandFlags.buildApk.defaultsTo, isFalse);
      expect(ClonifyCommandFlags.buildIpa.defaultsTo, isTrue);
      expect(ClonifyCommandFlags.skipAll.defaultsTo, isFalse);
      expect(ClonifyCommandFlags.skipBuildCheck.defaultsTo, isFalse);
    });

    test('every flag has non-empty help text', () {
      for (final flag in ClonifyCommandFlags.values) {
        expect(flag.help, isNotEmpty, reason: flag.name);
        expect(flag.description, isNotEmpty, reason: flag.name);
      }
    });
  });

  group('ClonifyArgParser / ClonifyArgResults', () {
    ArgParser buildParser() {
      final parser = ArgParser()
        ..addClientIdOption(mandatory: false)
        ..addClonifyFlags(const [
          ClonifyCommandFlags.skipAll,
          ClonifyCommandFlags.buildAab,
          ClonifyCommandFlags.buildApk,
          ClonifyCommandFlags.buildIpa,
        ]);
      return parser;
    }

    test('registers flags with enum defaults', () {
      final results = buildParser().parse([]);
      expect(results.clientId, isNull);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildAab), isTrue);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildApk), isFalse);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildIpa), isTrue);
      expect(results.clonifyFlag(ClonifyCommandFlags.skipAll), isFalse);
    });

    test('parses clientId aliases', () {
      expect(buildParser().parse(['--client-id', 'acme']).clientId, 'acme');
      expect(buildParser().parse(['--id', 'beta']).clientId, 'beta');
      expect(buildParser().parse(['--clientId', 'gamma']).clientId, 'gamma');
    });

    test('negated flags override defaults', () {
      final results = buildParser().parse([
        '--no-buildAab',
        '--buildApk',
        '--no-buildIpa',
        '--skipAll',
      ]);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildAab), isFalse);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildApk), isTrue);
      expect(results.clonifyFlag(ClonifyCommandFlags.buildIpa), isFalse);
      expect(results.clonifyFlag(ClonifyCommandFlags.skipAll), isTrue);
    });

    test('addClonifyFlag can override defaultsTo', () {
      final parser = ArgParser()
        ..addClonifyFlag(
          ClonifyCommandFlags.skipFirebaseConfigure,
          defaultsTo: true,
        );
      expect(
        parser.parse([]).clonifyFlag(ClonifyCommandFlags.skipFirebaseConfigure),
        isTrue,
      );
    });
  });
}

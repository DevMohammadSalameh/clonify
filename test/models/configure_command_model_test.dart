import 'package:args/args.dart';
import 'package:clonify/enums.dart';
import 'package:clonify/models/commands_calls_models/configure_command_model.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  ArgParser configureParser() {
    final parser = ArgParser()
      ..addClientIdOption(mandatory: false)
      ..addClonifyFlags(const [
        ClonifyCommandFlags.skipAll,
        ClonifyCommandFlags.autoUpdate,
        ClonifyCommandFlags.isDebug,
        ClonifyCommandFlags.skipFirebaseConfigure,
        ClonifyCommandFlags.skipShorebirdConfigure,
        ClonifyCommandFlags.skipPubUpdate,
        ClonifyCommandFlags.skipVersionUpdate,
      ]);
    return parser;
  }

  group('ConfigureCommandModel', () {
    test('uses flag defaults when args are empty', () {
      final model = ConfigureCommandModel.fromArgs(configureParser().parse([]));
      expect(model.clientId, isNull);
      expect(model.skipAll, isFalse);
      expect(model.autoUpdate, isFalse);
      expect(model.isDebug, isFalse);
      expect(model.skipFirebaseConfigure, isFalse);
      expect(model.skipShorebirdConfigure, isFalse);
      expect(model.skipPubUpdate, isFalse);
      expect(model.skipVersionUpdate, isFalse);
    });

    test('parses all configure flags', () {
      final model = ConfigureCommandModel.fromArgs(
        configureParser().parse([
          '--clientId',
          'client_x',
          '--skipAll',
          '--autoUpdate',
          '--isDebug',
          '--skipFirebaseConfigure',
          '--skipShorebirdConfigure',
          '--skipPubUpdate',
          '--skipVersionUpdate',
        ]),
      );

      expect(model.clientId, 'client_x');
      expect(model.skipAll, isTrue);
      expect(model.autoUpdate, isTrue);
      expect(model.isDebug, isTrue);
      expect(model.skipFirebaseConfigure, isTrue);
      expect(model.skipShorebirdConfigure, isTrue);
      expect(model.skipPubUpdate, isTrue);
      expect(model.skipVersionUpdate, isTrue);
    });

    test('empty constructor keeps defaults', () {
      final model = ConfigureCommandModel();
      expect(model.skipAll, ClonifyCommandFlags.skipAll.defaultsTo);
      expect(
        model.skipShorebirdConfigure,
        ClonifyCommandFlags.skipShorebirdConfigure.defaultsTo,
      );
    });

    test('fromArgs with null is safe', () {
      final model = ConfigureCommandModel.fromArgs(null);
      expect(model.clientId, isNull);
      expect(model.skipAll, isFalse);
    });
  });
}

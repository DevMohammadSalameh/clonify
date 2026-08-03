import 'package:args/args.dart';
import 'package:clonify/enums.dart';

class ConfigureCommandModel {
  String? clientId;
  bool skipAll = ClonifyCommandFlags.skipAll.defaultsTo;
  bool autoUpdate = ClonifyCommandFlags.autoUpdate.defaultsTo;
  bool isDebug = ClonifyCommandFlags.isDebug.defaultsTo;
  bool skipFirebaseConfigure =
      ClonifyCommandFlags.skipFirebaseConfigure.defaultsTo;
  bool skipShorebirdConfigure =
      ClonifyCommandFlags.skipShorebirdConfigure.defaultsTo;
  bool skipPubUpdate = ClonifyCommandFlags.skipPubUpdate.defaultsTo;
  bool skipVersionUpdate = ClonifyCommandFlags.skipVersionUpdate.defaultsTo;

  ConfigureCommandModel();

  ConfigureCommandModel.fromArgs(ArgResults? argResults) {
    if (argResults == null) return;
    clientId = argResults.clientId;
    skipAll = argResults.clonifyFlag(ClonifyCommandFlags.skipAll);
    autoUpdate = argResults.clonifyFlag(ClonifyCommandFlags.autoUpdate);
    isDebug = argResults.clonifyFlag(ClonifyCommandFlags.isDebug);
    skipFirebaseConfigure = argResults.clonifyFlag(
      ClonifyCommandFlags.skipFirebaseConfigure,
    );
    skipShorebirdConfigure = argResults.clonifyFlag(
      ClonifyCommandFlags.skipShorebirdConfigure,
    );
    skipPubUpdate = argResults.clonifyFlag(ClonifyCommandFlags.skipPubUpdate);
    skipVersionUpdate = argResults.clonifyFlag(
      ClonifyCommandFlags.skipVersionUpdate,
    );
  }
}

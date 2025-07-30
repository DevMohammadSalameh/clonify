import 'package:args/args.dart';
import 'package:clonify/enums.dart';

class ConfigureCommandModel {
  String? clientId;
  bool skipAll = false;
  bool autoUpdate = false;
  bool isDebug = false;
  bool skipFirebaseConfigure = false;
  bool skipPubUpdate = false;
  bool skipVersionUpdate = false;

  ConfigureCommandModel.fromArgs(ArgResults? argResults) {
    clientId = argResults?[ClonifyCommandOptions.clientId.name] as String?;
    skipAll = argResults?[ClonifyCommandFlags.skipAll.name] as bool? ?? false;
    autoUpdate =
        argResults?[ClonifyCommandFlags.autoUpdate.name] as bool? ?? false;
    isDebug = argResults?[ClonifyCommandFlags.isDebug.name] as bool? ?? false;
    skipFirebaseConfigure =
        argResults?[ClonifyCommandFlags.skipFirebaseConfigure.name] as bool? ??
        false;
    skipPubUpdate =
        argResults?[ClonifyCommandFlags.skipPubUpdate.name] as bool? ?? false;
    skipVersionUpdate =
        argResults?[ClonifyCommandFlags.skipVersionUpdate.name] as bool? ??
        false;
  }
}

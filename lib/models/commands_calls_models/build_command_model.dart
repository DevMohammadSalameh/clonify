import 'package:args/args.dart';
import 'package:clonify/enums.dart';

class BuildCommandModel {
  String? clientId;
  bool skipAll = false;
  bool buildAab = true;
  bool buildApk = false;
  bool buildIpa = true;
  bool skipBuildCheck = false;

  BuildCommandModel.fromArgs(ArgResults? argResults) {
    clientId = argResults?[ClonifyCommandOptions.clientId.name] as String?;
    skipAll = argResults?[ClonifyCommandFlags.skipAll.name] as bool? ?? false;
    buildAab = argResults?[ClonifyCommandFlags.buildAab.name] as bool? ?? true;
    buildApk = argResults?[ClonifyCommandFlags.buildApk.name] as bool? ?? false;
    buildIpa = argResults?[ClonifyCommandFlags.buildIpa.name] as bool? ?? false;
    skipBuildCheck =
        argResults?[ClonifyCommandFlags.skipBuildCheck.name] as bool? ?? false;
  }
}

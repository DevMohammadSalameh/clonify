import 'package:args/args.dart';
import 'package:clonify/enums.dart';

class BuildCommandModel {
  String? clientId;
  bool skipAll = ClonifyCommandFlags.skipAll.defaultsTo;
  bool buildAab = ClonifyCommandFlags.buildAab.defaultsTo;
  bool buildApk = ClonifyCommandFlags.buildApk.defaultsTo;
  bool buildIpa = ClonifyCommandFlags.buildIpa.defaultsTo;
  bool skipBuildCheck = ClonifyCommandFlags.skipBuildCheck.defaultsTo;

  BuildCommandModel.fromArgs(ArgResults? argResults) {
    if (argResults == null) return;
    clientId = argResults.clientId;
    skipAll = argResults.clonifyFlag(ClonifyCommandFlags.skipAll);
    buildAab = argResults.clonifyFlag(ClonifyCommandFlags.buildAab);
    buildApk = argResults.clonifyFlag(ClonifyCommandFlags.buildApk);
    buildIpa = argResults.clonifyFlag(ClonifyCommandFlags.buildIpa);
    skipBuildCheck = argResults.clonifyFlag(ClonifyCommandFlags.skipBuildCheck);
  }
}

import 'package:logger/logger.dart';

/// Keeps `dart test` output clean by hiding expected CLI error/info logs.
void silenceClonifyLogsForTests() {
  Logger.level = Level.off;
}
